import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calligro_app/features/admin/pages/admin_users.dart';
import 'package:calligro_app/features/admin/pages/admin_pending_teachers.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, "/LoginPage");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2196F3)),
            child: Text(
              "Admin Menu",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white),
            title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // just closes the drawer, stays on Dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white),
            title: const Text("Users", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminUsersPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions, color: Colors.white),
            title: const Text("Pending Teachers", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPendingTeachersPage()),
              );
            },
          ),
          const Divider(color: Colors.white30),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
