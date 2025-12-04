import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'image_upload_service.dart';
import '../shared/input_models.dart';

class ImagePickerHandler {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  static Future<InputData?> pickFromGallery(BuildContext context) async {
    try {
      // Check gallery permission
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          _showPermissionDeniedDialog(context, 'المعرض');
          return null;
        }
      }

      // Show loading
      _showLoadingDialog(context, 'جاري فتح المعرض...');

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      Navigator.of(context).pop(); // Close loading

      if (image == null) return null;

      // Show preview and confirm dialog
      final confirmed = await _showImagePreviewDialog(
        context,
        File(image.path),
        'الصورة المختارة',
      );

      if (!confirmed) return null;

      // Upload image
      _showLoadingDialog(context, 'جاري رفع الصورة...');

      final imageUrl = await ImageUploadService.uploadImage(File(image.path));

      Navigator.of(context).pop(); // Close loading

      if (imageUrl != null) {
        // Create input data
        return InputData(
          type: InputType.gallery,
          content: '',
          title: 'صورة من المعرض',
          rawInput: image.path,
          timestamp: DateTime.now(),
          imageUrl: imageUrl,
          metadata: {
            'source': 'gallery',
            'fileName': image.name,
            'size': await File(image.path).length(),
          },
        );
      }

      return null;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close any open dialogs
        _showErrorDialog(context, 'خطأ في اختيار الصورة: ${e.toString()}');
      }
      return null;
    }
  }

  // Capture image from camera
  static Future<InputData?> captureFromCamera(BuildContext context) async {
    try {
      // Check camera permission
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          _showPermissionDeniedDialog(context, 'الكاميرا');
          return null;
        }
      }

      // Show loading
      _showLoadingDialog(context, 'جاري فتح الكاميرا...');

      // Capture image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      Navigator.of(context).pop(); // Close loading

      if (image == null) return null;

      // Show preview and confirm dialog
      final confirmed = await _showImagePreviewDialog(
        context,
        File(image.path),
        'الصورة الملتقطة',
      );

      if (!confirmed) {
        // Delete captured image if not confirmed
        await File(image.path).delete();
        return null;
      }

      // Upload image
      _showLoadingDialog(context, 'جاري رفع الصورة...');

      final imageUrl = await ImageUploadService.uploadImage(File(image.path));

      Navigator.of(context).pop(); // Close loading

      if (imageUrl != null) {
        return InputData(
          type: InputType.camera,
          content: '',
          title: 'صورة ملتقطة',
          rawInput: image.path,
          timestamp: DateTime.now(),
          imageUrl: imageUrl,
          metadata: {
            'source': 'camera',
            'fileName': image.name,
            'size': await File(image.path).length(),
          },
        );
      }

      return null;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close any open dialogs
        _showErrorDialog(context, 'خطأ في التقاط الصورة: ${e.toString()}');
      }
      return null;
    }
  }

  // Show image preview dialog
  static Future<bool> _showImagePreviewDialog(
    BuildContext context,
    File imageFile,
    String title,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Image Preview
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'إلغاء',
                          style: GoogleFonts.tajawal(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'استخدام الصورة',
                              style: GoogleFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  // Show permission denied dialog
  static void _showPermissionDeniedDialog(
    BuildContext context,
    String feature,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(
                'صلاحية مطلوبة',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            'يحتاج التطبيق إلى صلاحية الوصول إلى $feature لتتمكن من استخدام هذه الميزة.',
            style: GoogleFonts.tajawal(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.tajawal(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'فتح الإعدادات',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show loading dialog
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: GoogleFonts.tajawal(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // Show error dialog
  static void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text(
                'خطأ',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(error, style: GoogleFonts.tajawal(fontSize: 14)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'حسناً',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
