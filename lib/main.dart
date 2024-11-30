import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_splitter/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Splitter',
      theme: ThemeData(
        brightness: Brightness.dark,
        cardColor: Colors.grey[850],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: AuthWrapper(),
    );
  }
}
