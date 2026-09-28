// models/goal_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class GoalModel {
  // ==========================================
  // PROPERTIES
  // ==========================================
  final String? id; // Firestore document ID
  final String userId; // කාගේ goal එකද?
  final String title; // "New Headphones"
  final double targetAmount; // Rs. 30,000
  final double savedAmount; // Rs. 18,500
  final DateTime? targetDate; // Goal එක ඉවර කරන්න ඕන දිනය (optional)
  final String? note; // Optional note
  final DateTime createdAt; // Record එක හදපු වෙලාව
  final DateTime? updatedAt; // අන්තිමට update කරපු වෙලාව

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  GoalModel({
    this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.targetDate,
    this.note,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ==========================================
  // FROM MAP (Firestore එකෙන් ගන්නකොට)
  // ==========================================
  factory GoalModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GoalModel(
      id: documentId,
      userId: map[AppConstants.fieldUserId] ?? '',
      title: map[AppConstants.fieldTitle] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      savedAmount: (map['savedAmount'] ?? 0).toDouble(),
      targetDate: (map['targetDate'] as Timestamp?)?.toDate(),
      note: map[AppConstants.fieldNote],
      createdAt: (map[AppConstants.fieldCreatedAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ==========================================
  // TO MAP (Firestore එකට යවන්නකොට)
  // ==========================================
  Map<String, dynamic> toMap() {
    return {
      AppConstants.fieldUserId: userId,
      AppConstants.fieldTitle: title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      AppConstants.fieldNote: note,
      AppConstants.fieldCreatedAt: Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // ==========================================
  // COPY WITH (Goal එකේ කොටසක් වෙනස් කරන්න)
  // ==========================================
  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Goal එකේ progress එක (0.0 - 1.0)
  /// උදා: 18500 / 30000 = 0.6167
  double get progress {
    if (targetAmount <= 0) return 0.0;
    double p = savedAmount / targetAmount;
    return p.clamp(0.0, 1.0); // 0ට වඩා අඩු හෝ 1ට වඩා වැඩි නොවෙන්න
  }

  /// Progress එක percentage එකක් විදියට (0 - 100)
  /// උදා: 62% (design එකේ පෙන්නන විදිය)
  int get progressPercentage {
    return (progress * 100).round();
  }

  /// Goal එක ඉවරද? (saved >= target)
  bool get isCompleted {
    return savedAmount >= targetAmount;
  }

  /// තව කීයක් ඉතුරු කරන්න ඕනද?
  double get remainingAmount {
    double remaining = targetAmount - savedAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Goal එකට තව කීයක් ඉතුරුද (percentage)
  int get remainingPercentage {
    return 100 - progressPercentage;
  }

  /// Target date එකට තව කීයක් දවස් ඉතුරුද?
  int? get daysRemaining {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  /// Target date එක ඉවර වෙලාද?
  bool get isOverdue {
    if (targetDate == null || isCompleted) return false;
    return DateTime.now().isAfter(targetDate!);
  }

  /// දවසකට කීයක් ඉතුරු කරන්න ඕනද? (target date එකක් තියෙනවා නම්)
  double? get dailySavingTarget {
    if (targetDate == null || isCompleted) return null;
    int days = daysRemaining ?? 0;
    if (days <= 0) return remainingAmount;
    return remainingAmount / days;
  }

  // ==========================================
  // TO STRING (Debug කරන්න)
  // ==========================================
  @override
  String toString() {
    return 'GoalModel(id: $id, title: $title, saved: $savedAmount/$targetAmount, progress: $progressPercentage%)';
  }
}
