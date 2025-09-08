import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../auth/data/services/auth_service.dart';

class VerificationWizardPage extends StatefulWidget {
  final String role;
  final String email;
  final String password;
  final String phone;
  final String name;
  final String portfolio;

  const VerificationWizardPage({
    super.key,
    required this.role,
    required this.email,
    required this.password,
    required this.phone,
    required this.name,
    required this.portfolio,
  });

  @override
  State<VerificationWizardPage> createState() => _VerificationWizardPageState();
}

class _VerificationWizardPageState extends State<VerificationWizardPage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _step = 0; // 0: phone OTP, 1: email OTP, 2: finish
  bool isLoading = false;

  Timer? _resendTimer;
  int _resendCooldown = 0;

  List<TextEditingController> phoneOtpControllers =
      List.generate(6, (_) => TextEditingController());
  String? _phoneVerificationId;
  List<TextEditingController> emailOtpControllers =
      List.generate(6, (_) => TextEditingController());

  bool get isTeacher => widget.role == "teacher";

  @override
  void initState() {
    super.initState();
    _sendPhoneOtp();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in phoneOtpControllers) c.dispose();
    for (var c in emailOtpControllers) c.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // ---------- PHONE ----------
  Future<void> _sendPhoneOtp() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _nextStep();
        },
        verificationFailed: (FirebaseAuthException e) {
          _showMessage("Phone verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _phoneVerificationId = verificationId);
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _phoneVerificationId = verificationId);
        },
      );
    } catch (e) {
      _showMessage("Failed to send phone OTP: $e");
    }
  }

  Future<bool> _verifyPhoneOtp() async {
    final smsCode = phoneOtpControllers.map((c) => c.text).join();
    if (_phoneVerificationId == null || smsCode.length != 6) {
      _showMessage("Enter the 6-digit phone code");
      return false;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _phoneVerificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      _showMessage("Invalid phone OTP. Try again.");
      return false;
    }
  }

  // ---------- EMAIL ----------
  Future<void> _sendEmailOtp() async {
    try {
      final ok = await _authService.sendEmailOtp(widget.email);
      if (ok) {
        _startResendTimer();
      } else {
        _showMessage("Failed to send email OTP.");
      }
    } catch (e) {
      _showMessage("Failed to send email OTP: $e");
    }
  }

  Future<bool> _verifyEmailOtp() async {
    final otp = emailOtpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showMessage("Enter the 6-digit email code");
      return false;
    }
    setState(() => isLoading = true);
    final valid = await _authService.verifyEmailOtp(widget.email, otp);
    setState(() => isLoading = false);
    if (!valid) {
      _showMessage("Invalid or expired email OTP. Try again.");
    }
    return valid;
  }

  // ---------- FINISH ----------
  Future<void> _finishRegistration() async {
    setState(() => isLoading = true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      final user = credential.user;
      if (user == null) throw Exception("User creation failed");

      final data = {
        "uid": user.uid,
        "name": widget.name,
        "email": widget.email,
        "role": widget.role,
        "status": isTeacher ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      };
      if (isTeacher) {
        data["phone"] = widget.phone;
        data["portfolio"] = widget.portfolio;
      }

      await _firestore.collection("users").doc(user.uid).set(data);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/LoginPage");
    } catch (e) {
      _showMessage("Registration failed: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------- NAVIGATION ----------
  Future<void> _nextStep() async {
    if (_step == 0) {
      final ok = await _verifyPhoneOtp();
      if (!ok) return;
      _sendEmailOtp();
    } else if (_step == 1) {
      final ok = await _verifyEmailOtp();
      if (!ok) return;
    } else if (_step == 2) {
      await _finishRegistration();
      return;
    }
    setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ---------- MODERN OTP BOX WIDGET ----------
  Widget _otpInput(List<TextEditingController> controllers) {
    return SizedBox(
      width: 330,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) {
          return Container(
            width: 45,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: TextField(
              controller: controllers[i],
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
              ),
              onChanged: (val) {
                if (val.isNotEmpty && i < controllers.length - 1) {
                  FocusScope.of(context).nextFocus();
                } else if (val.isEmpty && i > 0) {
                  FocusScope.of(context).previousFocus();
                }
              },
            ),
          );
        }),
      ),
    );
  }

  // ---------- STEP CONTENT ----------
  Widget _buildStepContent() {
    if (_step == 0) {
      return Column(
        children: [
          const Text("Enter the code sent to your phone",
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          _otpInput(phoneOtpControllers),
        ],
      );
    } else if (_step == 1) {
      return Column(
        children: [
          const Text("Enter the code sent to your email",
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          _otpInput(emailOtpControllers),
        ],
      );
    } else {
      return const Text(
        "All verified ✅\nPress Finish to complete registration.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      );
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    const totalSteps = 3;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, "/RegisterPage");
                    },
                  ),
                ),
                Text("Step ${_step + 1} of $totalSteps",
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: Center(child: _buildStepContent()),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _resendCooldown == 0
                      ? (_step == 0
                          ? _sendPhoneOtp
                          : _step == 1
                              ? _sendEmailOtp
                              : null)
                      : null,
                  child: Text(
                    _resendCooldown == 0
                        ? "Resend Code"
                        : "Resend in $_resendCooldown s",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: _prevStep,
                        child: const Text("Back",
                            style: TextStyle(color: Colors.white70)),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade400,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)
                          : Text(_step == 2 ? "Finish" : "Next"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
