import 'package:flutter/material.dart';
import 'package:calligro_app/theme/colors.dart';
import 'package:calligro_app/pages/app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: Appbar(),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.account_balance),
              title: const Text("Profile"),
            ),
          ],
        ),
      ),
      body: Stack(children: const [Background(), Header(),]),
    );
  }
}

class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/backgrounds/main_background.jpg",
            fit: BoxFit.cover,
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7), // dark at top
                  Colors.transparent, // fade out
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 150),
      child: Container(
        padding: EdgeInsets.only(left: 30),
        child: const Text(
          "A journey that begins from the first point",
          style: TextStyle(color: AppColors.textColor, fontSize: 40),
        ),
      ),
    );
  }
}
