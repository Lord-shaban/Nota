import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechToTextService {
  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  Function(String)? _onStatusChanged;
  Function(String)? _onError;

  SpeechToTextService() {
    _speech = stt.SpeechToText();
  }

  Future<bool> initialize({
    Function(String)? onStatus,
    Function(String)? onError,
  }) async {
    _onStatusChanged = onStatus;
    _onError = onError;

    try {
      // Check and request microphone permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _onError?.call('لم يتم منح إذن الميكروفون');
          return false;
        }
      }

      // Initialize speech recognition
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          _onStatusChanged?.call(status);
        },
        onError: (error) {
          _onError?.call(_getArabicErrorMessage(error.errorMsg));
        },
        debugLogging: false,
      );

      if (!_isInitialized) {
        _onError?.call('فشل تهيئة خدمة التعرف على الصوت');
      }

      return _isInitialized;
    } catch (e) {
      _onError?.call('خطأ في التهيئة: ${e.toString()}');
      return false;
    }
  }

  Future<void> startListening({
    required Function(SpeechRecognitionResult) onResult,
    String localeId = 'ar-SA', // Arabic Saudi Arabia by default
  }) async {
    if (!_isInitialized) {
      _onError?.call('الخدمة غير مهيأة');
      return;
    }

    try {
      await _speech.listen(
        onResult: onResult,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 60),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: localeId,
      );
    } catch (e) {
      _onError?.call('خطأ في بدء التسجيل: ${e.toString()}');
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      _onError?.call('خطأ في إيقاف التسجيل: ${e.toString()}');
    }
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (e) {
      _onError?.call('خطأ في إلغاء التسجيل: ${e.toString()}');
    }
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
  bool get hasPermission => _isInitialized;

  Future<List<stt.LocaleName>> getAvailableLocales() async {
    try {
      return await _speech.locales();
    } catch (e) {
      _onError?.call('خطأ في الحصول على اللغات المتاحة');
      return [];
    }
  }

  String _getArabicErrorMessage(String error) {
    // Translate common error messages to Arabic
    if (error.contains('permission')) {
      return 'لا يوجد إذن لاستخدام الميكروفون';
    } else if (error.contains('network')) {
      return 'خطأ في الاتصال بالشبكة';
    } else if (error.contains('busy')) {
      return 'الميكروفون مشغول';
    } else if (error.contains('no match')) {
      return 'لم يتم التعرف على الكلام';
    } else if (error.contains('timeout')) {
      return 'انتهت مدة الاستماع';
    } else {
      return 'خطأ: $error';
    }
  }

  void dispose() {
    _speech.stop();
    _speech.cancel();
  }
}
