import 'dart:async';

// This class simulates the operations that Firebase Auth will perform later.
class AuthService {
  // 1. Mock user state (is the user logged in?)
  bool _isLoggedIn = false;

  // 2. Mock Stream variable to monitor login/logout state
  // Used by the SplashScreen to decide where to navigate.
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  // Expose a stream that immediately yields the current state and then
  // forwards subsequent changes. A plain broadcast controller does not
  // replay the last value to new listeners, so the splash screen could
  // miss the current login state if it subscribes after the initial event.
  Stream<bool> get authStateChanges async* {
    yield _isLoggedIn;
    yield* _authStateController.stream;
  }

  // Singleton pattern for easy access throughout the app
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 3. Mock Sign In
  Future<void> signIn({required String email, required String password}) async {
    // Simulate network delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // Success condition
    if (email == 'test@example.com' && password == 'password') {
      _isLoggedIn = true;
      _authStateController.add(true); // Notify listeners that user is logged in
      return;
    } else {
      // Throw a simulated error for login failure
      throw 'Invalid credentials provided. Use test@example.com and password.';
    }
  }

  // 4. Mock Sign Up
  Future<void> signUp({required String email, required String password}) async {
    // Simulate network delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (password.length < 6) {
      throw 'Password must be at least 6 characters.';
    }
    // Success condition: No need to log in immediately after sign up
    return;
  }

  // 5. Mock Forgot Password Email
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return;
  }

  // 6. Mock Sign Out
  Future<void> signOut() async {
    _isLoggedIn = false;
    _authStateController.add(false); // Notify listeners that user is logged out
  }

  // Close resources if needed (call from app dispose if appropriate).
  void dispose() {
    _authStateController.close();
  }
}
