import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveAdminFcmToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _firestore.collection("users").doc(uid).update({
        "fcmToken": token,
      });
    }
  }
}
