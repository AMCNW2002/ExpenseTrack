// providers/budget_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/finance_calculations.dart';

class BudgetProvider extends ChangeNotifier {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  final FirebaseService _service = FirebaseService();
  StreamSubscription<BudgetModel?>? _budgetSubscription;

  // ==========================================
  // STATE VARIABLES
  // ==========================================
  BudgetModel? _budget;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime.now();
  int _budgetStreamGeneration = 0;
  int _spendingLoadGeneration = 0;

  // Expense data (spent amounts calculate කරන්න)
  Map<String, double> _spentByCategory = {};
  double _totalSpent = 0.0;

  // ==========================================
  // GETTERS
  // ==========================================
  BudgetModel? get budget => _budget;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;

  double get totalBudget => _budget?.totalBudget ?? 0.0;
  double get totalSpent => _totalSpent;
  double get availableToSpend =>
      calculateAvailableToSpend(totalBudget, _totalSpent);

  /// Budget එකෙන් කීයක් use කරලා තියෙනවද (percentage 0-100)
  double get spentPercentage =>
      calculateBudgetPercentage(totalBudget, _totalSpent);

  /// Budget එකෙන් කීයක් ඉතුරුද (percentage 0-100)
  double get remainingPercentage {
    return 100.0 - spentPercentage;
  }

  /// Budget එක ඉක්මවලා ගිහින්ද?
  bool get isOverBudget => isBudgetOverLimit(totalBudget, _totalSpent);

  /// Budget එකේ 80%+ use කරලා තියෙනවද? (Warning)
  bool get isNearLimit {
    return isNearBudgetLimit(
      totalBudget,
      _totalSpent,
      AppConstants.budgetWarningThreshold,
    );
  }

  /// Category එකකට අදාළ budget එක
  double getCategoryBudget(String category) {
    return _budget?.getCategoryBudget(category) ?? 0.0;
  }

  /// Category එකකට අදාළ spent amount
  double getCategorySpent(String category) {
    return _spentByCategory[category] ?? 0.0;
  }

  /// Category එකකට අදාළ percentage
  double getCategoryPercentage(String category) {
    return calculateCategoryBudgetPercentage(
      getCategoryBudget(category),
      getCategorySpent(category),
    );
  }

  /// Category එකක් over budget ද?
  bool isCategoryOverBudget(String category) {
    return isCategoryBudgetOverLimit(
      getCategoryBudget(category),
      getCategorySpent(category),
    );
  }

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  BudgetProvider() {
    _initBudgetStream();
  }

  // ==========================================
  // INIT: Listen to budget stream
  // ==========================================
  void _initBudgetStream() {
    final generation = ++_budgetStreamGeneration;
    final month = DateTime(_selectedMonth.year, _selectedMonth.month);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _budgetSubscription?.cancel();

    _budgetSubscription = _service
        .getBudgetStream(
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    )
        .listen(
      (budget) {
        if (generation != _budgetStreamGeneration) return;
        _budget = budget;
        notifyListeners();
        _loadSpendingData(month: month);
      },
      onError: (error) {
        if (generation != _budgetStreamGeneration) return;
        _spendingLoadGeneration++;
        _errorMessage = FirebaseService.friendlyError(error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==========================================
  // LOAD SPENDING DATA (Category-wise)
  // ==========================================
  Future<void> _loadSpendingData({DateTime? month}) async {
    final requestedMonth = month ?? _selectedMonth;
    final generation = ++_spendingLoadGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, double> spending = await _service.getSpendingByCategory(
        month: requestedMonth.month,
        year: requestedMonth.year,
      );

      if (generation != _spendingLoadGeneration ||
          requestedMonth.year != _selectedMonth.year ||
          requestedMonth.month != _selectedMonth.month) {
        return;
      }

      _spentByCategory = spending;
      _totalSpent = spending.values.fold(0.0, (sum, amount) => sum + amount);
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      if (generation != _spendingLoadGeneration) return;
      _errorMessage = FirebaseService.friendlyError(error);
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // DISPOSE
  // ==========================================
  @override
  void dispose() {
    _budgetStreamGeneration++;
    _spendingLoadGeneration++;
    _budgetSubscription?.cancel();
    super.dispose();
  }

  // ==========================================
  // CLEAR ERROR
  // ==========================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==========================================
  // SET MONTH (Month change කරාම)
  // ==========================================
  void setMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    _spendingLoadGeneration++;
    _budget = null;
    _spentByCategory = {};
    _totalSpent = 0.0;
    _initBudgetStream();
  }

  // ==========================================
  // SAVE BUDGET (Create or Update)
  // ==========================================
  Future<bool> saveBudget(BudgetModel budget) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.saveBudget(budget);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveBudgetAllocation({
    required double totalBudget,
    required Map<String, double> categoryBudgets,
  }) {
    final existing = _budget;
    final budget = BudgetModel(
      id: existing?.id,
      userId: existing?.userId ?? '',
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      month: _selectedMonth.month,
      year: _selectedMonth.year,
      createdAt: existing?.createdAt,
      updatedAt: DateTime.now(),
    );
    return saveBudget(budget);
  }

  // ==========================================
  // SET TOTAL BUDGET
  // ==========================================
  Future<bool> setTotalBudget(double amount) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateTotalBudget(
        amount,
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // SET CATEGORY BUDGET
  // ==========================================
  Future<bool> setCategoryBudget(String category, double amount) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateCategoryBudget(
        category,
        amount,
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // CREATE DEFAULT BUDGET (අලුත් user සඳහා)
  // ==========================================
  Future<bool> createDefaultBudget() async {
    BudgetModel newBudget = BudgetModel(
      userId: '',
      totalBudget: AppConstants.defaultMonthlyBudget,
      month: _selectedMonth.month,
      year: _selectedMonth.year,
      categoryBudgets: {
        AppConstants.categoryFood: 10000.0,
        AppConstants.categoryTransport: 8000.0,
        AppConstants.categoryShopping: 10000.0,
        AppConstants.categoryBills: 8000.0,
        AppConstants.categoryHealth: 5000.0,
        AppConstants.categoryEducation: 5000.0,
        AppConstants.categoryEntertainment: 2000.0,
        AppConstants.categoryOther: 2000.0,
      },
    );

    return await saveBudget(newBudget);
  }

  // ==========================================
  // GET CATEGORY BUDGET LIST (UI සඳහා)
  // ==========================================
  List<Map<String, dynamic>> get categoryBudgetList {
    return AppConstants.expenseCategories.map((category) {
      return {
        'category': category,
        'icon': AppConstants.categoryIcons[category],
        'budget': getCategoryBudget(category),
        'spent': getCategorySpent(category),
        'percentage': getCategoryPercentage(category),
        'isOverBudget': isCategoryOverBudget(category),
      };
    }).toList();
  }

  // ==========================================
  // GET SMART TIP (Budget එකට අදාළව)
  // ==========================================
  String get smartTip {
    if (totalBudget <= 0) {
      return 'Set a monthly budget to track your spending';
    }

    if (isOverBudget) {
      return 'You have exceeded your budget by Rs. ${(totalSpent - totalBudget).toStringAsFixed(0)}. Reduce spending!';
    }

    if (spentPercentage >= 90) {
      return 'You have used ${spentPercentage.toStringAsFixed(0)}% of your budget. Be careful!';
    }

    if (spentPercentage >= 80) {
      return 'You have used ${spentPercentage.toStringAsFixed(0)}% of your budget.';
    }

    // Top spending category එකෙන් tip එකක් දෙන්න
    String? topCategory = _topSpendingCategory;
    if (topCategory != null) {
      double topAmount = getCategorySpent(topCategory);
      double topPercent = totalSpent > 0 ? (topAmount / totalSpent) * 100 : 0;
      if (topPercent > 40) {
        return 'You could save more by reducing $topCategory expenses.';
      }
    }

    return 'You are on track! Keep it up 🎉';
  }

  // ==========================================
  // TOP SPENDING CATEGORY (Internal)
  // ==========================================
  String? get _topSpendingCategory {
    if (_spentByCategory.isEmpty) return null;

    String? top;
    double max = 0.0;
    _spentByCategory.forEach((category, amount) {
      if (amount > max) {
        max = amount;
        top = category;
      }
    });
    return top;
  }

  // ==========================================
  // REFRESH
  // ==========================================
  void refresh() {
    _initBudgetStream();
  }

  // ==========================================
  // RECALCULATE (Expense add/delete වුනාම call කරන්න)
  // ==========================================
  Future<void> recalculate() async {
    await _loadSpendingData();
  }
}
