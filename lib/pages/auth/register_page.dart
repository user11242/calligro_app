import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/colors.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'services/auth_service.dart';
import 'google_register_wizard.dart'; // ✅ import the wizard
import 'verification_wizard_page.dart'; // ✅ popup wizard

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final portfolioController = TextEditingController();

  String fullPhoneNumber = "";
  final _authService = AuthService();
  bool isLoading = false;
  String selectedRole = "student"; // toggle state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGoogleHintDialog();
    });
  }

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  /// 🔹 Handle normal register → show verification wizard in popup
  Future<void> _handleRegister() async {
    if (passwordController.text != confirmController.text) {
      _showMessage("Passwords do not match", false);
      return;
    }
    if (selectedRole == "teacher" && fullPhoneNumber.isEmpty) {
      _showMessage("Please enter your phone number", false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationWizardPage(
        role: selectedRole,
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: fullPhoneNumber,
        name: nameController.text.trim(),
        portfolio: portfolioController.text.trim(),
      ),
    );
  }

  /// 🔹 Handle Google register
  Future<void> _handleGoogleRegister() async {
    final result = await _authService.signInWithGoogle();

    if (result == "NEEDS_ROLE") {
      final role = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const GoogleRegisterWizard(),
      );

      if (role != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VerificationWizardPage(
            role: role,
            email: FirebaseAuth.instance.currentUser?.email ?? "",
            password: "", // Google doesn’t need password
            phone: fullPhoneNumber,
            name: FirebaseAuth.instance.currentUser?.displayName ?? "",
            portfolio: portfolioController.text.trim(),
          ),
        );
      }
    } else if (result == "student" || result == "teacher") {
      Navigator.pushReplacementNamed(context, "/");
    } else if (result == "admin") {
      Navigator.pushReplacementNamed(context, "/adminDashboard");
    } else {
      _showMessage(result ?? "Google sign-in failed", false);
    }
  }

  /// 🔹 Google hint popup
  Future<void> _showGoogleHintDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.login, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Continue registration with Google",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Image.asset(
                      "assets/icons/circle_google_icon.png",
                      height: 24,
                      width: 24,
                    ),
                    label: const Text(
                      "Continue with Google",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleGoogleRegister();
                    },
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Maybe later",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 🔹 Background
          Positioned.fill(
            child: Image.asset("assets/backgrounds/main_background.jpg",
                fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          // 🔹 Title
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFEEE593), Color(0xFF8B4513)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Join us today and start your journey\nas a Student or Teacher.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Form Box
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: height * 0.7,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 🔹 Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: ["student", "teacher"].map((role) {
                          final isSelected = selectedRole == role;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedRole = role),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.textColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.textColor, width: 2)
                                      : null,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    role[0].toUpperCase() + role.substring(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.black
                                          : const Color(0xFFB0B0B0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 🔹 Common Fields
                    AuthTextField(
                        controller: nameController,
                        hint: "Full Name",
                        icon: Icons.person),
                    const SizedBox(height: 20),

                    // Email
                    AuthTextField(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 20),

                    AuthTextField(
                      controller: passwordController,
                      hint: "Password",
                      obscure: true,
                      showToggle: true,
                      isObscured: true,
                      icon: Icons.lock,
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      controller: confirmController,
                      hint: "Confirm Password",
                      obscure: true,
                      icon: Icons.lock_outline,
                    ),

                    // 🔹 Extra Fields for Teacher
                    if (selectedRole == "teacher") ...[
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
                        dropdownTextStyle:
                            const TextStyle(color: Colors.white),
                        onChanged: (phone) {
                          fullPhoneNumber = phone.completeNumber;
                        },
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: portfolioController,
                        hint: "Portfolio / Social Link",
                        icon: Icons.link,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Your registration will be submitted for approval.\nWe'll notify you once it's ready.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 25),
                    isLoading
                        ? const CircularProgressIndicator()
                        : AuthButton(text: "Register", onPressed: _handleRegister),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, "/LoginPage"),
                      child: const Text("Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
