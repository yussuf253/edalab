import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/constants/pro_design_system.dart';

class ProWelcomeScreen extends StatelessWidget {
  const ProWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ProDesignSystem.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(
                    ProDesignSystem.radiusLarge,
                  ),
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  color: Colors.teal[700],
                  size: 30,
                ),
              ),
              const SizedBox(height: ProDesignSystem.spacing24),
              Text(
                'EdaLab Pro',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: ProDesignSystem.spacing12),
              Text(
                'Manage your business profile, inbox, jobs, and operations from a dedicated pro entrypoint.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: ProDesignSystem.spacing32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(ProRoutePaths.login),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: ProDesignSystem.spacing16,
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: ProDesignSystem.spacing12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(ProRoutePaths.register),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: ProDesignSystem.spacing16,
                    ),
                  ),
                  child: const Text('Create Account'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
