// providers/expense_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/finance_calculations.dart';

class ExpenseProvider extends ChangeNotifier {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  final FirebaseService _service = FirebaseService();
  StreamSubscription<List<ExpenseModel>>? _expenseSubscription;

  // ==========================================
  // STATE VARIABLES
  // ==========================================
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _streamErrorMessage;

  // Filters
  String _selectedCategory = 'All';
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime.now();

  // ==========================================
  // GETTERS
  // ==========================================
  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get filteredExpenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get streamErrorMessage => _streamErrorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  DateTime get selectedMonth => _selectedMonth;

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  ExpenseProvider() {
    // Provider එක හදනකොටම, expenses stream එක start කරන්න
    _initExpenseStream();
  }

  // ==========================================
  // INIT: Start real-time expense listener
  // ==========================================
  void _initExpenseStream() {
    _isLoading = true;
    _streamErrorMessage = null;
    notifyListeners();

    // පරණ subscription එක cancel කරන්න
    _expenseSubscription?.cancel();

    _expenseSubscription = _service.getExpensesStream().listen(
      (expenses) {
        _expenses = expenses;
        _streamErrorMessage = null;
        _applyFilters();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _streamErrorMessage = FirebaseService.friendlyError(error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==========================================
  // DISPOSE: Cancel subscription
  // ==========================================
  @override
  void dispose() {
    _expenseSubscription?.cancel();
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
  // APPLY FILTERS (Category + Search)
  // ==========================================
  void _applyFilters() {
    _filteredExpenses = filterExpenses(
      expenses: _expenses,
      month: _selectedMonth,
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );
  }

  // ==========================================
  // ADD EXPENSE
  // ==========================================
  Future<bool> addExpense(ExpenseModel expense) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addExpense(expense);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // UPDATE EXPENSE
  // ==========================================
  Future<bool> updateExpense(ExpenseModel expense) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateExpense(expense);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // DELETE EXPENSE
  // ==========================================
  Future<bool> deleteExpense(String expenseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteExpense(expenseId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // SET CATEGORY FILTER
  // ==========================================
  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // ==========================================
  // SET SEARCH QUERY
  // ==========================================
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // ==========================================
  // SET MONTH FILTER
  // ==========================================
  void setMonthFilter(DateTime month) {
    _selectedMonth = month;
    _applyFilters();
    notifyListeners();
  }

  // ==========================================
  // CLEAR ALL FILTERS
  // ==========================================
  void clearFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _selectedMonth = DateTime.now();
    _applyFilters();
    notifyListeners();
  }

  // ==========================================
  // GET EXPENSES BY CURRENT MONTH
  // ==========================================
  List<ExpenseModel> get currentMonthExpenses {
    return expensesForMonth(_expenses, DateTime.now());
  }

  List<ExpenseModel> getExpensesForLastMonths({
    required int months,
    DateTime? relativeTo,
  }) {
    return expensesForLastMonths(
      _expenses,
      months: months,
      relativeTo: relativeTo,
    );
  }

  // ==========================================
  // GET EXPENSES BY CATEGORY
  // ==========================================
  List<ExpenseModel> getExpensesByCategory(String category) {
    return _expenses.where((expense) {
      return expense.category.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  // ==========================================
  // GET RECENT EXPENSES (Last N items)
  // ==========================================
  List<ExpenseModel> getRecentExpenses({int limit = 5}) {
    List<ExpenseModel> sorted = List.from(_expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  // ==========================================
  // GET TOTAL SPENT (Current Month)
  // ==========================================
  double get totalSpentThisMonth {
    return totalExpenseAmount(currentMonthExpenses);
  }

  // ==========================================
  // GET TOTAL SPENT (All time)
  // ==========================================
  double get totalSpentAllTime {
    return totalExpenseAmount(_expenses);
  }

  // ==========================================
  // GET SPENDING BY CATEGORY (Current Month)
  // ==========================================
  Map<String, double> get spendingByCategory {
    return calculateSpendingByCategory(
      currentMonthExpenses,
      categories: AppConstants.expenseCategories,
    );
  }

  // ==========================================
  // GET SPENDING PERCENTAGES (Pie chart සඳහා)
  // ==========================================
  Map<String, double> get spendingPercentages {
    Map<String, double> categorySpending = spendingByCategory;
    double total = totalSpentThisMonth;

    if (total <= 0) {
      return {};
    }

    Map<String, double> percentages = {};
    categorySpending.forEach((category, amount) {
      if (amount > 0) {
        percentages[category] = (amount / total) * 100;
      }
    });
    return percentages;
  }

  // ==========================================
  // GET TODAY'S SPENDING
  // ==========================================
  double get todaySpending {
    DateTime now = DateTime.now();
    return _expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day;
    }).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // ==========================================
  // GET THIS WEEK'S SPENDING
  // ==========================================
  double get thisWeekSpending {
    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

    final expenses = _expenses.where((expense) {
      return expense.date.isAfter(
        DateTime(weekStart.year, weekStart.month, weekStart.day),
      );
    });
    return totalExpenseAmount(expenses);
  }

  // ==========================================
  // GET MONTHLY TREND (Last 6 months - Insights screen සඳහා)
  // ==========================================
  Map<String, double> getMonthlyTrend({int months = 6}) {
    return monthlyExpenseTotals(_expenses, months: months);
  }

  // ==========================================
  // GET TOP SPENDING CATEGORY
  // ==========================================
  String? get topSpendingCategory {
    Map<String, double> spending = spendingByCategory;
    if (spending.isEmpty) return null;

    String? topCategory;
    double maxAmount = 0.0;

    spending.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCategory = category;
      }
    });

    return topCategory;
  }

  // ==========================================
  // GET EXPENSE COUNT (Current Month)
  // ==========================================
  int get expenseCountThisMonth {
    return currentMonthExpenses.length;
  }

  // ==========================================
  // REFRESH (Manual reload)
  // ==========================================
  void refresh() {
    _initExpenseStream();
  }
}
