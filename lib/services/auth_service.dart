// lib/services/auth_service.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/loginpage.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _emailKey = 'email';
  static const String _userIdKey = 'user_id';

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Save login credentials
  static Future<void> saveLoginCredentials({
    required String username,
    required String password,
    required String email,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_userIdKey, userId);
  }

  // Get saved credentials
  static Future<Map<String, String>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey) ?? '',
      'password': prefs.getString(_passwordKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'userId': prefs.getString(_userIdKey) ?? '',
    };
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    // Don't clear username/password if you want to allow auto-login next time
    // If you want to clear all data, uncomment the lines below:
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);
  }

  // Clear all credentials (for complete logout)
  static Future<void> clearAllCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);
  }
}


class LogoutService {
  static Future<void> logout(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool shouldLogout = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Logout'),
            content: Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Logout'),
              ),
            ],
          );
        },
      ) ?? false;

      if (shouldLogout) {
        // Clear login state
        await AuthService.logout();

        // Navigate to login screen and clear all routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Complete logout (clear all data)
  static Future<void> completeLogout(BuildContext context) async {
    try {
      await AuthService.clearAllCredentials();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Complete logout error: $e');
    }
  }}

