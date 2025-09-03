import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/colors.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'widgets/role_selection_dialog.dart';
import 'services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _authService = AuthService();
  bool isLoading = false;

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);

    final result = await _authService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (result == "admin") {
      await _authService
          .saveAdminFcmToken(FirebaseAuth.instance.currentUser!.uid);
      _showMessage("Login successful! Welcome Boss!", true);
      Navigator.pushReplacementNamed(context, "/adminDashboard");
    } else if (result == "student" || result == "teacher") {
      _showMessage("Login successful! Welcome back.", true);
      Navigator.pushReplacementNamed(context, "/");
    } else {
      _showMessage(result ?? "Login failed", false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final result = await _authService.signInWithGoogle();

    if (result == "NEEDS_ROLE") {
      final chosenRole = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const RoleSelectionDialog(),
      );
      if (chosenRole == null) return;

      final createErr =
          await _authService.createGoogleUserWithRole(role: chosenRole);

      if (createErr == null) {
        if (chosenRole == "teacher") {
          _showMessage("Teacher registration submitted. Wait for approval.", true);
          await _authService.signOut();
        } else {
          _showMessage("Student registered successfully. Please login.", true);
          Navigator.pushReplacementNamed(context, "/");
        }
      } else {
        _showMessage(createErr, false);
      }
    } else if (result == "admin") {
      await _authService
          .saveAdminFcmToken(FirebaseAuth.instance.currentUser!.uid);
      _showMessage("Login successful! Welcome Boss!", true);
      Navigator.pushReplacementNamed(context, "/adminDashboard");
    } else if (result == "student" || result == "teacher") {
      _showMessage("Login successful! Welcome back.", true);
      Navigator.pushReplacementNamed(context, "/");
    } else {
      _showMessage(result ?? "Google sign-in failed", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 🔹 Fixed Background
          Positioned.fill(
            child: Image.asset(
              "assets/backgrounds/main_background.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          // 🔹 Scrollable content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  reverse: true, // keeps fields visible with keyboard
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 80),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFEEE593), Color(0xFF8B4513)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              "Welcome Back",
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
                            "We're happy to see you again.\nPlease login to continue.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // 🔹 Expanded Form
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(30),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 20),
                                  AuthTextField(
                                    controller: emailController,
                                    hint: "Email",
                                    icon: Icons.email,
                                  ),
                                  const SizedBox(height: 18),
                                  AuthTextField(
                                    controller: passwordController,
                                    hint: "Password",
                                    obscure: true,
                                    showToggle: true,
                                    isObscured: true,
                                    icon: Icons.lock,
                                  ),

                                  // 🔹 Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          Navigator.pushReplacementNamed(
                                              context, "/forgotPassword"),
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 14),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  isLoading
                                      ? const CircularProgressIndicator()
                                      : AuthButton(
                                          text: "Login", onPressed: _handleLogin),

                                  const SizedBox(height: 40), // ⬆ more spacing here

                                  // 🔹 Divider
                                  Row(
                                    children: const [
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white54,
                                              thickness: 0.8)),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          "Or continue with",
                                          style: TextStyle(
                                              color: AppColors
                                                  .login_register_toggle_color),
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white54,
                                              thickness: 0.8)),
                                    ],
                                  ),

                                  const SizedBox(height: 25),

                                  // 🔹 Google Button
                                  Center(
                                    child: SizedBox(
                                      height: 58,
                                      width: 58,
                                      child: ElevatedButton(
                                        onPressed: _handleGoogleLogin,
                                        style: ElevatedButton.styleFrom(
                                          shape: const CircleBorder(),
                                          padding: EdgeInsets.zero,
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            "assets/icons/circle_google_icon.png",
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 30),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushReplacementNamed(
                                            context, "/RegisterPage"),
                                    child: const Text(
                                        "Don't have an account? Register"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
