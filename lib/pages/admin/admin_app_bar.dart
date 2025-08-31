import 'package:flutter/material.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        "Admin Dashboard",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF2196F3), // clean modern blue
      iconTheme: const IconThemeData(color: Colors.white), // ✅ icons white
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications, color: Colors.white), // ✅ white
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings, color: Colors.white), // ✅ white
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
