import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';
import 'services/auth_service.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _step = 0;
  bool phoneVerified = false;
  bool isLoading = false;

  Timer? _resendTimer;
  int _resendCooldown = 60;

  List<TextEditingController> phoneOtpControllers =
      List.generate(6, (_) => TextEditingController());

  String? _verificationId;

  bool get isTeacher => widget.role == "teacher";

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in phoneOtpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- PHONE OTP ----------
  Future<void> _sendPhoneOtp() async {
    await AuthService().startPhoneVerification(
      phone: widget.phone,
      codeSent: (verificationId) {
        setState(() => _verificationId = verificationId);
        _showMessage("OTP sent to ${widget.phone}");
        _startResendCooldown();
      },
      onError: (error) => _showMessage(error),
    );
  }

  Future<void> _verifyPhoneOtp() async {
    if (_verificationId == null) {
      _showMessage("No OTP request found. Please resend.");
      return;
    }
    final code = phoneOtpControllers.map((c) => c.text.trim()).join("");
    final success = await AuthService()
        .verifySmsCode(verificationId: _verificationId!, smsCode: code);

    if (success) {
      setState(() => phoneVerified = true);
      _showMessage("Phone verified successfully!");
    } else {
      _showMessage("Invalid phone OTP");
    }
  }

  // ---------- TIMER ----------
  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  // ---------- NAVIGATION ----------
  void _nextStep() {
    if (_step == 0 && isTeacher && !phoneVerified) {
      _showMessage("Please verify your phone first.");
      return;
    }
    setState(() => _step++);
    if (_step == 0 && isTeacher) _sendPhoneOtp();
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
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
        "status": widget.role == "teacher" ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      };
      if (widget.role == "teacher") {
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

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ---------- OTP BOXES ----------
  Widget _otpBoxes(List<TextEditingController> controllers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: controllers[i],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // ✅ White text inside
            ),
            decoration: InputDecoration(
              counterText: "", // ✅ Remove counter
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && i < 5) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        );
      }),
    );
  }

  // ---------- STEP CONTENT ----------
  Widget _buildStepContent() {
    if (isTeacher && _step == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Enter Phone OTP",
              style: TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 16),
          _otpBoxes(phoneOtpControllers),
          const SizedBox(height: 20),

          // ✅ Modern Verify Button
          GestureDetector(
            onTap: _verifyPhoneOtp,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Verify",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: _resendCooldown == 0 ? _sendPhoneOtp : null,
            child: Text(
              _resendCooldown == 0
                  ? "Resend OTP"
                  : "Resend in $_resendCooldown s",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          if (phoneVerified)
            const Text("✅ Phone Verified!",
                style: TextStyle(color: Colors.green)),
        ],
      );
    }

    if ((!isTeacher && _step == 0) || (isTeacher && _step == 1)) {
      return const Center(
        child: Text("All set! 🎉\nPress Finish to continue.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    }

    return const SizedBox();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final totalSteps = isTeacher ? 2 : 1;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 350,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Text("Step ${_step + 1} of $totalSteps",
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              SizedBox(height: 280, child: Center(child: _buildStepContent())),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    TextButton(
                        onPressed: _prevStep,
                        child: const Text("Back",
                            style: TextStyle(color: Colors.white70))),
                  const Spacer(),
                  if ((!isTeacher && _step == 0) || (isTeacher && _step == 1))
                    ElevatedButton(
                        onPressed: _finish,
                        style: _btnStyle(),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)
                            : const Text("Finish"))
                  else
                    ElevatedButton.icon(
                        onPressed: _nextStep,
                        style: _btnStyle(),
                        icon: const Icon(Icons.arrow_forward, size: 20),
                        label: const Text("Next")),
                ],
              )
            ]),
          ),
        ),
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade400,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12));
  }
}
