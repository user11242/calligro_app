import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// -------- MODEL --------
class TeacherModel {
  final String id;
  final String name;
  final String email;
  final String status;

  TeacherModel({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  factory TeacherModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      id: doc.id,
      name: data["name"] ?? "Unknown",
      email: data["email"] ?? "",
      status: data["status"] ?? "pending",
    );
  }
}

/// -------- TILE WIDGET --------
class TeacherTile extends StatelessWidget {
  final TeacherModel teacher;
  final FirebaseFirestore firestore;

  const TeacherTile({
    super.key,
    required this.teacher,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.amberAccent,
            child: Icon(Icons.school, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  teacher.email,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await firestore.collection("users").doc(teacher.id).update({
                "status": "approved",
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Teacher approved!")),
                );
              }
            },
            label: const Text("Approve"),
          ),
        ],
      ),
    );
  }
}

/// -------- PAGE --------
class AdminPendingTeachersPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminPendingTeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Pending Teachers"),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("users")
            .where("role", isEqualTo: "teacher")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teachers = snapshot.data!.docs
              .map((doc) => TeacherModel.fromDoc(doc))
              .toList();

          if (teachers.isEmpty) {
            return const Center(
              child: Text(
                "No pending teacher approvals",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            itemBuilder: (context, index) => TeacherTile(
              teacher: teachers[index],
              firestore: _firestore,
            ),
          );
        },
      ),
    );
  }
}
