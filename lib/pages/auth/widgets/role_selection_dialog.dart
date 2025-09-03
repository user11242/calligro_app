import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:calligro_app/theme/colors.dart';

class RoleSelectionDialog extends StatefulWidget {
  const RoleSelectionDialog({super.key});

  @override
  State<RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<RoleSelectionDialog> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
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
              const Icon(Icons.person_add_alt_1, color: Colors.white, size: 50),
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

              // 📌 Student option
              Container(
                decoration: BoxDecoration(
                  color: _selectedRole == "student"
                      ? AppColors.textColor.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioListTile<String>(
                  value: "student",
                  groupValue: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value),
                  activeColor: AppColors.textColor,
                  title: Text(
                    "Student",
                    style: TextStyle(
                      color: _selectedRole == "student"
                          ? AppColors.textColor
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 📌 Teacher option
              Container(
                decoration: BoxDecoration(
                  color: _selectedRole == "teacher"
                      ? AppColors.textColor.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioListTile<String>(
                  value: "teacher",
                  groupValue: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value),
                  activeColor: AppColors.textColor,
                  title: Text(
                    "Teacher",
                    style: TextStyle(
                      color: _selectedRole == "teacher"
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
                  backgroundColor: _selectedRole == null
                      ? Colors.white24
                      : AppColors.textColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _selectedRole == null
                    ? null
                    : () => Navigator.pop(context, _selectedRole),
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
  }
}

/// ✅ Helper function so you can call it directly
Future<String?> showRoleSelectionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const RoleSelectionDialog(),
  );
}
