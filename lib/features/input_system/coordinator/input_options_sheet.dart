import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../text/text_input_dialog.dart';
import '../voice/voice_recorder_dialog.dart';
import '../camera/camera_capture_screen.dart';
import '../camera/image_picker_handler.dart';
import '../../../core/theme/app_theme.dart';

class InputOptionsSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataReceived;

  const InputOptionsSheet({Key? key, required this.onDataReceived})
    : super(key: key);

  @override
  State<InputOptionsSheet> createState() => _InputOptionsSheetState();
}

class _InputOptionsSheetState extends State<InputOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _itemAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.15,
            0.5 + index * 0.15,
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTextInput() {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TextInputDialog(
        onSave: (inputData) {
          widget.onDataReceived({'type': 'text', 'data': inputData.toJson()});
        },
      ),
    );
  }

  void _handleVoiceInput() {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceRecorderDialog(
        onSave: (voiceData) {
          widget.onDataReceived({'type': 'voice', 'data': voiceData});
        },
      ),
    );
  }

  void _handleCameraInput() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraCaptureScreen(
          onImageCaptured: (imagePath) {
            widget.onDataReceived({'type': 'camera', 'imagePath': imagePath});
          },
        ),
      ),
    );
  }

  void _handleGalleryInput() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'اختر طريقة الإدخال',
                style: GoogleFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اختر الطريقة المناسبة لإضافة ملاحظتك',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // Input Options
              _buildAnimatedOption(
                index: 0,
                icon: Icons.keyboard_rounded,
                title: 'كتابة نص',
                subtitle: 'اكتب ملاحظتك يدوياً',
                color: AppTheme.primaryColor,
                gradientColors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
                onTap: _handleTextInput,
              ),

              _buildAnimatedOption(
                index: 1,
                icon: Icons.mic_rounded,
                title: 'تسجيل صوتي',
                subtitle: 'سجل ملاحظتك بصوتك',
                color: const Color(0xFFFFB800),
                gradientColors: [
                  const Color(0xFFFFB800),
                  const Color(0xFFFFD900),
                ],
                onTap: _handleVoiceInput,
              ),

              _buildAnimatedOption(
                index: 2,
                icon: Icons.camera_alt_rounded,
                title: 'التقاط صورة',
                subtitle: 'صور ملاحظتك وسنحولها لنص',
                color: Colors.blue,
                gradientColors: [Colors.blue, Colors.lightBlueAccent],
                onTap: _handleCameraInput,
              ),

              _buildAnimatedOption(
                index: 3,
                icon: Icons.photo_library_rounded,
                title: 'اختيار صورة',
                subtitle: 'اختر صورة من المعرض',
                color: Colors.purple,
                gradientColors: [Colors.purple, Colors.purpleAccent],
                onTap: _handleGalleryInput,
              ),

              const SizedBox(height: 20),

              // Tips Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'نصائح',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTip('• استخدم الكتابة للملاحظات الطويلة'),
                    _buildTip('• التسجيل الصوتي أسرع للأفكار السريعة'),
                    _buildTip('• الكاميرا مفيدة للوثائق والإيصالات'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _itemAnimations[index].value,
          child: Opacity(
            opacity: _itemAnimations[index].value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors
                            .map((c) => c.withOpacity(0.05))
                            .toList(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.tajawal(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.tajawal(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }
}
