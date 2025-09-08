import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/theme/colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../../../features/auth/data/services/auth_service.dart';
import 'teacher_extra_dialog.dart';
import '../pages/verification_wizard_page.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _authService = AuthService();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final phoneController = TextEditingController();
  final portfolioController = TextEditingController();

  String fullPhoneNumber = "";
  String selectedRole = "student";
  bool isLoading = false;

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  /// 🔹 Normal Email Register
  Future<void> _handleRegister() async {
    if (passwordController.text != confirmController.text) {
      _showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    final error = await _authService.registerWithEmail(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      confirmPassword: confirmController.text.trim(),
      role: selectedRole,
      phone: fullPhoneNumber,
      portfolio: portfolioController.text.trim(),
    );

    setState(() => isLoading = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    // ✅ Show verification wizard
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
    ).then((_) {
      if (selectedRole == "teacher") {
        Navigator.pushReplacementNamed(context, "/teacherDashboard");
      } else {
        Navigator.pushReplacementNamed(context, "/");
      }
    });
  }

  /// 🔹 Google Register
  Future<void> _handleGoogleRegister() async {
    final result = await _authService.loginWithGoogle();

    if (result == "NEEDS_ROLE") {
      if (selectedRole == "teacher") {
        // Teacher → open extra dialog (phone + OTP + portfolio)
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => TeacherExtraDialog(
            onSubmit: (phone, portfolio) {
              fullPhoneNumber = phone;
              portfolioController.text = portfolio;

              // After teacher extra details → verification wizard
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => VerificationWizardPage(
                  role: "teacher",
                  email: emailController.text.trim(),
                  password: "",
                  phone: fullPhoneNumber,
                  name: nameController.text.trim(),
                  portfolio: portfolioController.text.trim(),
                ),
              ).then((_) {
                Navigator.pushReplacementNamed(context, "/teacherDashboard");
              });
            },
          ),
        );
      } else {
        // Student → directly go to verification wizard
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VerificationWizardPage(
            role: "student",
            email: emailController.text.trim(),
            password: "",
            phone: fullPhoneNumber,
            name: nameController.text.trim(),
            portfolio: portfolioController.text.trim(),
          ),
        ).then((_) {
          Navigator.pushReplacementNamed(context, "/");
        });
      }
    } else if (result == "teacher") {
      Navigator.pushReplacementNamed(context, "/teacherDashboard");
    } else if (result == "student") {
      Navigator.pushReplacementNamed(context, "/");
    } else if (result == "admin") {
      Navigator.pushReplacementNamed(context, "/adminDashboard");
    } else {
      _showMessage(result ?? "Google sign-in failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 🔹 Toggle Student/Teacher
          Row(
            children: ["student", "teacher"].map((role) {
              final selected = selectedRole == role;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedRole = role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.textColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        role[0].toUpperCase() + role.substring(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.black : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          AuthTextField(controller: nameController, hint: "Full Name", icon: Icons.person),
          const SizedBox(height: 20),
          AuthTextField(controller: emailController, hint: "Email", icon: Icons.email),
          const SizedBox(height: 20),
          AuthTextField(controller: passwordController, hint: "Password", obscure: true, icon: Icons.lock),
          const SizedBox(height: 20),
          AuthTextField(controller: confirmController, hint: "Confirm Password", obscure: true, icon: Icons.lock_outline),

          if (selectedRole == "teacher") ...[
            const SizedBox(height: 20),
            IntlPhoneField(
              controller: phoneController,
              initialCountryCode: "US",
              onChanged: (phone) => fullPhoneNumber = phone.completeNumber,
            ),
            const SizedBox(height: 20),
            AuthTextField(controller: portfolioController, hint: "Portfolio Link", icon: Icons.link),
          ],

          const SizedBox(height: 25),
          isLoading
              ? const CircularProgressIndicator()
              : AuthButton(text: "Register", onPressed: _handleRegister),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, "/LoginPage"),
            child: const Text("Already have an account? Login"),
          ),
          const SizedBox(height: 12),

        ],
      ),
    );
  }
}
