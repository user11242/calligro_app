import 'package:flutter/material.dart';
import 'package:calligro_app/core/theme/colors.dart';

class StepRole extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  const StepRole({super.key, required this.selectedRole, required this.onRoleChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Choose Your Role",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        ToggleButtons(
          borderRadius: BorderRadius.circular(12),
          fillColor: AppColors.textColor,
          selectedColor: Colors.black,
          color: Colors.white70,
          isSelected: [selectedRole == "student", selectedRole == "teacher"],
          onPressed: (i) => onRoleChanged(i == 0 ? "student" : "teacher"),
          children: const [
            Padding(padding: EdgeInsets.all(12), child: Text("Student")),
            Padding(padding: EdgeInsets.all(12), child: Text("Teacher")),
          ],
        ),
      ],
    );
  }
}
