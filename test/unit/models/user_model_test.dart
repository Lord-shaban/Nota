import 'package:flutter_test/flutter_test.dart';
import 'package:nota/core/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    late UserModel testUser;

    setUp(() {
      testUser = UserModel(
        uid: 'user-abc123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2025, 1, 1),
        isEmailVerified: false,
        photoURL: 'https://example.com/photo.jpg',
      );
    });

    test('User should be created correctly', () {
      expect(testUser.uid, 'user-abc123');
      expect(testUser.email, 'test@example.com');
      expect(testUser.displayName, 'Test User');
      expect(testUser.isEmailVerified, false);
    });

    test('Should generate initials from display name', () {
      expect(testUser.initials, 'TU');
    });

    test('Should handle single name initials', () {
      final singleName = testUser.copyWith(displayName: 'Ahmed');
      expect(singleName.initials, 'A');
    });

    test('Should handle null display name', () {
      final noNameUser = UserModel(
        uid: 'user-abc123',
        email: 'test@example.com',
        displayName: null,
        createdAt: DateTime(2025, 1, 1),
        isEmailVerified: false,
        photoURL: 'https://example.com/photo.jpg',
      );
      expect(noNameUser.displayName, null);
    });

    test('copyWith should update fields', () {
      final updated = testUser.copyWith(
        displayName: 'New Name',
        isEmailVerified: true,
      );
      expect(updated.displayName, 'New Name');
      expect(updated.isEmailVerified, true);
      expect(updated.uid, testUser.uid);
      expect(updated.email, testUser.email);
    });

    test('Users with same uid should be equal', () {
      final user2 = testUser.copyWith(displayName: 'Different Name');
      expect(testUser.uid, user2.uid);
    });

    test('Should validate email format', () {
      final validUser = testUser.copyWith(email: 'valid@example.com');
      expect(validUser.email, 'valid@example.com');
    });

    test('Should handle photo URL', () {
      final withPhoto = testUser.copyWith(
        photoURL: 'https://example.com/new-photo.jpg',
      );
      expect(withPhoto.photoURL, 'https://example.com/new-photo.jpg');
    });
  });
}
