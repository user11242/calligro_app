import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;       // student | teacher | admin
  final String status;     // approved | pending
  final String? phone;
  final String? portfolio;
  final String? fcmToken;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.portfolio,
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      status: map['status'] ?? 'pending',
      phone: map['phone'],
      portfolio: map['portfolio'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "role": role,
      "status": status,
      "phone": phone,
      "portfolio": portfolio,
      "fcmToken": fcmToken,
      "createdAt": createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
