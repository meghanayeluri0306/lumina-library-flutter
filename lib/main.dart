import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // మనం క్రియేట్ చేసిన కొత్త ఫోల్డర్ లింక్

void main() => runApp(const LuminaApp());

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginScreen(), // ఫస్ట్ లాగిన్ పేజీ లోడ్ అవుతుంది
    );
  }
}