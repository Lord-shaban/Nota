import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/input_models.dart';
import 'text_processor.dart';

class TextInputDialog extends StatefulWidget {
  final Function(InputData) onSave;
  final VoidCallback? onCancel;

  const TextInputDialog({Key? key, required this.onSave, this.onCancel})
    : super(key: key);

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isProcessing = false;
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Auto focus on text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Validation function
  String? _validateInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال نص للملاحظة';
    }
    if (value.trim().length < 3) {
      return 'النص قصير جداً (3 أحرف على الأقل)';
    }
    if (value.trim().length > 5000) {
      return 'النص طويل جداً (الحد الأقصى 5000 حرف)';
    }
    return null;
  }

  // Handle save action
  Future<void> _handleSave() async {
    // Clear any previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      // Show error animation
      _shakeAnimation();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Process the text
      final processedText = await TextProcessor.processText(
        _noteController.text.trim(),
      );

      // Create input data
      final inputData = InputData(
        type: InputType.text,
        content: processedText.content,
        title: processedText.title,
        rawInput: _noteController.text.trim(),
        timestamp: DateTime.now(),
        metadata: {
          'wordCount': processedText.wordCount,
          'language': processedText.detectedLanguage,
        },
      );

      // Animate close
      await _animationController.reverse();

      // Call the save callback
      widget.onSave(inputData);

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'حدث خطأ في معالجة النص: ${e.toString()}';
      });
    }
  }

  // Shake animation for errors
  void _shakeAnimation() {
    _animationController.forward(from: 0.0);
    HapticFeedback.lightImpact();
  }

  // Handle cancel action
  void _handleCancel() {
    if (_noteController.text.isNotEmpty) {
      _showDiscardDialog();
    } else {
      _closeDialog();
    }
  }

  void _closeDialog() {
    _animationController.reverse().then((_) {
      if (widget.onCancel != null) {
        widget.onCancel!();
      }
      Navigator.of(context).pop();
    });
  }

  // Show discard confirmation dialog
  void _showDiscardDialog() {
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
                'تجاهل التغييرات؟',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            'لديك نص غير محفوظ. هل تريد تجاهله والخروج؟',
            style: GoogleFonts.tajawal(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'متابعة الكتابة',
                style: GoogleFonts.tajawal(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _closeDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'تجاهل',
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: _buildTitle(),
              content: _buildContent(),
              actions: _buildActions(),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أضف ملاحظة جديدة',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              Text(
                'اكتب ملاحظتك ودعنا ننظمها لك',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _handleCancel,
          icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _buildTextField(),
              const SizedBox(height: 16),
              _buildInfoCard(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Stack(
      children: [
        TextFormField(
          controller: _noteController,
          focusNode: _focusNode,
          maxLines: 8,
          maxLength: 5000,
          enabled: !_isProcessing,
          style: GoogleFonts.tajawal(fontSize: 14, height: 1.5),
          decoration: InputDecoration(
            hintText:
                'اكتب ملاحظتك هنا...\n\n'
                'يمكنك كتابة:\n'
                '• مهام: "يجب أن أذهب للسوق غداً"\n'
                '• مواعيد: "موعد الطبيب يوم الخميس الساعة 3"\n'
                '• مصروفات: "دفعت 50 ريال للبقالة"\n'
                '• أي شيء آخر تريد تذكره',
            hintStyle: GoogleFonts.tajawal(
              color: Colors.grey[400],
              fontSize: 13,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          validator: _validateInput,
          onChanged: (value) {
            // Clear error message when user starts typing
            if (_errorMessage != null) {
              setState(() {
                _errorMessage = null;
              });
            }
          },
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _noteController.text.length > 4500
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_noteController.text.length}/5000',
              style: GoogleFonts.tajawal(
                fontSize: 11,
                color: _noteController.text.length > 4500
                    ? Colors.red
                    : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD900).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD900).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFFFB800),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'سيقوم الذكاء الاصطناعي بتحليل النص وتنظيمه تلقائياً',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
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
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isProcessing ? null : _handleCancel,
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(
                color: _isProcessing ? Colors.grey[400] : Colors.grey[600],
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: _isProcessing ? 0 : 2,
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'جاري المعالجة...',
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'حفظ الملاحظة',
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
