import 'package:flutter/material.dart';

class StepStudentFinish extends StatelessWidget {
  const StepStudentFinish({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Great! You’re all set.\nPress Finish to continue.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
