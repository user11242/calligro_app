import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../features/teacher/tabs/teacher_home_tab.dart';
import '../../features/teacher/tabs/teacher_courses_tab.dart';
import '../../features/teacher/tabs/teacher_profile_tab.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    TeacherHomeTab(),
    TeacherCoursesTab(),
    TeacherProfileTab(),
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🚫 disable back button
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Teacher Dashboard",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTap,
            backgroundColor: Colors.black87,
            selectedItemColor: Colors.amber,
            unselectedItemColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: "Courses"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ),
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () {
                  // 🔹 TODO: Navigate to course creation page
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Course"),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              )
            : null,
      ),
    );
  }
}
