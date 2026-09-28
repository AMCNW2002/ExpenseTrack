// models/budget_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class BudgetModel {
  // ==========================================
  // PROPERTIES
  // ==========================================
  final String? id; // Firestore document ID
  final String userId; // කාගේ budget එකද?
  final double totalBudget; // Rs. 50,000
  final Map<String, double>
      categoryBudgets; // {'Food': 10000, 'Transport': 3500, ...}
  final int month; // 9 (September)
  final int year; // 2026
  final DateTime createdAt; // Record එක හදපු වෙලාව
  final DateTime updatedAt; // අන්තිමට update කරපු වෙලාව

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  BudgetModel({
    this.id,
    required this.userId,
    required this.totalBudget,
    Map<String, double>? categoryBudgets,
    required this.month,
    required this.year,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : categoryBudgets = categoryBudgets ?? _defaultCategoryBudgets(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ==========================================
  // DEFAULT CATEGORY BUDGETS
  // ==========================================
  static Map<String, double> _defaultCategoryBudgets() {
    return {
      AppConstants.categoryFood: 0.0,
      AppConstants.categoryTransport: 0.0,
      AppConstants.categoryShopping: 0.0,
      AppConstants.categoryBills: 0.0,
      AppConstants.categoryHealth: 0.0,
      AppConstants.categoryEducation: 0.0,
      AppConstants.categoryEntertainment: 0.0,
      AppConstants.categoryOther: 0.0,
    };
  }

  // ==========================================
  // FROM MAP (Firestore එකෙන් ගන්නකොට)
  // ==========================================
  factory BudgetModel.fromMap(Map<String, dynamic> map, String documentId) {
    // categoryBudgets එක Map<String, dynamic> එකක් විදියට එනවා,
    // ඒක Map<String, double> එකකට convert කරන්න ඕන
    Map<String, double> parsedCategoryBudgets = {};
    if (map['categoryBudgets'] != null) {
      (map['categoryBudgets'] as Map<String, dynamic>).forEach((key, value) {
        parsedCategoryBudgets[key] = (value as num).toDouble();
      });
    } else {
      parsedCategoryBudgets = _defaultCategoryBudgets();
    }

    return BudgetModel(
      id: documentId,
      userId: map[AppConstants.fieldUserId] ?? '',
      totalBudget: (map['totalBudget'] ?? 0).toDouble(),
      categoryBudgets: parsedCategoryBudgets,
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      createdAt: (map[AppConstants.fieldCreatedAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ==========================================
  // TO MAP (Firestore එකට යවන්නකොට)
  // ==========================================
  Map<String, dynamic> toMap() {
    return {
      AppConstants.fieldUserId: userId,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets,
      'month': month,
      'year': year,
      AppConstants.fieldCreatedAt: Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ==========================================
  // COPY WITH (Budget එකේ කොටසක් වෙනස් කරන්න)
  // ==========================================
  BudgetModel copyWith({
    String? id,
    String? userId,
    double? totalBudget,
    Map<String, double>? categoryBudgets,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Category එකකට අදාළ budget එක ගන්න
  double getCategoryBudget(String category) {
    return categoryBudgets[category] ?? 0.0;
  }

  /// Category එකකට අදාළ budget එක update කරන්න
  BudgetModel updateCategoryBudget(String category, double amount) {
    Map<String, double> updated = Map.from(categoryBudgets);
    updated[category] = amount;
    return copyWith(
      categoryBudgets: updated,
      updatedAt: DateTime.now(),
    );
  }

  /// Month/Year එකට අදාළ unique key එක (Firestore doc ID සඳහා)
  String get monthYearKey => '${year}_${month.toString().padLeft(2, '0')}';

  /// Budget එකේ percentage එක calculate කරන්න (spent vs budget)
  double getPercentage(double spent) {
    if (totalBudget <= 0) return 0.0;
    return (spent / totalBudget) * 100;
  }

  // ==========================================
  // TO STRING (Debug කරන්න)
  // ==========================================
  @override
  String toString() {
    return 'BudgetModel(id: $id, totalBudget: $totalBudget, month: $month, year: $year)';
  }
}
