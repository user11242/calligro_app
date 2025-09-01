import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? photoUrl;
  final Map<String, dynamic> extraFields;

  UserModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.extraFields,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data["name"] ?? "No Name",
      photoUrl: data["photoUrl"],
      extraFields: Map.from(data)..removeWhere((k, _) =>
          ["name", "photoUrl", "userId", "uid", "createdAt"].contains(k)),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserModel user;
  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        leading: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
            ? CircleAvatar(
                backgroundImage: NetworkImage(user.photoUrl!),
                backgroundColor: Colors.transparent,
              )
            : const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
        title: Text(
          user.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: user.extraFields.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${entry.key}: ${entry.value}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminUsersPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Users"),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs.map((doc) => UserModel.fromDoc(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) => UserTile(user: users[index]),
          );
        },
      ),
    );
  }
}
