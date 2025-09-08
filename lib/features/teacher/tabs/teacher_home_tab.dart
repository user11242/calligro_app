import 'package:flutter/material.dart';

class TeacherHomeTab extends StatelessWidget {
  const TeacherHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Welcome back 👋",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Here’s your teaching overview",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),

        // 📊 Stats
        Row(
          children: [
            _buildStatCard("Courses", "5", Icons.book, Colors.amber),
            const SizedBox(width: 16),
            _buildStatCard("Students", "120", Icons.people, Colors.green),
          ],
        ),
        const SizedBox(height: 20),

        // 🔔 Notifications
        Card(
          color: Colors.black45,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.amber),
            title: const Text("No new notifications",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text("You're all caught up 🎉",
                style: TextStyle(color: Colors.white70)),
          ),
        ),
        const SizedBox(height: 20),

        // 🚀 Quick Actions
        const Text(
          "Quick Actions",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _buildActionButton("Create Course", Icons.add_circle, Colors.amber),
            _buildActionButton("My Students", Icons.people_alt, Colors.teal),
            _buildActionButton("Earnings", Icons.attach_money, Colors.orange),
          ],
        ),
      ],
    );
  }

  static Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 32),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(title, style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionButton(String text, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to respective page
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
