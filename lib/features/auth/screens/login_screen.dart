import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        final errorMessage =
            authProvider.errorMessage ?? context.l10n.t('auth.login_failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Logo
                FadeInDown(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Title
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    l10n.t('auth.login_title'),
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 28,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    l10n.t('auth.login_subtitle'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Email Field
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('auth.email'),
                        style: AppTextStyles.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: l10n.t('auth.email_hint'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.t('auth.email_required');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Password Field
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('auth.password'),
                        style: AppTextStyles.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: l10n.t('auth.password_hint'),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.t('auth.password_required');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Forgot Password
                FadeInDown(
                  delay: const Duration(milliseconds: 450),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        l10n.t('auth.forgot_password'),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Sign In Button
                FadeInDown(
                  delay: const Duration(milliseconds: 500),
                  child: AppButton(
                    text: l10n.t('auth.sign_in'),
                    isLoading: isLoading,
                    onPressed: _handleLogin,
                  ),
                ),
                const SizedBox(height: 26),
                // Register link
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.t('auth.no_account'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text(
                          l10n.t('auth.sign_up'),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
