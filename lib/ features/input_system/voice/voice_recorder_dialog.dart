import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'speech_to_text_service.dart';
import '../../../core/theme/app_theme.dart';
import 'voice_animations.dart';

class VoiceRecorderDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback? onCancel;

  const VoiceRecorderDialog({Key? key, required this.onSave, this.onCancel})
    : super(key: key);

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog>
    with TickerProviderStateMixin {
  final SpeechToTextService _speechService = SpeechToTextService();

  bool _isListening = false;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String _speechText = '';
  String _fullText = '';
  String? _errorMessage;

  Timer? _silenceTimer;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    final initialized = await _speechService.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    setState(() {
      _isInitialized = initialized;
      _hasPermission = initialized;
      if (!initialized) {
        _errorMessage = 'فشل تهيئة خدمة التعرف على الصوت';
      }
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' && _isListening) {
      _restartListening();
    }
  }

  void _onSpeechError(String error) {
    setState(() {
      _errorMessage = error;
      _isListening = false;
    });
    _pulseController.stop();
  }

  Future<void> _toggleListening() async {
    if (!_isInitialized || !_hasPermission) {
      setState(() {
        _errorMessage = 'لا يمكن استخدام الميكروفون. تحقق من الأذونات.';
      });
      return;
    }

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _errorMessage = null;
    });

    _pulseController.repeat();

    await _speechService.startListening(
      onResult: (result) {
        setState(() {
          _speechText = result.recognizedWords;
          if (result.finalResult) {
            if (_fullText.isNotEmpty) _fullText += ' ';
            _fullText += result.recognizedWords;
            _speechText = '';
            _resetSilenceTimer();
          }
        });
      },
    );
  }

  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
      if (_speechText.isNotEmpty) {
        if (_fullText.isNotEmpty) _fullText += ' ';
        _fullText += _speechText;
        _speechText = '';
      }
    });

    _pulseController.stop();
    _silenceTimer?.cancel();
    await _speechService.stopListening();
  }

  Future<void> _restartListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      await Future.delayed(const Duration(milliseconds: 100));
      await _startListening();
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 2), () {
      if (_isListening) {
        _restartListening();
      }
    });
  }

  void _handleSave() async {
    final finalText =
        _fullText + (_speechText.isNotEmpty ? ' $_speechText' : '');

    if (finalText.trim().isEmpty) {
      setState(() {
        _errorMessage = 'لا يوجد نص لحفظه';
      });
      return;
    }

    await _stopListening();

    widget.onSave({
      'text': finalText.trim(),
      'timestamp': DateTime.now().toIso8601String(),
      'duration': DateTime.now().difference(DateTime.now()).inSeconds,
    });

    await _fadeController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleCancel() async {
    await _stopListening();
    await _fadeController.reverse();
    widget.onCancel?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _speechService.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _silenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildRecorderSection(),
              _buildTextDisplay(),
              if (_errorMessage != null) _buildErrorMessage(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFB800), const Color(0xFFFFD900)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسجيل صوتي',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isListening ? 'جاري التسجيل...' : 'اضغط لبدء التحدث',
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleCancel,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRecorderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: GestureDetector(
          onTap: _toggleListening,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isListening)
                VoiceAnimations.pulseAnimation(
                  controller: _pulseController,
                  color: const Color(0xFFFFB800),
                ),
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
                  boxShadow: [
                    BoxShadow(
                      color: _isListening
                          ? const Color(0xFFFFB800).withOpacity(0.4)
                          : Colors.grey.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              if (_isListening)
                Positioned(bottom: 0, child: VoiceAnimations.waveAnimation()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextDisplay() {
    final displayText =
        _fullText + (_speechText.isNotEmpty ? ' $_speechText' : '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isListening
              ? const Color(0xFFFFB800).withOpacity(0.3)
              : Colors.grey[300]!,
          width: _isListening ? 2 : 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayText.isEmpty)
              Center(
                child: Text(
                  'النص المسجل سيظهر هنا...',
                  style: GoogleFonts.tajawal(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Text(
                displayText,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.right,
              ),
            if (_speechText.isNotEmpty && _isListening)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    VoiceAnimations.recordingIndicator(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _speechText,
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          color: const Color(0xFFFFB800),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.tajawal(fontSize: 12, color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final hasContent = _fullText.isNotEmpty || _speechText.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _handleCancel,
              child: Text(
                'إلغاء',
                style: GoogleFonts.tajawal(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: hasContent ? _handleSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    color: hasContent ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'حفظ التسجيل',
                    style: GoogleFonts.tajawal(
                      color: hasContent ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
