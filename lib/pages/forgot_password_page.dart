import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calligro_app/theme/colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleResetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage("Please enter your email.", false);
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage("Please enter a valid email address.", false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔍 Check Firestore for user document with this email
      final query = await _firestore
          .collection("users")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showMessage("No account found with this email.", false);
      } else {
        final userData = query.docs.first.data();
        final status = userData["status"] ?? "pending";

        if (status != "approved") {
          _showMessage("Your account is not approved yet.", false);
        } else {
          // ✅ If approved, send reset email
          await _auth.sendPasswordResetEmail(email: email);
          _showMessage("Password reset email sent!", true);
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Error sending reset email", false);
    } catch (e) {
      _showMessage("Something went wrong. Try again.", false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: Image.asset(
              "assets/backgrounds/main_background.jpg",
              fit: BoxFit.cover,
            ),
          ),
          /// Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          /// Page title + Back button
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "Forgot your password?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Enter your email and we’ll send you a reset link.",
                      style: TextStyle(
                        color: AppColors.login_register_toggle_color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Bottom container with form
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: height * 0.45,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  /// Email Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                        hintText: "Email Address",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(Icons.email,
                            color: AppColors.textColor),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// Reset Button
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8B4513),
                          Color(0xFFEEE593),
                        ],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(55),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isLoading ? null : _handleResetPassword,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              "Send Reset Email",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
