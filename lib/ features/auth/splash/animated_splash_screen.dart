import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

// Dummy screen for the place where the user goes after successful login
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
                // Call the mock sign out function
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
    // StreamBuilder listens to the AuthService to check login status
    return StreamBuilder<bool>(
      stream: AuthService().authStateChanges,
      initialData: false, 
      builder: (context, snapshot) {
        
        // If the user is logged in (data == true)
        if (snapshot.hasData && snapshot.data == true) {
          // Navigate to the Dashboard (HomeScreen)
          return const HomeScreen();
        } 
        
        // If not logged in (data == false), show the Splash UI
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notes, size: 100, color: Colors.blue),
                SizedBox(height: 20),
                Text('Nota App', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                // Mock animation/loading indicator
                CircularProgressIndicator(), 
                SizedBox(height: 20),
                // We add a tiny delay here to ensure the animation shows up before navigating
                Text('Checking session...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}