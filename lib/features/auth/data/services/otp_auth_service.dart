import 'package:firebase_auth/firebase_auth.dart';

class OtpAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Start phone verification
  Future<void> startPhoneVerification({
    required String phone,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
    Function()? autoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential cred) async {
          // ⚡ Instead of always signing in, check if user exists
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            await currentUser.linkWithCredential(cred);
          } else {
            await _auth.signInWithCredential(cred);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Phone verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (autoRetrievalTimeout != null) autoRetrievalTimeout();
        },
      );
    } catch (e) {
      onError("Failed to start phone verification: $e");
    }
  }

  /// 🔹 Verify OTP code
  Future<UserCredential?> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Link phone with existing account (recommended if user already signed in)
        return await currentUser.linkWithCredential(credential);
      } else {
        // Otherwise sign in directly
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      return null; // You can throw or return error info here
    }
  }
}
