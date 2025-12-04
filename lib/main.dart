import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import ' features/auth/splash/animated_splash_screen.dart';
import ' features/auth/services/auth_service.dart';

/// Nota - Smart Notes & Diary App with AI
/// Main entry point of the application
/// 
/// Co-authored-by: Ali-0110
/// Co-authored-by: abdelrahman-hesham11
/// Co-authored-by: Mahmoud13MA
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
  
  runApp(const NotaApp());
}

class NotaApp extends StatelessWidget {
  const NotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider(
      create: (_) => AuthService().authStateChanges,
      initialData: null,
      child: MaterialApp(
        title: 'Nota',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AnimatedSplashScreen(),
        // Disable animations for faster navigation during development
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
