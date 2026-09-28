// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class UserModel {
  // ==========================================
  // PROPERTIES
  // ==========================================
  final String? id; // Firebase Auth UID
  final String name; // "Sachini Kumanayaka"
  final String email; // "sachini@email.com"
  final String? phone; // Optional phone number
  final String? photoUrl; // Optional profile picture URL
  final DateTime createdAt; // Account එක හදපු වෙලාව
  final DateTime? updatedAt; // අන්තිමට update කරපු වෙලාව

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ==========================================
  // FROM MAP (Firestore එකෙන් ගන්නකොට)
  // ==========================================
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map[AppConstants.fieldName] ?? '',
      email: map[AppConstants.fieldEmail] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
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
      AppConstants.fieldName: name,
      AppConstants.fieldEmail: email,
      'phone': phone,
      'photoUrl': photoUrl,
      AppConstants.fieldCreatedAt: Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // ==========================================
  // COPY WITH (User ගේ කොටසක් වෙනස් කරන්න)
  // ==========================================
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// User ගේ නමේ මුල් අකුරු දෙක (Profile avatar සඳහා)
  /// උදා: "Sachini Kumanayaka" → "SK"
  String get initials {
    if (name.trim().isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// First name එක විතරක් ගන්න
  String get firstName {
    if (name.trim().isEmpty) return '';
    return name.trim().split(' ').first;
  }

  // ==========================================
  // TO STRING (Debug කරන්න)
  // ==========================================
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email)';
  }
}
