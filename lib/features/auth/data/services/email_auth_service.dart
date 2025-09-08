import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore.collection("users").doc(userCred.user!.uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return "User not found";
      }

      final role = doc["role"];
      final status = doc["status"];

      if (role == "admin") return "admin";
      if (role == "teacher" && status != "approved") {
        await _auth.signOut();
        return "Teacher account pending approval";
      }

      return role; // "student" or "teacher"
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login failed";
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    String? phone,
    String? portfolio,
  }) async {
    if (name.isEmpty) return "Full name cannot be empty";
    if (password != confirmPassword) return "Passwords do not match";
    if (role == "teacher" && (phone == null || phone.isEmpty)) {
      return "Phone number is required for teachers";
    }
    return null; // ✅ success
  }
}
