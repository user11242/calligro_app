import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // keep this for Firebase initialization
// import 'package:firebase_messaging/firebase_messaging.dart'; // 🔕 Notifications disabled
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import your feature pages
import 'package:calligro_app/features/admin/admin_dashboard.dart';
import 'package:calligro_app/features/admin/pages/admin_pending_teachers.dart';
import 'package:calligro_app/features/admin/pages/admin_users.dart';
import 'package:calligro_app/features/auth/pages/forgot_password_page.dart';
import 'package:calligro_app/features/auth/pages/register_page.dart';
import 'package:calligro_app/features/student/pages/home_page.dart';
import 'package:calligro_app/features/auth/pages/login_page.dart';
import 'package:calligro_app/features/student/pages/profile_page.dart';
import 'package:calligro_app/features/teacher/teacher_dashboard.dart';

/* 🔕 Disabled Firebase Messaging background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("📩 Background message received: ${message.notification?.title}");
}

Future<void> _saveTokenToFirestore(String token) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final role = userDoc.data()?['role'];

    if (role == "admin") {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "fcmToken": token,
      });
      debugPrint("✅ FCM Token saved for ADMIN: ${user.uid}");
    } else {
      debugPrint("⚠️ Not an admin, token not saved for user: ${user.uid}");
    }
  } else {
    debugPrint("⚠️ No logged-in user, token not saved");
  }
}
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /* 🔕 Disabled Firebase Messaging setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint("📌 User granted permission: ${settings.authorizationStatus}");

  String? token = await messaging.getToken();
  debugPrint("📌 Initial FCM Token: $token");

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint("🔄 FCM Token refreshed: $newToken");
    await _saveTokenToFirestore(newToken);
  });
  */

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: "/adminDashboard",
    routes: {
      '/': (context) => HomePage(),
      '/LoginPage': (context) => LoginPage(),
      '/RegisterPage': (context) => RegisterPage(),
      '/ProfilePage': (context) => ProfilePage(),
      '/forgotPassword': (context) => ForgotPasswordPage(),
      '/adminDashboard': (context) => AdminDashboardPage(),
      '/adminUsers': (context) => AdminUsersPage(),
      '/adminPendingTeachers': (context) => AdminPendingTeachersPage(),
      '/teacherDashboard': (context) => TeacherDashboardPage(),
    },
  ));

  /* 🔕 Disabled foreground and background Firebase Messaging listeners
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 Foreground message: ${message.notification?.title}");
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("📩 App opened from notification: ${message.notification?.title}");
  });
  */
}
