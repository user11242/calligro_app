import 'package:flutter/material.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Admin Dashboard",style: TextStyle(color: Colors.white),),
      backgroundColor: const Color(0xFF2196F3), // clean modern blue
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications),),
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
