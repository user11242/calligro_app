import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherProfileTab extends StatelessWidget {
  const TeacherProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.amber,
              child: Text(
                data["name"] != null && data["name"].isNotEmpty
                    ? data["name"][0].toUpperCase()
                    : "?",
                style: const TextStyle(fontSize: 40, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data["name"] ?? "Teacher",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              data["email"] ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text("Settings", style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, "/LoginPage");
                }
              },
            ),
          ],
        );
      },
    );
  }
}
