import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class GoogleHintDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const GoogleHintDialog({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Continue registration with Google",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Image.asset(
                  "assets/icons/circle_google_icon.png",
                  height: 24,
                  width: 24,
                ),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: onContinue, // ✅ no Navigator.pop here
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Maybe later",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
