import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepWelcome extends StatelessWidget {
  final User? user;
  const StepWelcome({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
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
}
