import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

/// Authentication Service
/// Handles all authentication operations with Firebase
/// 
/// Co-authored-by: Ali-0110
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Current user model
  Stream<UserModel?> get currentUserStream {
    return authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      return await getUserData(user.uid);
    });
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Update last login time
      if (credential.user != null) {
        await updateLastLogin(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Create user document in Firestore
      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          displayName: displayName?.trim(),
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: false,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toJson());

        // Update display name if provided
        if (displayName != null && displayName.trim().isNotEmpty) {
          await credential.user!.updateDisplayName(displayName.trim());
        }

        // Send email verification
        await sendEmailVerification();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء إنشاء الحساب: $e';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء إرسال رابط استعادة كلمة المرور: $e';
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء إرسال رابط التحقق: $e';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'حدث خطأ أثناء تسجيل الخروج: $e';
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete auth account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء حذف الحساب: $e';
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName.trim());
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL.trim());
        }

        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          if (displayName != null) 'displayName': displayName.trim(),
          if (photoURL != null) 'photoURL': photoURL.trim(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء تحديث الملف الشخصي: $e';
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'حدث خطأ أثناء جلب بيانات المستخدم: $e';
    }
  }

  /// Update last login time
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      // Silently fail - this is not critical
      print('Failed to update last login: $e');
    }
  }

  /// Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'فشلت عملية إعادة المصادقة: $e';
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Re-authenticate first
      await reauthenticateWithPassword(currentPassword);

      // Change password
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ أثناء تغيير كلمة المرور: $e';
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح به، حاول مرة أخرى لاحقاً';
      case 'operation-not-allowed':
        return 'العملية غير مسموح بها';
      case 'requires-recent-login':
        return 'يتطلب إعادة تسجيل الدخول';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالشبكة';
      default:
        return 'حدث خطأ غير متوقع: ${e.message ?? e.code}';
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}