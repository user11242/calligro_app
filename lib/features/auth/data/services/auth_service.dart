import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_otp_service.dart';

// Modular services
import 'email_auth_service.dart';
import 'google_auth_service.dart';
import 'otp_auth_service.dart';
import 'fcm_service.dart';

class AuthService {
  final EmailAuthService _email = EmailAuthService();
  final GoogleAuthService _google = GoogleAuthService();
  final OtpAuthService _otp = OtpAuthService();
  final FcmService _fcm = FcmService();
  final EmailOtpService _emailOtp = EmailOtpService();

  /// 🔹 Unified sign-out (works for all providers)
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut(); // clear Google session too
  }

  // ============ EMAIL AUTH ============
  Future<String?> loginWithEmail(String email, String password) {
    return _email.login(email: email, password: password);
  }

  Future<String?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    String? phone,
    String? portfolio,
  }) {
    return _email.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
      phone: phone,
      portfolio: portfolio,
    );
  }

  // ============ GOOGLE AUTH ============
  Future<String?> loginWithGoogle() => _google.signInWithGoogle();

  Future<String?> createGoogleUserWithRole(String role) =>
      _google.createGoogleUserWithRole(role: role);

  // ============ PHONE OTP AUTH ============
  Future<void> startPhoneVerification({
    required String phone,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
    Function()? autoRetrievalTimeout,
  }) {
    return _otp.startPhoneVerification(
      phone: phone,
      codeSent: codeSent,
      onError: onError,
      autoRetrievalTimeout: autoRetrievalTimeout,
    );
  }

  Future<UserCredential?> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    return _otp.verifySmsCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  // ============ EMAIL OTP AUTH ============
  Future<bool> sendEmailOtp(String email) => _emailOtp.sendOtp(email);

  Future<bool> verifyEmailOtp(String email, String otp) =>
      _emailOtp.verifyOtp(email, otp);

  // ============ FCM ============
  /// Save admin FCM token for push notifications
  Future<void> saveAdminFcmToken(String uid) {
    return _fcm.saveAdminFcmToken(uid);
  }
}
