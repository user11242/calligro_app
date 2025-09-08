import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calligro_app/features/admin/widgets/admin_app_bar.dart';
import 'package:calligro_app/features/admin/widgets/admin_drawer.dart';
import 'package:calligro_app/features/admin/widgets/stat_card.dart';

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
          _buildStatCard(
            title: "Total Users",
            icon: Icons.people,
            color: Colors.blueAccent,
            type: "users",
            route: "/adminUsers",
          ),
          _buildStatCard(
            title: "Pending",
            icon: Icons.pending,
            color: Colors.amberAccent,
            type: "pendingTeachers",
            route: "/adminPendingTeachers",
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required String type,
    required String route,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: type == "users"
          ? _firestore.collection("users").snapshots()
          : _firestore
              .collection("users")
              .where("role", isEqualTo: "teacher")
              .where("status", isEqualTo: "pending")
              .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return StatCard(
          title: title,
          icon: icon,
          color: color,
          count: count,
          onTap: () => Navigator.pushNamed(context, route),
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
