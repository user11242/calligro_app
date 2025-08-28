import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Colors.grey[900], // dark modern background
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey[850], // darker header
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.amber,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 40, color: Colors.black)
                  : null,
            ),
            accountName: Text(
              user?.displayName ?? "Guest User",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              user?.email ?? "No email",
              style: const TextStyle(color: Colors.white70),
            ),
          ),

          // Profile
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.amber),
            title: const Text("Profile", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pushNamed(context, '/ProfilePage');
            },
          ),

          // Divider for sections
          const Divider(color: Colors.white24, thickness: 1),

          // Help & Support
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.amber),
            title: const Text(
              "Help & Support",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              // TODO: Navigate to help page or open FAQ dialog
            },
          ),

          // About Us
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.amber),
            title: const Text(
              "About Us",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              // TODO: Navigate to About page
            },
          ),

          const Divider(color: Colors.white24, thickness: 1),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, "LoginPage");
            },
          ),
        ],
      ),
    );
  }
}
