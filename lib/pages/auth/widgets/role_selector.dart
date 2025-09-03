import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const RoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E1E1E),
      items: const [
        DropdownMenuItem(value: "student", child: Text("Student")),
        DropdownMenuItem(value: "teacher", child: Text("Teacher")),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}
