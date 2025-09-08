import 'package:flutter/material.dart';

class TeacherCoursesTab extends StatelessWidget {
  const TeacherCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = ["Intro to Calligraphy", "Arabic Letters Basics"];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.amber),
            title: Text(courses[index],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text("20 students enrolled",
                style: TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            onTap: () {
              // 🔹 TODO: Open course details
            },
          ),
        );
      },
    );
  }
}
