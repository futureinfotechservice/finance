import 'package:financeapp/screens/home.dart';
import 'package:financeapp/screens/loan_issue_screen.dart';
import 'package:financeapp/screens/loan_type_master_screen.dart';
import 'package:financeapp/screens/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'masters/customermaster.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4318D1)),
        useMaterial3: true,
      ),
      // home: const CustomerManagementApp(),
      home: const LoginScreen(),
    );
  }
}

