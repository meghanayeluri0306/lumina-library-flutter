import 'package:flutter/material.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'book_catalog_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  void loginLocalUser() {
    final username = userController.text.trim().toLowerCase();
    final password = passController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      final existingUsersStr = html.window.localStorage['app_users_db'];
      Map<String, dynamic> usersMap = {};

      if (existingUsersStr != null) {
        try { usersMap = json.decode(existingUsersStr) as Map<String, dynamic>; } 
        catch(e) { usersMap = {}; }
      }

      
      if (usersMap.containsKey(username) && usersMap[username] == password) {
        
        html.window.localStorage['username'] = userController.text.trim(); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookCatalogScreen()),
        );
      } else {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Username or Password! Access Denied.'), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Username and Password!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 80, color: Color(0xFF5A4FCF)),
              const SizedBox(height: 16),
              const Text('Welcome to Lumina', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Login securely to access your resources', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              TextField(controller: userController, decoration: InputDecoration(labelText: 'Username', prefixIcon: const Icon(Icons.person, color: Color(0xFF5A4FCF)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),

              TextField(controller: passController, obscureText: true, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock, color: Color(0xFF5A4FCF)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A4FCF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: loginLocalUser,
                  child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24), 

              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                child: const Text("Don't have an account? Register here", style: TextStyle(color: Color(0xFF5A4FCF), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}