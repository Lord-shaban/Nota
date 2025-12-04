import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import ' features/auth/splash/animated_splash_screen.dart';

/// Nota - Smart Notes & Diary App with AI
/// Main entry point of the application
/// 
/// Co-authored-by: Ali-0110
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const NotaApp());
}

class NotaApp extends StatelessWidget {
  const NotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nota',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AnimatedSplashScreen(),
    );
  }
}
