import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../l10n/app_localizations.dart';

class ProLoginScreen extends StatefulWidget {
  const ProLoginScreen({super.key});

  @override
  State<ProLoginScreen> createState() => _ProLoginScreenState();
}

class _ProLoginScreenState extends State<ProLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    try {
      final proAuth = context.read<ProAuthProvider>();
      await proAuth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      final profile = proAuth.currentProfile;
      if (profile == null) {
        context.go(ProRoutePaths.signup);
        return;
      }

      context.go(ProRoutePaths.homeForProfileType(profile.type));
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

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
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
                  l10n.welcome,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing8),
                Text(
                  l10n.loginSubtitle,
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.email,
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
                      return l10n.emailRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
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
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ProDesignSystem.spacing24),
                AppButton(
                  text: proAuth.isLoading ? l10n.signingIn : l10n.signIn,
                  isLoading: proAuth.isLoading,
                  onPressed: () => _submit(),
                ),
                const SizedBox(height: ProDesignSystem.spacing12),
                TextButton(
                  onPressed: () => context.go(ProRoutePaths.register),
                  child: Text(l10n.createProAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
