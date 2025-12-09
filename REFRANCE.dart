import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:table_calendar/table_calendar.dart';

// Cloudinary Configuration
final cloudinary = CloudinaryPublic('dlbwwddv5', 'chat123', cache: false);

// Gemini API Key
const String geminiApiKey = 'AIzaSyDyTexcA5nzBO54Hq9KJ-gzgfVGMhsjrs0';

// تهيئة الإشعارات
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ar', null);

  // تهيئة الإشعارات
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AlNotaApp());
}

// التطبيق الرئيسي
class AlNotaApp extends StatelessWidget {
  const AlNotaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'النوتة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF58CC02),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        textTheme: GoogleFonts.tajawalTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58CC02),
          primary: const Color(0xFF58CC02),
          secondary: const Color(0xFFFFD900),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AnimatedSplashScreen(),
      locale: const Locale('ar', 'SA'),
    );
  }
}

// شاشة السبلاش المتحركة المحسنة
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({Key? key}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  bool _isInitialized = false;
  String _loadingMessage = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkUserAndNavigate();
  }

  void _initializeAnimations() {
    // Logo Animation Controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text Animation Controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Progress Animation Controller
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Logo Animations
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text Animation
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Progress Animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _progressController.forward();
    });
  }

  Future<void> _checkUserAndNavigate() async {
    // محاكاة تحميل البيانات
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _loadingMessage = 'جاري التحقق من المستخدم...');

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _loadingMessage = 'تحضير البيانات...');

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _loadingMessage = 'تقريباً جاهز...');

    // الانتظار لإكمال الأنيميشن
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isInitialized = true);

    // الانتقال إلى AuthWrapper
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF58CC02), Color(0xFF45A801), Color(0xFF3D9001)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background Animation
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: BackgroundPainter(
                        animation: _logoController.value,
                      ),
                    );
                  },
                ),
              ),
              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value * 0.1,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(35),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow Effect
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(
                                            0xFF58CC02,
                                          ).withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Icon
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(
                                      milliseconds: 1000,
                                    ),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: const Icon(
                                          Icons.book_rounded,
                                          size: 70,
                                          color: Color(0xFF58CC02),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    // App Name
                    FadeTransition(
                      opacity: _textAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_textController),
                        child: Column(
                          children: [
                            Text(
                              'النوتة',
                              style: GoogleFonts.tajawal(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'دفتر يومياتك الذكي',
                              style: GoogleFonts.tajawal(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Loading Progress
                    FadeTransition(
                      opacity: _textAnimation,
                      child: Column(
                        children: [
                          // Progress Bar
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Loading Message
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _loadingMessage,
                              key: ValueKey(_loadingMessage),
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Particles Effect
              ...List.generate(
                15,
                (index) => AnimatedParticle(
                  delay: Duration(milliseconds: index * 100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

// Animated Particle Widget
class AnimatedParticle extends StatefulWidget {
  final Duration delay;

  const AnimatedParticle({Key? key, required this.delay}) : super(key: key);

  @override
  State<AnimatedParticle> createState() => _AnimatedParticleState();
}

class _AnimatedParticleState extends State<AnimatedParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final double _startX = math.Random().nextDouble();
  final double _endX = math.Random().nextDouble();
  final double _size = math.Random().nextDouble() * 4 + 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 10 + math.Random().nextInt(10)),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left:
              MediaQuery.of(context).size.width *
              (_startX + (_endX - _startX) * (1 - _animation.value)),
          top: MediaQuery.of(context).size.height * _animation.value,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3 * (1 - _animation.value)),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Background Painter
class BackgroundPainter extends CustomPainter {
  final double animation;

  BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Wave 1
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * (0.3 + 0.1 * math.sin(animation * 2 * math.pi)),
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * (0.3 - 0.1 * math.sin(animation * 2 * math.pi)),
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Wave 2
    final path2 = Path();
    paint.color = Colors.white.withOpacity(0.03);

    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * (0.5 - 0.15 * math.sin(animation * 2 * math.pi + 1)),
      size.width * 0.5,
      size.height * 0.5,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * (0.5 + 0.15 * math.sin(animation * 2 * math.pi + 1)),
      size.width,
      size.height * 0.5,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Wrapper للتحقق من حالة تسجيل الدخول
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// شاشة التحميل
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58CC02),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جاري التحميل...',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// شاشة تسجيل الدخول المحسنة
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late AnimationController _formAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _formAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _formAnimationController.forward();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_isLogin) {
      if (value == null || value.isEmpty) {
        return 'الاسم مطلوب';
      }
      if (value.length < 3) {
        return 'الاسم يجب أن يكون 3 أحرف على الأقل';
      }
    }
    return null;
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // حفظ حالة تسجيل الدخول
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // إنشاء ملف المستخدم
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
              'preferences': {
                'theme': 'light',
                'notifications': true,
                'language': 'ar',
              },
              'stats': {
                'totalNotes': 0,
                'totalTasks': 0,
                'completedTasks': 0,
                'totalAppointments': 0,
                'totalExpenses': 0,
                'totalQuotes': 0,
              },
            });

        // إرسال رسالة ترحيب
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .collection('notes')
            .add({
              'type': 'note',
              'title': 'مرحباً بك في النوتة!',
              'content':
                  'نتمنى لك تجربة ممتعة في استخدام تطبيق النوتة. يمكنك البدء بإضافة ملاحظاتك ومهامك ومواعيدك.',
              'createdAt': FieldValue.serverTimestamp(),
              'isWelcomeNote': true,
            });
      }

      // نجاح تسجيل الدخول - عرض رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isLogin ? 'تم تسجيل الدخول بنجاح' : 'تم إنشاء الحساب بنجاح',
                  style: GoogleFonts.tajawal(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF58CC02),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getErrorMessage(e.code),
                    style: GoogleFonts.tajawal(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'operation-not-allowed':
        return 'العملية غير مسموح بها';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح بها، حاول لاحقاً';
      default:
        return 'حدث خطأ ما، حاول مرة أخرى';
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _formAnimationController.reset();
    _formAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF58CC02), Color(0xFF45A801)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Logo with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.book_rounded,
                              size: 60,
                              color: Color(0xFF58CC02),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'النوتة',
                      style: GoogleFonts.tajawal(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isLogin ? 'مرحباً بعودتك' : 'إنشاء حساب جديد',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Form Card with animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Name Field (for registration)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: !_isLogin
                                  ? Column(
                                      children: [
                                        _buildTextField(
                                          controller: _nameController,
                                          hint: 'الاسم الكامل',
                                          icon: Icons.person_outline,
                                          validator: _validateName,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            // Email Field
                            _buildTextField(
                              controller: _emailController,
                              hint: 'البريد الإلكتروني',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            // Password Field
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'كلمة المرور',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            if (_isLogin) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => _showForgotPasswordDialog(),
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: GoogleFonts.tajawal(
                                      color: const Color(0xFF58CC02),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _authenticate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF58CC02),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isLogin
                                            ? 'تسجيل الدخول'
                                            : 'إنشاء الحساب',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Toggle Auth Mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? 'ليس لديك حساب؟'
                                      : 'لديك حساب بالفعل؟',
                                  style: GoogleFonts.tajawal(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _toggleAuthMode,
                                  child: Text(
                                    _isLogin ? 'إنشاء حساب' : 'تسجيل الدخول',
                                    style: GoogleFonts.tajawal(
                                      color: const Color(0xFF58CC02),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.tajawal(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.tajawal(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF58CC02)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF58CC02), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset, color: Color(0xFF58CC02)),
            ),
            const SizedBox(width: 12),
            Text(
              'استعادة كلمة المرور',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابط استعادة كلمة المرور',
              style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.tajawal(),
              decoration: InputDecoration(
                hintText: 'البريد الإلكتروني',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF58CC02),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إرسال رابط الاستعادة إلى بريدك الإلكتروني',
                        style: GoogleFonts.tajawal(),
                      ),
                      backgroundColor: const Color(0xFF58CC02),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'حدث خطأ، تأكد من البريد الإلكتروني',
                        style: GoogleFonts.tajawal(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إرسال',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }
}

// الشاشة الرئيسية المحسنة
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';
  late GenerativeModel _model;

  // Data lists
  List<Map<String, dynamic>> _allNotes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _quotes = [];

  // Processing state
  List<Map<String, dynamic>> _extractedItems = [];
  bool _isProcessing = false;
  bool _isSearching = false;

  // Voice recording
  Timer? _speechTimer;
  bool _continuousListening = true;
  String _fullSpeechText = '';

  // User data
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _speech = stt.SpeechToText();
    _initializeGemini();
    _loadData();
    _loadUserData();
  }

  void _initializeGemini() {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (mounted) {
      setState(() {
        _userData = doc.data();
      });
    }
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _allNotes = snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();
              _filteredNotes = _allNotes;
              _categorizeNotes();
              _updateUserStats();
            });
          }
        });
  }

  void _categorizeNotes() {
    _tasks.clear();
    _appointments.clear();
    _expenses.clear();
    _quotes.clear();

    for (var note in _allNotes) {
      switch (note['type']) {
        case 'task':
          _tasks.add(note);
          break;
        case 'appointment':
          _appointments.add(note);
          break;
        case 'expense':
          _expenses.add(note);
          break;
        case 'quote':
          _quotes.add(note);
          break;
      }
    }
  }

  void _updateUserStats() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final completedTasks = _tasks.where((t) => t['completed'] == true).length;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'stats': {
        'totalNotes': _allNotes.length,
        'totalTasks': _tasks.length,
        'completedTasks': completedTasks,
        'totalAppointments': _appointments.length,
        'totalExpenses': _expenses.length,
        'totalQuotes': _quotes.length,
      },
    });
  }

  void _filterNotes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = _allNotes;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredNotes = _allNotes.where((note) {
        final title = note['title']?.toString().toLowerCase() ?? '';
        final content = note['content']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) || content.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                _buildTasksTab(),
                _buildAppointmentsTab(),
                _buildExpensesTab(),
                _buildQuotesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      drawer: _buildDrawer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_rounded, color: Color(0xFF58CC02)),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book_rounded,
              color: Color(0xFF58CC02),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'النوتة',
            style: GoogleFonts.tajawal(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C3C3C),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search_rounded, color: Colors.blue),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _filterNotes('');
              }
            });
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD900).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFFFFB800),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onPressed: () => _showNotifications(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterNotes,
          autofocus: true,
          style: GoogleFonts.tajawal(),
          decoration: InputDecoration(
            hintText: 'ابحث في ملاحظاتك...',
            hintStyle: GoogleFonts.tajawal(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterNotes('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF58CC02),
        indicatorWeight: 3,
        labelColor: const Color(0xFF58CC02),
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        tabs: [
          _buildTab(Icons.home_rounded, 'الرئيسية'),
          _buildTab(Icons.task_alt_rounded, 'المهام', _tasks.length),
          _buildTab(
            Icons.calendar_month_rounded,
            'المواعيد',
            _appointments.length,
          ),
          _buildTab(Icons.attach_money_rounded, 'المصروفات', _expenses.length),
          _buildTab(Icons.format_quote_rounded, 'اقتباسات', _quotes.length),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, [int? count]) {
    return Tab(
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.tajawal()),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF58CC02), Color(0xFF45A801)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF58CC02),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['name'] ?? 'المستخدم',
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard_rounded,
              title: 'لوحة التحكم',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.analytics_rounded,
              title: 'الإحصائيات',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.backup_rounded,
              title: 'النسخ الاحتياطي',
              onTap: () => _showBackupDialog(),
            ),
            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: 'الإعدادات',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_rounded,
              title: 'المساعدة',
              onTap: () => _showHelpDialog(),
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'تسجيل الخروج',
              color: Colors.red,
              onTap: () => _logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF58CC02),
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHomeTab() {
    final notes = _isSearching ? _filteredNotes : _allNotes;

    return AnimationLimiter(
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
          await _loadUserData();
        },
        color: const Color(0xFF58CC02),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              if (!_isSearching) ...[
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildStatsCards(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
              ],
              _buildSectionTitle(
                _isSearching
                    ? 'نتائج البحث (${notes.length})'
                    : 'آخر الملاحظات',
                Icons.history_rounded,
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                _buildEmptyState()
              else
                ...notes
                    .take(_isSearching ? notes.length : 10)
                    .map((note) => _buildNoteCard(note, showActions: true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
        ? 'مساء الخير'
        : 'مساء الخير';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF45A801)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting، ${_userData?['name'] ?? 'صديقي'}',
                  style: GoogleFonts.tajawal(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لديك ${_tasks.where((t) => t['completed'] != true).length} مهمة غير مكتملة',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              hour < 12
                  ? Icons.wb_sunny_rounded
                  : hour < 18
                  ? Icons.wb_twilight_rounded
                  : Icons.nightlight_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات سريعة',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: Icons.add_task_rounded,
                label: 'مهمة',
                color: const Color(0xFF58CC02),
                onTap: () => _showQuickAddDialog('task'),
              ),
              _buildQuickActionButton(
                icon: Icons.event_rounded,
                label: 'موعد',
                color: const Color(0xFFFFB800),
                onTap: () => _showQuickAddDialog('appointment'),
              ),
              _buildQuickActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'مصروف',
                color: Colors.blue,
                onTap: () => _showQuickAddDialog('expense'),
              ),
              _buildQuickActionButton(
                icon: Icons.format_quote_rounded,
                label: 'اقتباس',
                color: Colors.purple,
                onTap: () => _showQuickAddDialog('quote'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off_rounded : Icons.note_add_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _isSearching ? 'لا توجد نتائج للبحث' : 'لا توجد ملاحظات بعد',
              style: GoogleFonts.tajawal(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'جرب البحث بكلمات أخرى'
                  : 'ابدأ بإضافة ملاحظتك الأولى',
              style: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, {bool showActions = false}) {
    IconData icon;
    Color color;

    switch (note['type']) {
      case 'task':
        icon = Icons.task_alt_rounded;
        color = const Color(0xFF58CC02);
        break;
      case 'appointment':
        icon = Icons.calendar_month_rounded;
        color = const Color(0xFFFFB800);
        break;
      case 'expense':
        icon = Icons.attach_money_rounded;
        color = Colors.blue;
        break;
      case 'quote':
        icon = Icons.format_quote_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.note_rounded;
        color = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _showNoteDetails(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: showActions ? () => _showNoteOptions(note) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note['title'] ?? '',
                                style: GoogleFonts.tajawal(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (note['priority'] == 'high')
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'مهم',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note['content'] ?? '',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (note['date'] != null)
                              _buildInfoChip(
                                Icons.calendar_today,
                                _formatDate(note['date']),
                                Colors.orange,
                              ),
                            if (note['time'] != null) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                Icons.access_time,
                                note['time'],
                                Colors.blue,
                              ),
                            ],
                            if (note['amount'] != null) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                Icons.attach_money,
                                '${note['amount']} ${note['currency'] ?? 'ر.س'}',
                                Colors.green,
                              ),
                            ],
                            const Spacer(),
                            if (note['type'] == 'task')
                              Checkbox(
                                value: note['completed'] ?? false,
                                onChanged: (value) =>
                                    _toggleTaskComplete(note['id'], value!),
                                activeColor: const Color(0xFF58CC02),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            if (showActions)
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[600],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                itemBuilder: (BuildContext context) {
                                  return <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.visibility,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'عرض',
                                            style: GoogleFonts.tajawal(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'تعديل',
                                            style: GoogleFonts.tajawal(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'share',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.share, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'مشاركة',
                                            style: GoogleFonts.tajawal(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'حذف',
                                            style: GoogleFonts.tajawal(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                                onSelected: (String value) {
                                  switch (value) {
                                    case 'view':
                                      _showNoteDetails(note);
                                      break;
                                    case 'edit':
                                      _showEditNoteDialog(note);
                                      break;
                                    case 'share':
                                      _shareNote(note);
                                      break;
                                    case 'delete':
                                      _deleteNote(note['id']);
                                      break;
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        final dateTime = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(dateTime);
      } catch (e) {
        return date;
      }
    } else if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    }
    return '';
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // شاشة عرض تفاصيل الملاحظة
  void _showNoteDetails(Map<String, dynamic> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailsScreen(
          note: note,
          onEdit: () => _showEditNoteDialog(note),
          onDelete: () => _deleteNote(note['id']),
        ),
      ),
    );
  }

  // دالة تعديل الملاحظة
  void _showEditNoteDialog(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditNoteBottomSheet(
        note: note,
        onSave: (updatedNote) async {
          await _updateNote(note['id'], updatedNote);
        },
      ),
    );
  }

  Future<void> _updateNote(String noteId, Map<String, dynamic> data) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'تم تحديث الملاحظة بنجاح',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF58CC02),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareNote(Map<String, dynamic> note) {
    final text =
        '''
📝 ${note['title'] ?? ''}

${note['content'] ?? ''}

${note['date'] != null ? '📅 التاريخ: ${_formatDate(note['date'])}' : ''}
${note['time'] != null ? '⏰ الوقت: ${note['time']}' : ''}
${note['amount'] != null ? '💰 المبلغ: ${note['amount']} ${note['currency'] ?? 'ر.س'}' : ''}

تمت المشاركة من تطبيق النوتة 📱
    ''';

    // يمكنك استخدام حزمة share_plus للمشاركة
    // Share.share(text);

    // مؤقتاً نعرض رسالة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ النص للحافظة',
          style: GoogleFonts.tajawal(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF58CC02),
      ),
    );
  }

  void _showNoteOptions(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionItem(
              icon: Icons.visibility_rounded,
              title: 'عرض التفاصيل',
              onTap: () {
                Navigator.pop(context);
                _showNoteDetails(note);
              },
            ),
            _buildOptionItem(
              icon: Icons.edit_rounded,
              title: 'تعديل',
              onTap: () {
                Navigator.pop(context);
                _showEditNoteDialog(note);
              },
            ),
            _buildOptionItem(
              icon: Icons.copy_rounded,
              title: 'نسخ',
              onTap: () {
                Navigator.pop(context);
                _duplicateNote(note);
              },
            ),
            _buildOptionItem(
              icon: Icons.share_rounded,
              title: 'مشاركة',
              onTap: () {
                Navigator.pop(context);
                _shareNote(note);
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_rounded,
              title: 'حذف',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _deleteNote(note['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF3C3C3C),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  void _duplicateNote(Map<String, dynamic> note) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final newNote = Map<String, dynamic>.from(note);

    newNote.remove('id');
    newNote['title'] = '${note['title']} (نسخة)';
    newNote['createdAt'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(newNote);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم إنشاء نسخة من الملاحظة',
          style: GoogleFonts.tajawal(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF58CC02),
      ),
    );
  }

  // Quick Add Dialog
  void _showQuickAddDialog(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddBottomSheet(
        type: type,
        onSave: (data) async {
          await _saveNote(data);
        },
      ),
    );
  }

  Widget _buildStatsCards() {
    final completedTasks = _tasks.where((t) => t['completed'] == true).length;
    final pendingTasks = _tasks.length - completedTasks;
    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, expense) => sum + (expense['amount'] ?? 0).toDouble(),
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'المهام المعلقة',
          pendingTasks.toString(),
          Icons.pending_actions_rounded,
          const Color(0xFF58CC02),
          subtitle: 'من أصل ${_tasks.length}',
        ),
        _buildStatCard(
          'المواعيد القادمة',
          _getUpcomingAppointments().toString(),
          Icons.event_available_rounded,
          const Color(0xFFFFB800),
          subtitle: 'هذا الأسبوع',
        ),
        _buildStatCard(
          'إجمالي المصروفات',
          totalExpenses.toStringAsFixed(0),
          Icons.account_balance_wallet_rounded,
          Colors.blue,
          subtitle: 'ر.س',
        ),
        _buildStatCard(
          'الاقتباسات',
          _quotes.length.toString(),
          Icons.format_quote_rounded,
          Colors.purple,
          subtitle: 'اقتباس محفوظ',
        ),
      ],
    );
  }

  int _getUpcomingAppointments() {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));

    return _appointments.where((appointment) {
      if (appointment['date'] == null) return false;

      try {
        final date = DateTime.parse(appointment['date']);
        return date.isAfter(now) && date.isBefore(weekLater);
      } catch (e) {
        return false;
      }
    }).length;
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF58CC02), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // تابع _MainScreenState - الوظائف الخاصة بالتبويبات
  Widget _buildTasksTab() {
    final tasks = _tasks.where((task) {
      if (_isSearching && _searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final title = task['title']?.toString().toLowerCase() ?? '';
        final content = task['content']?.toString().toLowerCase() ?? '';
        return title.contains(query) || content.contains(query);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Task Statistics
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF58CC02), Color(0xFF45A801)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF58CC02).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTaskStat(
                'إجمالي',
                tasks.length.toString(),
                Icons.list_alt_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildTaskStat(
                'مكتملة',
                tasks.where((t) => t['completed'] == true).length.toString(),
                Icons.check_circle_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildTaskStat(
                'معلقة',
                tasks.where((t) => t['completed'] != true).length.toString(),
                Icons.pending_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('الكل', true, () {}),
              const SizedBox(width: 8),
              _buildFilterChip('مكتملة', false, () {}),
              const SizedBox(width: 8),
              _buildFilterChip('معلقة', false, () {}),
              const SizedBox(width: 8),
              _buildFilterChip('مهمة', false, () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tasks List
        if (tasks.isEmpty)
          _buildEmptyTaskState()
        else
          ...tasks.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  Widget _buildTaskStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF58CC02) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF58CC02) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.tajawal(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTaskState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'لا توجد مهام',
              style: GoogleFonts.tajawal(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isCompleted = task['completed'] ?? false;
    final priority = task['priority'] ?? 'low';

    return AnimationConfiguration.staggeredList(
      position: _tasks.indexOf(task),
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Dismissible(
              key: Key(task['id']),
              direction: DismissDirection.horizontal,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  _toggleTaskComplete(task['id'], !isCompleted);
                } else {
                  _deleteNote(task['id']);
                }
              },
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : const Color(0xFF58CC02).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Checkbox(
                    value: isCompleted,
                    onChanged: (value) =>
                        _toggleTaskComplete(task['id'], value!),
                    activeColor: const Color(0xFF58CC02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                title: Text(
                  task['title'] ?? '',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task['content'] != null && task['content'].isNotEmpty)
                      Text(
                        task['content'],
                        style: GoogleFonts.tajawal(
                          color: Colors.grey[600],
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (priority == 'high') _buildPriorityChip('high'),
                        if (task['tags'] != null)
                          ...(task['tags'] as List).map(
                            (tag) => Chip(
                              label: Text(
                                tag,
                                style: GoogleFonts.tajawal(fontSize: 12),
                              ),
                              backgroundColor: const Color(0xFFF0F0F0),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showNoteOptions(task),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            locale: 'ar',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFF58CC02),
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFF58CC02),
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF58CC02),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: GoogleFonts.tajawal(color: Colors.red),
              defaultTextStyle: GoogleFonts.tajawal(),
            ),
            eventLoader: (day) {
              return _appointments.where((appointment) {
                if (appointment['date'] == null) return false;
                try {
                  final date = DateTime.parse(appointment['date']);
                  return isSameDay(date, day);
                } catch (e) {
                  return false;
                }
              }).toList();
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _appointments.length,
            itemBuilder: (context, index) {
              final appointment = _appointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showNoteDetails(appointment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appointment['date'] != null
                          ? DateFormat(
                              'dd',
                            ).format(DateTime.parse(appointment['date']))
                          : '--',
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFB800),
                      ),
                    ),
                    Text(
                      appointment['date'] != null
                          ? DateFormat(
                              'MMM',
                              'ar',
                            ).format(DateTime.parse(appointment['date']))
                          : '--',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: const Color(0xFFFFB800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['title'] ?? '',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (appointment['time'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment['time'],
                            style: GoogleFonts.tajawal(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    if (appointment['location'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment['location'],
                            style: GoogleFonts.tajawal(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showNoteOptions(appointment),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    double totalExpenses = _expenses.fold<double>(
      0,
      (sum, expense) => sum + (expense['amount'] ?? 0).toDouble(),
    );

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي المصروفات',
                    style: GoogleFonts.tajawal(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalExpenses.toStringAsFixed(2)} ر.س',
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              return _buildExpenseCard(expense);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showNoteDetails(expense),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['title'] ?? '',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense['content'] ?? '',
                      style: GoogleFonts.tajawal(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${expense['amount'] ?? 0} ${expense['currency'] ?? 'ر.س'}',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _quotes.length,
      itemBuilder: (context, index) {
        final quote = _quotes[index];
        return _buildQuoteCard(quote);
      },
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    final colors = [
      const Color(0xFF58CC02),
      const Color(0xFFFFB800),
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];
    final color = colors[_quotes.indexOf(quote) % colors.length];

    return GestureDetector(
      onTap: () => _showNoteDetails(quote),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                quote['content'] ?? '',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'high':
        color = Colors.red;
        label = 'مهم';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'متوسط';
        break;
      default:
        color = Colors.green;
        label = 'عادي';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF45A801)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showInputOptions,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(
                  'إضافة ملاحظة',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInputOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'اختر طريقة الإدخال',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputOption(
                  icon: Icons.keyboard_rounded,
                  title: 'كتابة نص',
                  subtitle: 'اكتب ملاحظتك يدوياً',
                  color: const Color(0xFF58CC02),
                  onTap: () {
                    Navigator.pop(context);
                    _showTextInput();
                  },
                ),
                _buildInputOption(
                  icon: Icons.mic_rounded,
                  title: 'تسجيل صوتي',
                  subtitle: 'سجل ملاحظتك بصوتك',
                  color: const Color(0xFFFFB800),
                  onTap: () {
                    Navigator.pop(context);
                    _startVoiceInput();
                  },
                ),
                _buildInputOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'التقاط صورة',
                  subtitle: 'صور ملاحظتك وسنحولها لنص',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildInputOption(
                  icon: Icons.photo_library_rounded,
                  title: 'اختيار صورة',
                  subtitle: 'اختر صورة من المعرض',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // باقي الوظائف المساعدة
  void _showTextInput() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF58CC02),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'أضف ملاحظة جديدة',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _noteController,
                maxLines: 5,
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  hintText:
                      'اكتب ملاحظتك هنا...\nيمكنك كتابة عدة مهام ومواعيد ومصروفات في نص واحد',
                  hintStyle: GoogleFonts.tajawal(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD900).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD900).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFB800),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيقوم الذكاء الاصطناعي باستخراج جميع المهام والمواعيد والمصروفات من النص',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _noteController.clear();
              Navigator.pop(context);
            },
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_noteController.text.isNotEmpty) {
                Navigator.pop(context);
                await _processTextWithAI(_noteController.text);
                _noteController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'تحليل وحفظ',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // باقي الوظائف من الكود الأصلي
  Future<void> _processTextWithAI(String text) async {
    _showLoadingDialog('الذكاء الاصطناعي يحلل النص...');

    try {
      final prompt =
          '''
      قم بتحليل النص التالي واستخرج جميع العناصر المختلفة منه.
      
      النص: "$text"
      
      قم باستخراج:
      1. المهام - أي شيء يحتاج إلى إنجاز
      2. المواعيد - أي حدث له وقت أو تاريخ محدد  
      3. المصروفات - أي ذكر للمال أو المشتريات
      4. الاقتباسات - أي عبارات ملهمة أو حكم
      5. الملاحظات العامة
      
      أرجع النتيجة كـ JSON:
      {
        "items": [
          {
            "type": "task/appointment/expense/quote/note",
            "title": "عنوان مناسب قصير",
            "content": "المحتوى الكامل",
            "date": "التاريخ YYYY-MM-DD إن وجد",
            "time": "الوقت HH:MM إن وجد",
            "amount": رقم المبلغ إن وجد,
            "currency": "العملة",
            "priority": "high/medium/low",
            "tags": ["وسوم مناسبة"]
          }
        ]
      }
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      Navigator.pop(context);

      if (response.text != null) {
        final jsonStr = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '');
        final data = json.decode(jsonStr);

        if (data['items'] != null && data['items'] is List) {
          _extractedItems = List<Map<String, dynamic>>.from(data['items']);
          _showExtractedItemsDialog();
        } else {
          await _saveNote({
            'type': 'note',
            'title': text.length > 30 ? text.substring(0, 30) + '...' : text,
            'content': text,
          });
        }
      }
    } catch (e) {
      Navigator.pop(context);
      await _saveNote({
        'type': 'note',
        'title': text.length > 30 ? text.substring(0, 30) + '...' : text,
        'content': text,
      });
    }
  }

  Future<void> _startVoiceInput() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    bool available = await _speech.initialize();

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'التعرف على الصوت غير متاح',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _fullSpeechText = '';
    _speechText = '';
    _continuousListening = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [const Color(0xFFFFB800), const Color(0xFFFFD900)]
                        : [Colors.grey[400]!, Colors.grey[600]!],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isListening)
                      Lottie.network(
                        'https://assets10.lottiefiles.com/packages/lf20_p7ml1rhe.json',
                        width: 150,
                        height: 150,
                      ),
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isListening ? 'أستمع إليك...' : 'اضغط للتحدث',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 200,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _fullSpeechText.isEmpty
                        ? 'ابدأ بالتحدث...'
                        : _fullSpeechText,
                    style: GoogleFonts.tajawal(
                      color: _fullSpeechText.isEmpty
                          ? Colors.grey
                          : Colors.black,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _continuousListening = false;
                      _isListening = false;
                      _speechTimer?.cancel();
                      _speech.stop();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: Text(
                      'إلغاء',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_isListening) {
                        _continuousListening = false;
                        _isListening = false;
                        _speechTimer?.cancel();
                        await _speech.stop();
                        setDialogState(() => _isListening = false);

                        if (_fullSpeechText.isNotEmpty) {
                          Navigator.pop(context);
                          await _processTextWithAI(_fullSpeechText);
                          _fullSpeechText = '';
                        }
                      } else {
                        _continuousListening = true;
                        setDialogState(() => _isListening = true);
                        _startContinuousListening(setDialogState);
                      }
                    },
                    icon: Icon(
                      _isListening ? Icons.check : Icons.mic,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isListening ? 'حفظ' : 'تحدث',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening
                          ? const Color(0xFF58CC02)
                          : const Color(0xFFFFB800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startContinuousListening(StateSetter setDialogState) async {
    if (!_continuousListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          setDialogState(() {
            if (result.finalResult) {
              if (_fullSpeechText.isNotEmpty) {
                _fullSpeechText += ' ';
              }
              _fullSpeechText += result.recognizedWords;
              _speechText = '';
            } else {
              _speechText = result.recognizedWords;
            }
          });
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 60),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: 'ar-SA',
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      _showLoadingDialog('جاري معالجة الصورة...');

      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );

        final imageBytes = await File(image.path).readAsBytes();
        final prompt = '''
        قم بتحليل هذه الصورة واستخرج جميع المعلومات منها.
        ''';

        final content = [
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
        ];

        final response2 = await _model.generateContent(content);
        Navigator.pop(context);

        if (response2.text != null) {
          final jsonStr = response2.text!
              .replaceAll('```json', '')
              .replaceAll('```', '');
          final data = json.decode(jsonStr);

          if (data['items'] != null && data['items'] is List) {
            _extractedItems = List<Map<String, dynamic>>.from(data['items']);
            for (var item in _extractedItems) {
              item['imageUrl'] = response.secureUrl;
            }
            _showExtractedItemsDialog();
          }
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في معالجة الصورة', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExtractedItemsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF58CC02),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'تم استخراج ${_extractedItems.length} عنصر',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _extractedItems.length,
            itemBuilder: (context, index) {
              final item = _extractedItems[index];
              return _buildExtractedItemCard(item, index);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _extractedItems.clear();
              Navigator.pop(context);
            },
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveMultipleNotes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حفظ الكل',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedItemCard(Map<String, dynamic> item, int index) {
    IconData icon;
    Color color;
    String typeLabel;

    switch (item['type']) {
      case 'task':
        icon = Icons.task_alt_rounded;
        color = const Color(0xFF58CC02);
        typeLabel = 'مهمة';
        break;
      case 'appointment':
        icon = Icons.calendar_month_rounded;
        color = const Color(0xFFFFB800);
        typeLabel = 'موعد';
        break;
      case 'expense':
        icon = Icons.attach_money_rounded;
        color = Colors.blue;
        typeLabel = 'مصروف';
        break;
      case 'quote':
        icon = Icons.format_quote_rounded;
        color = Colors.purple;
        typeLabel = 'اقتباس';
        break;
      default:
        icon = Icons.note_rounded;
        color = Colors.grey;
        typeLabel = 'ملاحظة';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _extractedItems.removeAt(index);
                  });
                  Navigator.pop(context);
                  _showExtractedItemsDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item['title'] ?? '',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['content'] ?? '',
            style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _saveMultipleNotes() async {
    _showLoadingDialog('جاري حفظ ${_extractedItems.length} عنصر...');

    final userId = FirebaseAuth.instance.currentUser!.uid;
    int savedCount = 0;

    for (var item in _extractedItems) {
      item['createdAt'] = FieldValue.serverTimestamp();
      item['userId'] = userId;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add(item);

      savedCount++;

      if (item['type'] == 'appointment' &&
          item['date'] != null &&
          item['time'] != null) {
        _scheduleNotification(item);
      }
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'تم حفظ $savedCount عنصر بنجاح',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF58CC02),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    _extractedItems.clear();
  }

  Future<void> _saveNote(Map<String, dynamic> data) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    data['createdAt'] = FieldValue.serverTimestamp();
    data['userId'] = userId;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(data);

    if (data['type'] == 'appointment' &&
        data['date'] != null &&
        data['time'] != null) {
      _scheduleNotification(data);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'تم حفظ ${_getTypeLabel(data['type'])} بنجاح',
              style: GoogleFonts.tajawal(),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF58CC02),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'task':
        return 'المهمة';
      case 'appointment':
        return 'الموعد';
      case 'expense':
        return 'المصروف';
      case 'quote':
        return 'الاقتباس';
      default:
        return 'الملاحظة';
    }
  }

  void _scheduleNotification(Map<String, dynamic> data) async {
    // جدولة الإشعارات
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.tajawal(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTaskComplete(String taskId, bool value) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('notes')
        .doc(taskId)
        .update({'completed': value});
  }

  void _deleteNote(String noteId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تأكيد الحذف',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا العنصر؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('notes')
                  .doc(noteId)
                  .delete();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم الحذف بنجاح', style: GoogleFonts.tajawal()),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    // عرض الإشعارات
  }

  void _showBackupDialog() {
    // عرض نافذة النسخ الاحتياطي
  }

  void _showHelpDialog() {
    // عرض نافذة المساعدة
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'خروج',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _speechTimer?.cancel();
    _speech.stop();
    super.dispose();
  }
}

// شاشات إضافية
class NoteDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteDetailsScreen({
    Key? key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3C3C3C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTypeLabel(note['type'] ?? 'note'),
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3C3C3C),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF58CC02)),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTypeColor(note['type']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTypeIcon(note['type']),
                          color: _getTypeColor(note['type']),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note['title'] ?? 'بدون عنوان',
                              style: GoogleFonts.tajawal(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(note['createdAt']),
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    note['content'] ?? '',
                    style: GoogleFonts.tajawal(fontSize: 16, height: 1.6),
                  ),
                  if (note['imageUrl'] != null) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(note['imageUrl'], fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (note['date'] != null)
                        _buildDetailChip(
                          Icons.calendar_today,
                          _formatDateOnly(note['date']),
                          Colors.orange,
                        ),
                      if (note['time'] != null)
                        _buildDetailChip(
                          Icons.access_time,
                          note['time'],
                          Colors.blue,
                        ),
                      if (note['amount'] != null)
                        _buildDetailChip(
                          Icons.attach_money,
                          '${note['amount']} ${note['currency'] ?? 'ر.س'}',
                          Colors.green,
                        ),
                      if (note['priority'] != null)
                        _buildDetailChip(
                          Icons.flag,
                          _getPriorityLabel(note['priority']),
                          _getPriorityColor(note['priority']),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'task':
        return 'مهمة';
      case 'appointment':
        return 'موعد';
      case 'expense':
        return 'مصروف';
      case 'quote':
        return 'اقتباس';
      default:
        return 'ملاحظة';
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'task':
        return Icons.task_alt_rounded;
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'expense':
        return Icons.attach_money_rounded;
      case 'quote':
        return Icons.format_quote_rounded;
      default:
        return Icons.note_rounded;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'task':
        return const Color(0xFF58CC02);
      case 'appointment':
        return const Color(0xFFFFB800);
      case 'expense':
        return Colors.blue;
      case 'quote':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(date.toDate());
    }
    return '';
  }

  String _formatDateOnly(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'مهم';
      case 'medium':
        return 'متوسط';
      default:
        return 'عادي';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheets
class EditNoteBottomSheet extends StatefulWidget {
  final Map<String, dynamic> note;
  final Function(Map<String, dynamic>) onSave;

  const EditNoteBottomSheet({
    Key? key,
    required this.note,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditNoteBottomSheet> createState() => _EditNoteBottomSheetState();
}

class _EditNoteBottomSheetState extends State<EditNoteBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title']);
    _contentController = TextEditingController(text: widget.note['content']);
    _selectedType = widget.note['type'] ?? 'note';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تعديل الملاحظة',
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: GoogleFonts.tajawal(),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 5,
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  labelText: 'المحتوى',
                  labelStyle: GoogleFonts.tajawal(),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSave({
                          'title': _titleController.text,
                          'content': _contentController.text,
                          'type': _selectedType,
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF58CC02),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'حفظ التعديلات',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

class QuickAddBottomSheet extends StatefulWidget {
  final String type;
  final Function(Map<String, dynamic>) onSave;

  const QuickAddBottomSheet({
    Key? key,
    required this.type,
    required this.onSave,
  }) : super(key: key);

  @override
  State<QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<QuickAddBottomSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedDate;
  String? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'إضافة ${_getTypeLabel(widget.type)}',
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: GoogleFonts.tajawal(),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 3,
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  labelStyle: GoogleFonts.tajawal(),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (widget.type == 'expense') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.tajawal(),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    labelStyle: GoogleFonts.tajawal(),
                    suffixText: 'ر.س',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final data = {
                          'type': widget.type,
                          'title': _titleController.text,
                          'content': _contentController.text,
                        };

                        if (widget.type == 'expense' &&
                            _amountController.text.isNotEmpty) {
                          data['amount'] =
                              (double.tryParse(_amountController.text) ?? 0)
                                  as String;
                          data['currency'] = 'ر.س';
                        }

                        widget.onSave(data);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF58CC02),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'حفظ',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'task':
        return 'مهمة جديدة';
      case 'appointment':
        return 'موعد جديد';
      case 'expense':
        return 'مصروف جديد';
      case 'quote':
        return 'اقتباس جديد';
      default:
        return 'ملاحظة جديدة';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

// الشاشات الإضافية
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة التحكم', style: GoogleFonts.tajawal()),
        backgroundColor: const Color(0xFF58CC02),
      ),
      body: const Center(child: Text('لوحة التحكم')),
    );
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإحصائيات', style: GoogleFonts.tajawal()),
        backgroundColor: const Color(0xFF58CC02),
      ),
      body: const Center(child: Text('الإحصائيات')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات', style: GoogleFonts.tajawal()),
        backgroundColor: const Color(0xFF58CC02),
      ),
      body: const Center(child: Text('الإعدادات')),
    );
  }
}
