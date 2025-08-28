import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calligro_app/pages/admin/admin_app_bar.dart';
import 'package:calligro_app/pages/admin/admin_drawer.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- DASHBOARD OVERVIEW ----------
  Widget _buildOverview() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildStatCard("Total Users", Icons.people, Colors.blueAccent, "users"),
          _buildStatCard("Pending", Icons.pending, Colors.amberAccent, "pendingTeachers"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, String type) {
    return FutureBuilder<QuerySnapshot>(
      future: type == "users"
          ? _firestore.collection("users").get()
          : _firestore
              .collection("users")
              .where("role", isEqualTo: "teacher")
              .where("status", isEqualTo: "pending")
              .get(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const AdminAppBar(),
      drawer: const AdminDrawer(),
      body: _buildOverview(),
    );
  }
}
