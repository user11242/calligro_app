import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/colors.dart';

class GoogleRegisterWizard extends StatefulWidget {
  const GoogleRegisterWizard({super.key});

  @override
  State<GoogleRegisterWizard> createState() => _GoogleRegisterWizardState();
}

class _GoogleRegisterWizardState extends State<GoogleRegisterWizard> {
  int _step = 0;
  String selectedRole = "student";
  final phoneController = TextEditingController();
  final portfolioController = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool isLoading = false;

  void _nextStep() {
    // 🔹 Validation before moving to next step
    if (_step == 2 && selectedRole == "teacher") {
      if (phoneController.text.trim().isEmpty) {
        _showMessage("Please enter your phone number.");
        return;
      }
    }
    if (_step == 3 && selectedRole == "teacher") {
      if (portfolioController.text.trim().isEmpty) {
        _showMessage("Please enter your portfolio link.");
        return;
      }
    }
    setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _finish() async {
    setState(() => isLoading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    final data = {
      "uid": user.uid,
      "name": user.displayName ?? "",
      "email": user.email ?? "",
      "photoUrl": user.photoURL ?? "",
      "role": selectedRole,
      "status": selectedRole == "teacher" ? "pending" : "approved",
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (selectedRole == "teacher") {
      data["phone"] = phoneController.text.trim();
      data["portfolio"] = portfolioController.text.trim();
    }

    await _firestore.collection("users").doc(user.uid).set(data);

    setState(() => isLoading = false);

    if (!mounted) return;
    Navigator.pop(context, selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Close button top-right
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // 🔹 Step Content (fixed height)
                SizedBox(
                  height: 280, // fixed so it doesn’t resize with keyboard
                  child: Center(child: _buildStepContent()),
                ),

                const SizedBox(height: 20),

                // 🔹 Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_step > 0 && !(_step == 2 && selectedRole == "student"))
                      TextButton(
                        onPressed: _prevStep,
                        child: const Text("Back",
                            style: TextStyle(color: Colors.white70)),
                      ),
                    const Spacer(),
                    if (_step == 2 && selectedRole == "student")
                      ElevatedButton(
                        onPressed: _finish,
                        style: _btnStyle(),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)
                            : const Text("Finish"),
                      )
                    else if (_step == 4 && selectedRole == "teacher")
                      ElevatedButton(
                        onPressed: _finish,
                        style: _btnStyle(),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)
                            : const Text("Finish"),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _nextStep,
                        style: _btnStyle(),
                        icon: const Icon(Icons.arrow_forward, size: 20),
                        label: const Text("Next"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Step Router ----------
  Widget _buildStepContent() {
    if (_step == 0) return _buildWelcomeStep();
    if (_step == 1) return _buildRoleStep();
    if (_step == 2 && selectedRole == "student") return _buildStudentFinishStep();
    if (_step == 2 && selectedRole == "teacher") return _buildTeacherPhoneStep();
    if (_step == 3 && selectedRole == "teacher") return _buildTeacherPortfolioStep();
    if (_step == 4 && selectedRole == "teacher") return _buildTeacherFinishStep();
    return const SizedBox();
  }

  // ---------- Steps ----------
  Widget _buildWelcomeStep() {
    final user = _auth.currentUser;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : null,
          radius: 40,
          child: user?.photoURL == null
              ? const Icon(Icons.person, size: 40, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          "Hi, ${user?.displayName ?? "User"} 👋",
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          "We’ll just need a few more details to finish setting up your account.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRoleStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Choose Your Role",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        ToggleButtons(
          borderRadius: BorderRadius.circular(12),
          fillColor: AppColors.textColor,
          selectedColor: Colors.black,
          color: Colors.white70,
          isSelected: [selectedRole == "student", selectedRole == "teacher"],
          onPressed: (i) =>
              setState(() => selectedRole = i == 0 ? "student" : "teacher"),
          children: const [
            Padding(padding: EdgeInsets.all(12), child: Text("Student")),
            Padding(padding: EdgeInsets.all(12), child: Text("Teacher")),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentFinishStep() {
    return const Center(
      child: Text("Great! You’re all set.\nPress Finish to continue.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  Widget _buildTeacherPhoneStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Your Phone Number",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          decoration: _inputDecoration("Phone Number", Icons.phone),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildTeacherPortfolioStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Portfolio Link",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        TextField(
          controller: portfolioController,
          decoration:
              _inputDecoration("Portfolio Link (Instagram, etc.)", Icons.link),
        ),
      ],
    );
  }

  Widget _buildTeacherFinishStep() {
    return const Center(
      child: Text(
        "Your registration has been submitted for approval.\nYou’ll be notified once it’s approved.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  // ---------- Helpers ----------
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.amber.shade400,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
  }
}
