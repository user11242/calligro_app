import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_text_field.dart';
import 'auth_button.dart';
import 'role_selection_dialog.dart';
import '../services/auth_service.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onForgotPasswordTap;

  const LoginForm({
    super.key,
    required this.onRegisterTap,
    required this.onForgotPasswordTap,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _loading = false;

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveAdminFcmToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "fcmToken": token,
      });
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final result = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (result == "admin") {
        await _saveAdminFcmToken(FirebaseAuth.instance.currentUser!.uid);
        _showMessage("Login successful! Welcome Boss!", true);
        Navigator.pushReplacementNamed(context, "/adminDashboard");
      } else if (result == "student" || result == "teacher") {
        _showMessage("Login successful! Welcome back.", true);
        Navigator.pushReplacementNamed(context, "/");
      } else {
        _showMessage(result ?? "Login failed", false);
      }
    } catch (e) {
      _showMessage("Login failed: $e", false);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    final result = await _authService.signInWithGoogle();

    if (result == "NEEDS_ROLE") {
      // ask role
      final chosenRole = await showRoleSelectionDialog(context);
      if (chosenRole == null) return;

      final createErr =
          await _authService.createGoogleUserWithRole(role: chosenRole);

      if (createErr == null) {
        if (chosenRole == "teacher") {
          _showMessage("Teacher registration submitted. Wait for approval.", true);
          await _authService.signOut(); // prevent teacher login until approval
        } else {
          _showMessage("Student registered successfully. Please login.", true);
          Navigator.pushReplacementNamed(context, "/");
        }
      } else {
        _showMessage(createErr, false);
      }
    } else if (result == "admin") {
      await _saveAdminFcmToken(FirebaseAuth.instance.currentUser!.uid);
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
    return Column(
      children: [
        AuthTextField(
          controller: emailController,
          hint: "Email",
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email,
        ),
        AuthTextField(
          controller: passwordController,
          hint: "Password",
          obscure: true,
          showToggle: true,
          isObscured: true,
          icon: Icons.lock,
        ),
        const SizedBox(height: 16),
        _loading
            ? const CircularProgressIndicator()
            : AuthButton(text: "Login", onPressed: _login),
        const SizedBox(height: 12),
        AuthButton(
          text: "Login with Google",
          onPressed: _loginWithGoogle,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.onForgotPasswordTap,
          child: const Text(
            "Forgot Password?",
            style: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.onRegisterTap,
          child: const Text("Don't have an account? Register"),
        ),
      ],
    );
  }
}
