import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut(); // also clear Google session
  }

  Future<void> saveAdminFcmToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _firestore.collection("users").doc(uid).update({
        "fcmToken": token,
      });
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc =
          await _firestore.collection("users").doc(userCred.user!.uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return "User not found";
      }

      final role = userDoc["role"];
      final status = userDoc["status"];

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

  /// ✅ Register now only validates inputs
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
    return null; // ✅ success, let VerificationWizardPage handle creation
  }

  Future<String?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // clear session

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "Google sign-in cancelled";

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final userDoc =
          await _firestore.collection("users").doc(userCred.user!.uid).get();

      if (userDoc.exists) {
        final role = userDoc["role"];
        final status = userDoc["status"];

        if (role == "teacher" && status != "approved") {
          await _auth.signOut();
          return "Teacher account pending approval";
        }

        return role; // "student", "teacher", or "admin"
      } else {
        return "NEEDS_ROLE";
      }
    } catch (e) {
      return "Google sign-in failed";
    }
  }

  // ✅ Google user creation with role assignment
  Future<String?> createGoogleUserWithRole({required String role}) async {
    final user = _auth.currentUser;
    if (user == null) return "Not signed in";

    await _firestore.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "name": user.displayName ?? "",
      "email": user.email,
      "phone": user.phoneNumber ?? "",
      "portfolio": "", // can be added later
      "role": role,
      "status": role == "teacher" ? "pending" : "approved",
      "createdAt": FieldValue.serverTimestamp(),
    });

    return null;
  }

  // ------------------ PHONE OTP (Firebase) ------------------

  Future<void> startPhoneVerification({
    required String phone,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Auto verification on Android
        await _auth.currentUser?.linkWithCredential(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "Phone verification failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Timeout reached
      },
    );
  }

  Future<bool> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.currentUser?.linkWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }
}
