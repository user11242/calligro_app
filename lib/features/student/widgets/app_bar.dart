import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        "Calligro",
        style: TextStyle(color: AppColors.primary),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.primary),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.language),
          color: AppColors.primary,
        ),
      ],
    );
  }

  // 👇 Required for PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
