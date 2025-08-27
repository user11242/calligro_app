import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phone_number/phone_number.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  bool isLoginSelected = true;
  String role = "Student";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PhoneNumberUtil _phoneUtil = PhoneNumberUtil();

  // 🔹 Email validation
  bool _isValidEmail(String email) {
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return regex.hasMatch(email);
  }

  // 🔹 Phone validation
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
        "status": role == "Teacher" ? "pending" : "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (role == "Teacher") {
        _showMessage("Teacher registration submitted. Wait for approval.", true);
      } else {
        _showMessage("Student registered successfully.", true);
      }

      // ✅ Redirect after successful register
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

      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(userCred.user!.uid).get();

      if (!userDoc.exists) {
        _showMessage("User not found in Firestore.", false);
        await _auth.signOut();
        return;
      }

      String status = userDoc["status"];
      String role = userDoc["role"];

      if (role == "teacher" && status != "approved") {
        _showMessage("Your teacher account is still pending approval.", false);
        await _auth.signOut();
        return;
      }

      _showMessage("Login successful! Welcome back.", true);

      // ✅ Redirect after successful login
      Navigator.pushReplacementNamed(context, "/");

    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Login failed", false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
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

      // ✅ Redirect after Google login
      Navigator.pushReplacementNamed(context, "/");

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
          Positioned.fill(
            child: Container(color: Colors.black54),
          ),
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
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E), // Dark grey
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
                              style: TextStyle(color: Colors.white70),
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
        children: [
          _buildTab("Login", true),
          _buildTab("Register", false),
        ],
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
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: selected
                ? Border.all(color: Colors.amber, width: 2)
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.amber : Colors.white70,
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
        _buildTextField(emailController, "Email Address", Icons.email,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _buildTextField(passwordController, "Password", Icons.lock,
            obscure: true),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (value) {
                setState(() {
                  rememberMe = value ?? false;
                });
              },
            ),
            const Text("Remember me", style: TextStyle(color: Colors.white70)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text("Forgot Password?",
                  style: TextStyle(color: Colors.amber)),
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
        _buildTextField(emailController, "Email Address", Icons.email,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _buildTextField(phoneController, "Phone Number", Icons.phone,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        _buildTextField(passwordController, "Password", Icons.lock,
            obscure: true),
        const SizedBox(height: 15),
        _buildTextField(
            confirmController, "Confirm Password", Icons.lock_outline,
            obscure: true),
        const SizedBox(height: 20),
        const Text("Register as:",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Student", style: TextStyle(color: Colors.white70)),
                value: "Student",
                activeColor: Colors.amber,
                groupValue: role,
                onChanged: (value) {
                  setState(() => role = value!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Teacher", style: TextStyle(color: Colors.white70)),
                value: "Teacher",
                activeColor: Colors.amber,
                groupValue: role,
                onChanged: (value) {
                  setState(() => role = value!);
                },
              ),
            ),
          ],
        ),
        if (role == "Teacher") ...[
          const SizedBox(height: 10),
          const Text(
            "Your registration has been submitted for approval.\nWe’ll notify you once it’s ready.",
            style: TextStyle(
                fontSize: 13,
                color: Colors.white54,
                fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.amber),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.amber, width: 2),
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
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFFC6A664), Color(0xFFEDE5D1)]),
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: isLoginSelected ? _login : _register,
          child: Text(
            isLoginSelected ? "Login" : "Register",
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
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
            image: DecorationImage(
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
