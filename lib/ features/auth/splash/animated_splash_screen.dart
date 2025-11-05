import 'package:flutter/material.dart';
import '../login/login_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome Back!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AuthService().authStateChanges,
      initialData: true,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashUI();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const HomeScreen();
        }

        return FutureBuilder(
          future: Future.delayed(const Duration(seconds: 2)),
          builder: (context, timerSnapshot) {
            if (timerSnapshot.connectionState == ConnectionState.waiting) {
              return _buildSplashUI();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            });

            return Container();
          },
        );
      },
    );
  }

  Widget _buildSplashUI() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Nota App',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Mock animation/loading indicator
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
