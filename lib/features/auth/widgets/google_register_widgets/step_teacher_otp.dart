import 'package:flutter/material.dart';

class StepTeacherOtp extends StatelessWidget {
  final List<TextEditingController> controllers;
  final String title;
  final String? errorText;

  const StepTeacherOtp({
    super.key,
    required this.controllers,
    required this.title,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 20),

        // 🔹 OTP Boxes
        SizedBox(
          width: 330,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(controllers.length, (i) {
              return Container(
                width: 45,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controllers[i],
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    errorText: i == 0 ? errorText : null, // show error once
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < controllers.length - 1) {
                      FocusScope.of(context).nextFocus();
                    } else if (val.isEmpty && i > 0) {
                      FocusScope.of(context).previousFocus();
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
