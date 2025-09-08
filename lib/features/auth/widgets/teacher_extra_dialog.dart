import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';

class TeacherExtraDialog extends StatefulWidget {
  final Function(String phone, String portfolio) onSubmit;

  const TeacherExtraDialog({super.key, required this.onSubmit});

  @override
  State<TeacherExtraDialog> createState() => _TeacherExtraDialogState();
}

class _TeacherExtraDialogState extends State<TeacherExtraDialog> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final portfolioController = TextEditingController();
  final otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  bool otpSent = false;
  bool isLoading = false;
  String fullPhoneNumber = "";

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (fullPhoneNumber.isEmpty) {
      _showMessage("Please enter a phone number");
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      verificationCompleted: (cred) {},
      verificationFailed: (e) {
        _showMessage("Phone verification failed: ${e.message}");
      },
      codeSent: (verificationId, _) {
        setState(() {
          otpSent = true;
          _verificationId = verificationId;
        });
        _showMessage("OTP sent to $fullPhoneNumber", success: true);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<bool> _verifyOtp(String otp) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _auth.signInWithCredential(cred);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!otpSent) {
      _showMessage("Please verify phone number with OTP");
      return;
    }

    setState(() => isLoading = true);
    final ok = await _verifyOtp(otpController.text.trim());
    setState(() => isLoading = false);

    if (!ok) {
      _showMessage("Invalid OTP");
      return;
    }

    widget.onSubmit(fullPhoneNumber, portfolioController.text.trim());
    Navigator.pop(context); // ✅ Close dialog
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Teacher Verification",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  IntlPhoneField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                    ),
                    initialCountryCode: "US",
                    style: const TextStyle(color: Colors.white),
                    dropdownTextStyle: const TextStyle(color: Colors.white),
                    onChanged: (phone) {
                      fullPhoneNumber = phone.completeNumber;
                    },
                    validator: (value) =>
                        (value == null || value.number.isEmpty)
                            ? "Enter phone number"
                            : null,
                  ),

                  const SizedBox(height: 12),

                  if (!otpSent)
                    ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Send OTP"),
                    ),

                  if (otpSent) ...[
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Enter OTP",
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextFormField(
                    controller: portfolioController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Portfolio Link",
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter portfolio link";
                      }
                      final urlRegex = RegExp(
                          r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/[\w\-./?%&=]*)?$');
                      if (!urlRegex.hasMatch(value)) {
                        return "Enter a valid link";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2)
                        : const Text("Continue"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
