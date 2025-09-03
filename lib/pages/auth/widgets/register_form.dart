import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_text_field.dart';
import 'auth_button.dart';
import 'role_selection_dialog.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onLoginTap;

  const RegisterForm({super.key, required this.onLoginTap});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
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

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      // 🔹 Ask user for role via dialog
      final chosenRole = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const RoleSelectionDialog(),
      );

      if (chosenRole == null) {
        setState(() => _loading = false);
        return;
      }

      final userCred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "uid": userCred.user!.uid,
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "role": chosenRole,
        "status": chosenRole == "teacher" ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        if (chosenRole == "teacher") {
          _showMessage(
              "Teacher registration submitted. Wait for approval.", true);
        } else {
          _showMessage("Student registered successfully. Please login.", true);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Registration failed", false);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthTextField(controller: nameController, hint: "Full Name", icon: Icons.person),
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
        const SizedBox(height: 20),
        _loading
            ? const CircularProgressIndicator()
            : AuthButton(text: "Register", onPressed: _register),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.onLoginTap,
          child: const Text("Already have an account? Login"),
        ),
      ],
    );
  }
}
