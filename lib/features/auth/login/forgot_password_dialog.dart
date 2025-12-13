import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

/// Forgot Password Dialog
/// Allows users to reset their password via email
/// 
/// Co-authored-by: Ali-0110
/// Co-authored-by: abdelrahman-hesham11
/// Co-authored-by: Mahmoud13MA
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      await AuthService().sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      debugPrint('✅ Password reset email sent to: ${_emailController.text.trim()}');

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: _emailSent ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Close Button
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),

          const SizedBox(height: 8),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'نسيت كلمة المرور؟',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            'أدخل بريدك الإلكتروني وسنرسل لك رابط استعادة كلمة المرور',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Email Field
          AuthTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleResetPassword(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال البريد الإلكتروني';
              }
              if (!EmailValidator.validate(value.trim())) {
                return 'البريد الإلكتروني غير صالح';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Reset Button
          AuthButton(
            text: 'إرسال رابط الاستعادة',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
            icon: Icons.send,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: AppTheme.successColor,
          ),
        ),

        const SizedBox(height: 24),

        // Success Title
        Text(
          'تم إرسال الرابط!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.successColor,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Success Message
        Text(
          'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Email Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _emailController.text.trim(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Info Message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.infoColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.infoColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تحقق من صندوق البريد الوارد أو البريد المزعج',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.infoColor,
                      ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Close Button
        AuthButton(
          text: 'إغلاق',
          onPressed: () => Navigator.pop(context),
          isOutlined: true,
        ),
      ],
    );
  }
}
