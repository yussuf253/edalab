import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/constants/pro_design_system.dart';

class ProRegisterScreen extends StatefulWidget {
  const ProRegisterScreen({super.key});

  @override
  State<ProRegisterScreen> createState() => _ProRegisterScreenState();
}

class _ProRegisterScreenState extends State<ProRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    try {
      final proAuth = context.read<ProAuthProvider>();
      await proAuth.registerAccount(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go(ProRoutePaths.signup);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final proAuth = context.watch<ProAuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Pro Account'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ProDesignSystem.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set up your dedicated pro sign-in',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing8),
                Text(
                  'This account is separate from the customer app and is used only for EdaLab Pro access.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: ProDesignSystem.spacing24),
                if (_errorMessage != null) ...[
                  ModernInfoBox(
                    message: _errorMessage!,
                    icon: Icons.error_outline,
                    backgroundColor: const Color(0xFFFFF5F5),
                    textColor: const Color(0xFFDC2626),
                    borderColor: const Color(0xFFF87171),
                  ),
                  const SizedBox(height: ProDesignSystem.spacing20),
                ],
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusSmall,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ProDesignSystem.spacing12,
                      vertical: ProDesignSystem.spacing12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusSmall,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ProDesignSystem.spacing12,
                      vertical: ProDesignSystem.spacing12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusSmall,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ProDesignSystem.spacing12,
                      vertical: ProDesignSystem.spacing12,
                    ),
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusSmall,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ProDesignSystem.spacing12,
                      vertical: ProDesignSystem.spacing12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusSmall,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ProDesignSystem.spacing12,
                      vertical: ProDesignSystem.spacing12,
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ProDesignSystem.spacing24),
                AppButton(
                  text: proAuth.isLoading ? 'Creating account...' : 'Continue',
                  isLoading: proAuth.isLoading,
                  onPressed: () => _submit(),
                ),
                const SizedBox(height: ProDesignSystem.spacing12),
                TextButton(
                  onPressed: () => context.go(ProRoutePaths.login),
                  child: const Text('Already have a pro account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
