import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Forgot your password?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your registered email address and we will send password reset instructions.',
                style: TextStyle(color: AppColors.neutralGray, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (!_submitted) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.terracotta),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_emailController.text.isNotEmpty) {
                      setState(() => _submitted = true);
                    }
                  },
                  child: const Text('Send Reset Link'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardamomLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.terracotta),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'If an account exists for this email, reset instructions have been sent.',
                          style: TextStyle(color: AppColors.terracottaDark, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Return to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
