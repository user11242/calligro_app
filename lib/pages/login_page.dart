import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phone_number/phone_number.dart';
import 'package:calligro_app/theme/colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  bool isLoginSelected = true;
  String role = "student";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PhoneNumberUtil _phoneUtil = PhoneNumberUtil();

  bool _isValidEmail(String email) {
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return regex.hasMatch(email);
  }

  Future<bool> _isValidPhone(String phone) async {
    try {
      final parsed = await _phoneUtil.parse(phone);
      return parsed.e164 != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _register() async {
    try {
      if (passwordController.text != confirmController.text) {
        _showMessage("Passwords do not match", false);
        return;
      }

      if (!_isValidEmail(emailController.text.trim())) {
        _showMessage("Please enter a valid email address", false);
        return;
      }

      if (!await _isValidPhone(phoneController.text.trim())) {
        _showMessage("Please enter a valid phone number", false);
        return;
      }

      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "uid": userCred.user!.uid,
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "role": role.toLowerCase(),
        "status": role.toLowerCase() == "teacher" ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (role.toLowerCase() == "teacher") {
        _showMessage(
          "Teacher registration submitted. Wait for approval.",
          true,
        );
      } else {
        _showMessage("Student registered successfully.", true);
      }

      Navigator.pushReplacementNamed(context, "/");
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Registration failed", false);
    }
  }

  Future<void> _login() async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userCred.user!.uid)
          .get();

      if (!userDoc.exists) {
        _showMessage("User not found in Firestore.", false);
        await _auth.signOut();
        return;
      }

      String status = userDoc["status"];
      String role = userDoc["role"].toString().toLowerCase();

      if (role == "teacher" && status != "approved") {
        _showMessage("Your teacher account is still pending approval.", false);
        await _auth.signOut();
        return;
      }

      _showMessage("Login successful! Welcome back.", true);

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, "/adminDashboard");
      } else {
        Navigator.pushReplacementNamed(context, "/");
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Login failed", false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final userDoc =
          await _firestore.collection("users").doc(userCred.user!.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection("users").doc(userCred.user!.uid).set({
          "uid": userCred.user!.uid,
          "name": userCred.user!.displayName ?? "",
          "email": userCred.user!.email,
          "phone": userCred.user!.phoneNumber ?? "",
          "role": "student",
          "status": "approved",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      _showMessage("Google login successful!", true);

      final updatedUserDoc =
          await _firestore.collection("users").doc(userCred.user!.uid).get();

      String role = updatedUserDoc["role"].toString().toLowerCase();

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, "/adminDashboard");
      } else {
        Navigator.pushReplacementNamed(context, "/");
      }
    } catch (e) {
      _showMessage("Google sign-in failed: $e", false);
    }
  }

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/backgrounds/main_background.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: const Color.fromARGB(112, 0, 0, 0))),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {},
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Go ahead and set up\nyour account",
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
                    "Sign in-up to enjoy the best managing experience",
                    style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primary, // swapped background
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTabs(),
                          const SizedBox(height: 25),
                          isLoginSelected
                              ? _buildLoginForm()
                              : _buildRegisterForm(),
                          const SizedBox(height: 20),
                          _buildActionButton(),
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              "Or continue with",
                              style: TextStyle(color: Color(0xFFB0B0B0)),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildGoogleButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
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
    final selected = (isLoginSelected == loginTab);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isLoginSelected = loginTab;
          });
        },
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

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          emailController,
          "Email Address",
          Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          passwordController,
          "Password",
          Icons.lock,
          obscure: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, 'ForgotPassword');
              },
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
        _buildTextField(nameController, "Full Name", Icons.person),
        const SizedBox(height: 15),
        _buildTextField(
          emailController,
          "Email Address",
          Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          phoneController,
          "Phone Number",
          Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          passwordController,
          "Password",
          Icons.lock,
          obscure: true,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          confirmController,
          "Confirm Password",
          Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 20),
        const Text(
          "Register as:",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  "Student",
                  style: TextStyle(color: Color(0xFFB0B0B0)),
                ),
                value: "student",
                activeColor: AppColors.textColor,
                groupValue: role,
                onChanged: (value) {
                  setState(() => role = value!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  "Teacher",
                  style: TextStyle(color: Colors.white70),
                ),
                value: "teacher",
                activeColor: AppColors.textColor,
                groupValue: role,
                onChanged: (value) {
                  setState(() => role = value!);
                },
              ),
            ),
          ],
        ),
        if (role == "teacher") ...[
          const SizedBox(height: 10),
          const Text(
            "Your registration has been submitted for approval.\nWe’ll notify you once it’s ready.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.textColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.textColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.textColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.textColor, AppColors.textColor.withOpacity(0.7)],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: isLoginSelected ? _login : _register,
          child: Text(
            isLoginSelected ? "Login" : "Register",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _signInWithGoogle,
        child: Ink(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage("assets/icons/google_icon.png"),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
