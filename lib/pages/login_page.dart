import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_number/phone_number.dart';
import 'package:calligro_app/theme/colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


/// Handles Firebase authentication logic
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PhoneNumberUtil _phoneUtil = PhoneNumberUtil();

  Future<bool> _isValidEmail(String email) async {
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return regex.hasMatch(email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut(); // also sign out from Google
  }

  Future<bool> _isValidPhone(String phone) async {
    try {
      final parsed = await _phoneUtil.parse(phone);
      return parsed.e164.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{6,}$');
    return regex.hasMatch(password);
  }

  Future<String?> createGoogleUserWithRole({required String role}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "Not signed in";

      await _firestore.collection("users").doc(user.uid).set({
        "uid": user.uid,
        "name": user.displayName ?? "",
        "email": user.email,
        "phone": user.phoneNumber ?? "",
        "role": role,
        "status": role == "teacher" ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });
      return null; // success
    } catch (_) {
      return "Failed to create user profile";
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    try {
      if (name.isEmpty) return "Full name cannot be empty";
      if (password != confirmPassword) return "Passwords do not match";
      if (!await _isValidEmail(email)) return "Invalid email address";
      if (!await _isValidPhone(phone)) return "Invalid phone number";
      if (!_isValidPassword(password)) {
        return "Password must be at least 6 characters,\ninclude an uppercase letter, number and symbol";
      }

      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "uid": userCred.user!.uid,
        "name": name,
        "email": email,
        "phone": phone,
        "role": role,
        "status": role == "teacher" ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Registration failed";
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection("users")
          .doc(userCred.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return "User not found";
      }

      final role = userDoc["role"];
      final status = userDoc["status"];

      if (role == "admin") {
        return "admin";
      }

      if (role == "teacher" && status != "approved") {
        await _auth.signOut();
        return "Teacher account pending approval";
      }

      return role;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login failed";
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "Google sign-in cancelled";

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore
          .collection("users")
          .doc(userCred.user!.uid)
          .get();

      if (userDoc.exists) {
        final role = userDoc["role"];
        final status = userDoc["status"];

        if (role == "teacher" && status != "approved") {
          await _auth.signOut();
          return "Teacher account pending approval";
        }

        return role; // "admin" | "teacher" | "student"
      } else {
        return "NEEDS_ROLE";
      }
    } catch (_) {
      return "Google sign-in failed";
    }
  }
}

/// Custom text input field
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final bool showToggle;
  final bool isObscured;
  final VoidCallback? onToggle;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.showToggle = false,
    this.isObscured = false,
    this.onToggle,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscure
            ? (widget.showToggle ? widget.isObscured : true)
            : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
          ),
          prefixIcon: Icon(widget.icon, color: AppColors.textColor),
          border: InputBorder.none,
          suffixIcon: widget.showToggle
              ? IconButton(
                  icon: Icon(
                    widget.isObscured ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textColor,
                  ),
                  onPressed: widget.onToggle,
                )
              : null,
        ),
      ),
    );
  }
}

/// Toggle between Student and Teacher
class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ["student", "teacher"].map((role) {
        final isSelected = selectedRole == role;
        return Expanded(
          child: GestureDetector(
            onTap: () => onRoleChanged(role),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textColor : Colors.black26,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.textColor),
              ),
              child: Center(
                child: Text(
                  role[0].toUpperCase() + role.substring(1),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : AppColors.login_register_toggle_color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Tab selector for Login/Register
class TabSelector extends StatelessWidget {
  final bool isLoginSelected;
  final Function(bool) onTabChanged;

  const TabSelector({
    super.key,
    required this.isLoginSelected,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [_buildTab("Login", true), _buildTab("Register", false)],
      ),
    );
  }

  Widget _buildTab(String title, bool loginTab) {
    final selected = isLoginSelected == loginTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(loginTab),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: selected
                ? Border.all(color: AppColors.textColor, width: 2)
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.textColor : const Color(0xFFB0B0B0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient button for Login/Register actions
class GradientButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B4513), // Saddle Brown
            Color(0xFFEEE593), // your gold
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
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Circle Google button
class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      width: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const CircleBorder(),
        ),
        onPressed: onPressed,
        child: ClipOval(
          child: Image.asset(
            "assets/icons/circle_google_icon.png",
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// LoginPage with separated widgets
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String fullPhoneNumber = "";
  bool isLoginSelected = true;
  String role = "student";
  bool isPasswordObscured = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final _authService = AuthService();

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


  Future<void> _handleRegister() async {
    // Ask the user to pick role in a blurred dialog
    final chosenRole = await showRoleSelectionDialog(context);
    if (chosenRole == null)
      return; // user dismissed (shouldn't happen since not dismissible)

    final result = await _authService.register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: fullPhoneNumber.isNotEmpty
          ? fullPhoneNumber
          : phoneController.text.trim(),
      password: passwordController.text,
      confirmPassword: confirmController.text,
      role: chosenRole, // <-- use picked role
    );

    if (result == null) {
      _showMessage(
        chosenRole == "teacher"
            ? "Teacher registration submitted. Wait for approval."
            : "Student registered successfully. Please login.",
        true,
      );
      setState(() => isLoginSelected = true);
    } else {
      _showMessage(result, false);
    }
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please fill in both email and password.", false);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showMessage("Please enter a valid email address.", false);
      return;
    }

    final result = await _authService.login(email: email, password: password);

    if (result == "admin") {
        // ✅ Save admin FCM token
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveAdminFcmToken(user.uid);
      }
      _showMessage("Login successful! Welcome Boss!", true);
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacementNamed(context, "/adminDashboard");
    } else if (result == "student" || result == "teacher") {
      _showMessage("Login successful! Welcome back.", true);
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacementNamed(context, "/");
    } else {
      _showMessage(result ?? "Login failed", false);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _handleGoogleLogin() async {
    final result = await _authService.signInWithGoogle();

    if (result == "NEEDS_ROLE") {
      // Ask the user to pick role in a blurred dialog
      final chosenRole = await showRoleSelectionDialog(context);
      if (chosenRole == null) return; // user dismissed

      final createErr = await _authService.createGoogleUserWithRole(
        role: chosenRole,
      );

      if (createErr == null) {
        _showMessage(
          chosenRole == "teacher"
              ? "Teacher registration submitted. Wait for approval."
              : "Student registered successfully. Please login.",
          true,
        );

        if (chosenRole == "teacher") {
          await _authService.signOut(); // prevent teacher login until approval
          return;
        }

        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pushReplacementNamed(context, "/");
      } else {
        _showMessage(createErr, false);
      }

      return;
    }

    // Existing users
    if (result == "admin") {
        // ✅ Save admin FCM token
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveAdminFcmToken(user.uid);
      }
      _showMessage("Login successful! Welcome Boss!", true);
      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pushReplacementNamed(context, "/adminDashboard");
    } else if (result == "student" || result == "teacher") {
      _showMessage("Login successful! Welcome back.", true);
      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pushReplacementNamed(context, "/");
    } else {
      _showMessage(result ?? "Google sign-in failed", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/backgrounds/main_background.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 80),
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "Go ahead and set up\nyour account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Sign in-up to enjoy the best managing experience",
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: height * 2 / 3,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TabSelector(
                      isLoginSelected: isLoginSelected,
                      onTabChanged: (val) =>
                          setState(() => isLoginSelected = val),
                    ),
                    const SizedBox(height: 25),
                    isLoginSelected ? _buildLoginForm() : _buildRegisterForm(),
                    const SizedBox(height: 20),
                    GradientButton(
                      title: isLoginSelected ? "Login" : "Register",
                      onPressed: isLoginSelected
                          ? _handleLogin
                          : _handleRegister,
                    ),
                    const SizedBox(height: 20),
                    if (isLoginSelected) ...[
                      const Text(
                        "Or continue with",
                        style: TextStyle(
                          color: AppColors.login_register_toggle_color,
                        ),
                      ),
                      const SizedBox(height: 15),
                      GoogleButton(onPressed: _handleGoogleLogin),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        CustomTextField(
          controller: emailController,
          hint: "Email Address",
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: passwordController,
          hint: "Password",
          icon: Icons.lock,
          obscure: true,
          showToggle: true,
          isObscured: isPasswordObscured,
          onToggle: () {
            setState(() => isPasswordObscured = !isPasswordObscured);
          },
        ),
        Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, 'ForgotPassword'),
              child: const Text(
                "Forgot Password?",
                style: TextStyle(color: AppColors.textColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        CustomTextField(
          controller: nameController,
          hint: "Full Name",
          icon: Icons.person,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: emailController,
          hint: "Email Address",
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        IntlPhoneField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: "Phone Number",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            prefixIcon: const Icon(Icons.phone, color: AppColors.textColor),
          ),
          initialCountryCode: "US", // or "JO" for Jordan
          style: const TextStyle(color: Colors.white),
          dropdownTextStyle: const TextStyle(color: Colors.white),
          onChanged: (phone) {
            fullPhoneNumber = phone.completeNumber;
          },
        ),

        const SizedBox(height: 15),
        CustomTextField(
          controller: passwordController,
          hint: "Password",
          icon: Icons.lock,
          obscure: true,
          showToggle: true,
          isObscured: isPasswordObscured,
          onToggle: () {
            setState(() => isPasswordObscured = !isPasswordObscured);
          },
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: confirmController,
          hint: "Confirm Password",
          icon: Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 10),
        if (role == "teacher")
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Your registration will be submitted for approval.\nWe'll notify you once it's ready.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

// for the pop up student/teacher
Future<String?> showRoleSelectionDialog(BuildContext context) async {
  String? selectedRole;

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 40,
              ),
              backgroundColor: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🔙 Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 👤 Icon + Title
                    const Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 50,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Choose Your Role",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Are you signing up as a Student or a Teacher?\n"
                      "Teachers will need approval before accessing the system.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    // 📌 Radio List Tiles
                    Container(
                      decoration: BoxDecoration(
                        color: selectedRole == "student"
                            ? AppColors.textColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RadioListTile<String>(
                        value: "student",
                        groupValue: selectedRole,
                        onChanged: (value) =>
                            setState(() => selectedRole = value),
                        activeColor: AppColors.textColor,
                        title: Text(
                          "Student",
                          style: TextStyle(
                            color: selectedRole == "student"
                                ? AppColors.textColor
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: selectedRole == "teacher"
                            ? AppColors.textColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RadioListTile<String>(
                        value: "teacher",
                        groupValue: selectedRole,
                        onChanged: (value) =>
                            setState(() => selectedRole = value),
                        activeColor: AppColors.textColor,
                        title: Text(
                          "Teacher",
                          style: TextStyle(
                            color: selectedRole == "teacher"
                                ? AppColors.textColor
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ✅ Confirm button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedRole == null
                            ? Colors.white24
                            : AppColors.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: selectedRole == null
                          ? null
                          : () => Navigator.pop(context, selectedRole),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showLoginHintDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.blueGrey[900],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 50),
                const SizedBox(height: 16),
                const Text(
                  "Registration Info",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "When registering, you can choose to sign up as a Student or a Teacher.\n\n"
                  "Teachers will need admin approval before they can access the system.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueGrey[900],
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it"),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
