import 'package:flutter/material.dart';

class StepTeacherFinish extends StatelessWidget {
  const StepTeacherFinish({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Your registration has been submitted for approval.\nYou’ll be notified once it’s approved.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
