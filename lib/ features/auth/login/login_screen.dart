import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../register/register_screen.dart';
import '../../dashboard/home_screen.dart';
import 'forgot_password_dialog.dart';

/// Login Screen
/// Handles user authentication with email and password
/// 
/// Co-authored-by: Ali-0110
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
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

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ForgotPasswordDialog(),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '„—Õ»« »⁄Êœ ﬂ!',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '”Ã¯· œŒÊ·ﬂ ··„ «»⁄…',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AuthTextField(
                  controller: _emailController,
                  label: '«·»—Ìœ «·≈·ﬂ —Ê‰Ì',
                  hint: 'example@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ì—ÃÏ ≈œŒ«· «·»—Ìœ «·≈·ﬂ —Ê‰Ì';
                    }
                    if (!EmailValidator.validate(value.trim())) {
                      return '«·»—Ìœ «·≈·ﬂ —Ê‰Ì €Ì— ’«·Õ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: 'ﬂ·„… «·„—Ê—',
                  hint: '',
                  prefixIcon: Icons.lock_outlined,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ì—ÃÏ ≈œŒ«· ﬂ·„… «·„—Ê—';
                    }
                    if (value.length < 6) {
                      return 'ﬂ·„… «·„—Ê— ÌÃ» √‰  ﬂÊ‰ 6 √Õ—› ⁄·Ï «·√ﬁ·';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('‰”Ì  ﬂ·„… «·„—Ê—ø'),
                  ),
                ),
                const SizedBox(height: 24),
                AuthButton(
                  text: ' ”ÃÌ· «·œŒÊ·',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                  icon: Icons.login,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '√Ê',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '·Ì” ·œÌﬂ Õ”«»ø ',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToRegister,
                      child: const Text(
                        '≈‰‘«¡ Õ”«» ÃœÌœ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '» ”ÃÌ· «·œŒÊ·° √‰   Ê«›ﬁ ⁄·Ï ‘—Êÿ «·«” Œœ«„',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
