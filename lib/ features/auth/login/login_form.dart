import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

/// Login Form Widget
/// Reusable login form component with validation
/// 
/// Co-authored-by: Ali-0110
class LoginForm extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onForgotPassword;
  final bool showForgotPassword;
  final String? initialEmail;

  const LoginForm({
    super.key,
    this.onLoginSuccess,
    this.onForgotPassword,
    this.showForgotPassword = true,
    this.initialEmail,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    _loadRememberMe();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    // TODO: Load from SharedPreferences
    // For now, just a placeholder
  }

  Future<void> _saveRememberMe() async {
    if (_rememberMe) {
      // TODO: Save to SharedPreferences
      // For now, just a placeholder
    }
  }

  Future<void> _handleLogin() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Unfocus text fields
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    setState(() => _isLoading = true);

    try {
      await AuthService().signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save remember me preference
      await _saveRememberMe();

      if (mounted) {
        // Call success callback
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Set appropriate error based on error message
          final errorMsg = e.toString();
          if (errorMsg.contains('البريد') || errorMsg.contains('email')) {
            _emailError = errorMsg;
          } else if (errorMsg.contains('كلمة المرور') || errorMsg.contains('password')) {
            _passwordError = errorMsg;
          } else {
            // Show in snackbar for general errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleForgotPassword() {
    widget.onForgotPassword?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          AuthTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
            onFieldSubmitted: (_) {
              _passwordFocusNode.requestFocus();
            },
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

          const SizedBox(height: 16),

          // Password Field
          AuthTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'كلمة المرور',
            hint: '••••••••',
            prefixIcon: Icons.lock_outlined,
            isPassword: true,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
            onFieldSubmitted: (_) => _handleLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Remember Me & Forgot Password Row
          Row(
            children: [
              // Remember Me Checkbox
              Checkbox(
                value: _rememberMe,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                activeColor: AppTheme.primaryColor,
              ),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                child: Text(
                  'تذكرني',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const Spacer(),

              // Forgot Password Button
              if (widget.showForgotPassword)
                TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  child: const Text('نسيت كلمة المرور؟'),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Login Button
          AuthButton(
            text: 'تسجيل الدخول',
            onPressed: _handleLogin,
            isLoading: _isLoading,
            icon: Icons.login,
          ),
        ],
      ),
    );
  }
}

/// Compact Login Form (for dialogs or small spaces)
class CompactLoginForm extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const CompactLoginForm({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<CompactLoginForm> createState() => _CompactLoginFormState();
}

class _CompactLoginFormState extends State<CompactLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'مطلوب';
              }
              if (!EmailValidator.validate(value.trim())) {
                return 'غير صالح';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordController,
            label: 'كلمة المرور',
            prefixIcon: Icons.lock_outlined,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'مطلوب';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthButton(
            text: 'دخول',
            onPressed: _handleLogin,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
