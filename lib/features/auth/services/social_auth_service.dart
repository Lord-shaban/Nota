import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/models/user_model.dart';

/// Social Authentication Service
/// Handles Google, Facebook, GitHub, and Biometric authentication
/// 
/// Co-authored-by: Ali-0110
/// Co-authored-by: abdelrahman hesham
/// Co-authored-by: ALi Sameh
class SocialAuthService {
  // Singleton pattern
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ============================================
  // GOOGLE SIGN IN
  // ============================================

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUser(
          userCredential.user!,
          provider: 'google',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } on PlatformException catch (e) {
      throw 'خطأ في تسجيل الدخول بجوجل: ${e.message}';
    } catch (e) {
      throw 'حدث خطأ أثناء تسجيل الدخول بجوجل: $e';
    }
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  /// Check if signed in with Google
  bool get isSignedInWithGoogle => _googleSignIn.currentUser != null;

  // ============================================
  // FACEBOOK SIGN IN
  // ============================================

  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      if (result.status == LoginStatus.failed) {
        throw 'فشل تسجيل الدخول بفيسبوك: ${result.message}';
      }

      // Get the access token
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        throw 'لم يتم الحصول على رمز الوصول';
      }

      // Create a credential from the access token
      final OAuthCredential credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      // Sign in to Firebase with the Facebook credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUser(
          userCredential.user!,
          provider: 'facebook',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'حدث خطأ أثناء تسجيل الدخول بفيسبوك: $e';
    }
  }

  /// Sign out from Facebook
  Future<void> signOutFromFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('Error signing out from Facebook: $e');
    }
  }

  // ============================================
  // GITHUB SIGN IN
  // ============================================

  /// Sign in with GitHub
  Future<UserCredential?> signInWithGitHub() async {
    try {
      // Create a new provider
      GithubAuthProvider githubProvider = GithubAuthProvider();
      
      // Add scopes if needed
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');

      // Sign in with popup for web, or redirect for mobile
      final UserCredential userCredential;
      
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(githubProvider);
      } else {
        userCredential = await _auth.signInWithProvider(githubProvider);
      }

      // Create or update user in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUser(
          userCredential.user!,
          provider: 'github',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'حدث خطأ أثناء تسجيل الدخول بجيت هب: $e';
    }
  }

  // ============================================
  // BIOMETRIC AUTHENTICATION
  // ============================================

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = 
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = 
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'قم بتأكيد هويتك للمتابعة',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = true,
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  /// Authenticate and sign in (for users who have biometric enabled)
  /// This requires the user to have saved their credentials locally
  Future<bool> biometricSignIn() async {
    try {
      // First verify biometric
      final authenticated = await authenticateWithBiometrics(
        localizedReason: 'قم بتأكيد هويتك لتسجيل الدخول',
      );

      if (!authenticated) {
        return false;
      }

      // Check if there's a current user session
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Refresh the token
        await currentUser.reload();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Biometric sign in error: $e');
      return false;
    }
  }

  // ============================================
  // APPLE SIGN IN (iOS/macOS)
  // ============================================

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Create an AppleAuthProvider
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      // Sign in with Apple
      final UserCredential userCredential;
      
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(appleProvider);
      } else {
        userCredential = await _auth.signInWithProvider(appleProvider);
      }

      // Create or update user in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUser(
          userCredential.user!,
          provider: 'apple',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'حدث خطأ أثناء تسجيل الدخول بأبل: $e';
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Create or update user document in Firestore
  Future<void> _createOrUpdateUser(
    User user, {
    required String provider,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // Update existing user
        await userDoc.update({
          'lastLoginAt': Timestamp.now(),
          'lastProvider': provider,
          'providers': FieldValue.arrayUnion([provider]),
        });
      } else {
        // Create new user
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
        );

        await userDoc.set({
          ...userModel.toJson(),
          'providers': [provider],
          'lastProvider': provider,
        });
      }
    } catch (e) {
      debugPrint('Error creating/updating user: $e');
    }
  }

  /// Sign out from all providers
  Future<void> signOutAll() async {
    await signOutFromGoogle();
    await signOutFromFacebook();
    await _auth.signOut();
  }

  /// Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'يوجد حساب مسجل بهذا البريد الإلكتروني بطريقة أخرى';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صالحة';
      case 'operation-not-allowed':
        return 'طريقة تسجيل الدخول هذه غير مفعلة';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'user-not-found':
        return 'لم يتم العثور على المستخدم';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'popup-closed-by-user':
        return 'تم إغلاق نافذة تسجيل الدخول';
      case 'cancelled-popup-request':
        return 'تم إلغاء طلب تسجيل الدخول';
      case 'popup-blocked':
        return 'تم حظر النافذة المنبثقة';
      default:
        return 'حدث خطأ: ${e.message ?? e.code}';
    }
  }

  /// Link current account with Google
  Future<UserCredential?> linkWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'لا يوجد مستخدم مسجل الدخول';

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await user.linkWithCredential(credential);

      // Update providers list
      await _firestore.collection('users').doc(user.uid).update({
        'providers': FieldValue.arrayUnion(['google']),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'حدث خطأ أثناء ربط الحساب بجوجل: $e';
    }
  }

  /// Link current account with Facebook
  Future<UserCredential?> linkWithFacebook() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'لا يوجد مستخدم مسجل الدخول';

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) return null;

      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) return null;

      final credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      final userCredential = await user.linkWithCredential(credential);

      // Update providers list
      await _firestore.collection('users').doc(user.uid).update({
        'providers': FieldValue.arrayUnion(['facebook']),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'حدث خطأ أثناء ربط الحساب بفيسبوك: $e';
    }
  }

  /// Unlink provider from current account
  Future<User?> unlinkProvider(String providerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'لا يوجد مستخدم مسجل الدخول';

      final updatedUser = await user.unlink(providerId);

      // Update providers list
      String providerName = providerId.replaceAll('.com', '');
      await _firestore.collection('users').doc(user.uid).update({
        'providers': FieldValue.arrayRemove([providerName]),
      });

      return updatedUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'حدث خطأ أثناء فصل الحساب: $e';
    }
  }

  /// Get linked providers for current user
  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    return user.providerData.map((info) => info.providerId).toList();
  }
}
