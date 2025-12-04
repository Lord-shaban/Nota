import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  // Cloudinary configuration (من الكود المرجعي)
  static final cloudinary = CloudinaryPublic(
    'dlbwwddv5',
    'chat123',
    cache: false,
  );

  // Upload to Cloudinary
  static Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  // Upload to Firebase Storage
  static Future<String?> uploadToFirebaseStorage(File imageFile) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'images/$userId/$timestamp.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(imageFile);

      if (uploadTask.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        return url;
      }

      return null;
    } catch (e) {
      print('Firebase Storage upload error: $e');
      return null;
    }
  }

  // Main upload function - tries Cloudinary first, then Firebase
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Try Cloudinary first
      final cloudinaryUrl = await uploadToCloudinary(imageFile);
      if (cloudinaryUrl != null) {
        return cloudinaryUrl;
      }

      // Fallback to Firebase Storage
      final firebaseUrl = await uploadToFirebaseStorage(imageFile);
      return firebaseUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  // Optimize image before upload
  static Future<File> optimizeImage(File imageFile) async {
    // TODO: Implement image optimization
    // Can use packages like flutter_image_compress
    return imageFile;
  }

  // Delete image from storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.contains('firebasestorage')) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
        return true;
      }
      // Cloudinary doesn't support direct deletion from client
      return false;
    } catch (e) {
      print('Image deletion error: $e');
      return false;
    }
  }
}
