import 'package:flutter/material.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  void registerLocalUser() {
    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      
      final existingUsersStr = html.window.localStorage['app_users_db'];
      Map<String, dynamic> usersMap = {};
      
      if (existingUsersStr != null) {
        try { usersMap = json.decode(existingUsersStr) as Map<String, dynamic>; } 
        catch(e) { usersMap = {}; }
      }

    
      if (usersMap.containsKey(username.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken! Try another.'), backgroundColor: Colors.red),
        );
      } else {
        
        usersMap[username.toLowerCase()] = password;
        html.window.localStorage['app_users_db'] = json.encode(usersMap);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful! Please login.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create an Account', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A4FCF),
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 80, color: Color(0xFF5A4FCF)),
              const SizedBox(height: 16),
              const Text('Join Lumina', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              TextField(controller: userController, decoration: InputDecoration(labelText: 'New Username', prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5A4FCF)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              
              TextField(controller: passController, obscureText: true, decoration: InputDecoration(labelText: 'Create Password', prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5A4FCF)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A4FCF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: registerLocalUser,
                  child: const Text('Register', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}