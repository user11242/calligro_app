import 'package:calligro_app/pages/home_page.dart';
import 'package:calligro_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    initialRoute: "LoginPage",
    routes: {
      '/' : (context) => HomePage(),
      'LoginPage' : (context) => LoginPage()
    },

  ));
}