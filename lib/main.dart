import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import ' features/auth/splash/animated_splash_screen.dart';
import ' features/auth/services/auth_service.dart';
import 'core/services/local_notifications_service.dart';

/// Nota - Smart Notes & Diary App with AI (Based on alNota)
/// Main entry point of the application
/// 
/// Co-authored-by: Ali-0110
/// Co-authored-by: abdelrahman-hesham11
/// Co-authored-by: Mahmoud13MA
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (portrait only like alNota)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
  
  // Initialize Notifications
  try {
    final notificationsService = LocalNotificationsService();
    await notificationsService.initialize();
    await notificationsService.requestPermissions();
    debugPrint('✅ Notifications initialized successfully');
  } catch (e) {
    debugPrint('❌ Notifications initialization error: $e');
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
        title: 'Nota - ملاحظاتك الذكية',
        debugShowCheckedModeBanner: false,
        theme: _buildAlNotaTheme(),
        darkTheme: _buildAlNotaTheme(),
        themeMode: ThemeMode.light,
        home: const AnimatedSplashScreen(),
        // RTL for Arabic support like alNota
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  /// Build theme matching alNota design
  ThemeData _buildAlNotaTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.tajawal().fontFamily,
      primaryColor: const Color(0xFFFFB800), // Golden yellow from alNota
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFFFB800),
        secondary: const Color(0xFFFFD900),
        surface: Colors.white,
        error: Colors.red.shade400,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFB800),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFB800),
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB800),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB800), width: 2),
        ),
        labelStyle: GoogleFonts.tajawal(color: Colors.grey.shade700),
        hintStyle: GoogleFonts.tajawal(color: Colors.grey.shade400),
      ),
    );
  }
}
