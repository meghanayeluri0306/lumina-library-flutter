import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

// గ్లోబల్ వేరియబుల్: యాప్ మొత్తంలో ఎక్కడైనా థీమ్ ని మార్చడానికి ఇది ఉపయోగపడుతుంది
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() => runApp(const LuminaApp());

class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context){ 
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
        
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF5A4FCF),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: Color(0xFF5A4FCF)),
              elevation: 0,
            ),
          ),
          
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF5A4FCF),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: Colors.white),
              elevation: 0,
            ),
            cardColor: const Color(0xFF1E1E1E),
            drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1A1A1A)),
          ),
          
          themeMode: currentMode,
          home: const LoginScreen(), 
        );
      },
    );
  }
}