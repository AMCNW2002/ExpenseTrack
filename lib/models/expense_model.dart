// models/expense_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class ExpenseModel {
  // ==========================================
  // PROPERTIES
  // ==========================================
  final String? id; // Firestore document ID (auto-generated)
  final String userId; // කාගේ expense එකද?
  final String title; // "Lunch", "Bus", "Shopping"
  final double amount; // Rs. 850.00
  final String category; // "Food", "Transport", etc.
  final DateTime date; // Expense එක කරපු දිනය
  final String? note; // Optional note
  final String? receiptUrl; // Optional receipt image URL
  final DateTime createdAt; // Record එක හදපු වෙලාව

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  ExpenseModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.receiptUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ==========================================
  // FROM MAP (Firestore එකෙන් ගන්නකොට)
  // ==========================================
  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExpenseModel(
      id: documentId,
      userId: map[AppConstants.fieldUserId] ?? '',
      title: map[AppConstants.fieldTitle] ?? '',
      amount: (map[AppConstants.fieldAmount] ?? 0).toDouble(),
      category: map[AppConstants.fieldCategory] ?? AppConstants.categoryOther,
      date: (map[AppConstants.fieldDate] as Timestamp?)?.toDate() ??
          DateTime.now(),
      note: map[AppConstants.fieldNote],
      receiptUrl: map['receiptUrl'],
      createdAt: (map[AppConstants.fieldCreatedAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  // ==========================================
  // TO MAP (Firestore එකට යවන්නකොට)
  // ==========================================
  Map<String, dynamic> toMap() {
    return {
      AppConstants.fieldUserId: userId,
      AppConstants.fieldTitle: title,
      AppConstants.fieldAmount: amount,
      AppConstants.fieldCategory: category,
      AppConstants.fieldDate: Timestamp.fromDate(date),
      AppConstants.fieldNote: note,
      'receiptUrl': receiptUrl,
      AppConstants.fieldCreatedAt: Timestamp.fromDate(createdAt),
    };
  }

  // ==========================================
  // COPY WITH (Expense එකේ කොටසක් වෙනස් කරන්න)
  // ==========================================
  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? receiptUrl,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==========================================
  // TO STRING (Debug කරන්න)
  // ==========================================
  @override
  String toString() {
    return 'ExpenseModel(id: $id, title: $title, amount: $amount, category: $category, date: $date)';
  }
}
