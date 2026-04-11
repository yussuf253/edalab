import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/constants/pro_design_system.dart';

class ProSignupScreen extends StatefulWidget {
  const ProSignupScreen({super.key});

  @override
  State<ProSignupScreen> createState() => _ProSignupScreenState();
}

class _ProSignupScreenState extends State<ProSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();

  ProProfileType? _selectedProfileType;
  final Set<ProModule> _selectedModules = {};
  String? _submissionMessage;

  void _onProfileSelected(ProProfileType type) {
    setState(() {
      _selectedProfileType = type;
      _selectedModules.clear();
      _selectedModules.addAll(
        ProModuleHelper.getDefaultModulesForProfile(type),
      );
      _submissionMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();

    if (_selectedProfileType == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a profile type')),
      );
      return;
    }
    if (_selectedModules.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select at least one module')),
      );
      return;
    }
    final proAuth = context.read<ProAuthProvider>();
    setState(() {
      _submissionMessage = null;
    });

    try {
      await proAuth.completeProfile(
        type: _selectedProfileType!,
        selectedModules: _selectedModules.toList(),
        businessName: _businessNameController.text.trim(),
      );

      if (!mounted) return;

      if (proAuth.currentProfile == null) {
        setState(() {
          _submissionMessage =
              'We could not finish your pro setup. Please try again.';
        });
        return;
      }

      await AppPreferences.setHasSeenProOnboarding(true);
      if (!mounted) return;

      context.go(
        ProRoutePaths.homeForProfileType(proAuth.currentProfile!.type),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submissionMessage =
            'Sign up failed. ${error.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join as a Professional'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<ProAuthProvider>(
          builder: (context, proAuth, _) {
            if (proAuth.currentAccount == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(ProDesignSystem.spacing24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          ProDesignSystem.spacing20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            ProDesignSystem.radiusLarge,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 40,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing12),
                      const Text(
                        'Create or sign in to a pro account first before setting up your workspace.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: ProDesignSystem.spacing16),
                      AppButton(
                        text: 'Go to Pro Sign In',
                        onPressed: () => context.go(ProRoutePaths.login),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(ProDesignSystem.spacing24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (proAuth.currentAccount != null) ...[
                      ModernInfoBox(
                        message:
                            'Signed in as ${proAuth.currentAccount!.email}. Now choose the pro profile and modules you want to operate.',
                        icon: Icons.verified_user_outlined,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        textColor: Colors.blue[700]!,
                        borderColor: Colors.blue[300]!,
                      ),
                      const SizedBox(height: ProDesignSystem.spacing20),
                    ],
                    if (proAuth.isLoading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: ProDesignSystem.spacing16),
                      Text(
                        'Creating your pro workspace...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ProDesignSystem.spacing20),
                    ],
                    if (_submissionMessage != null) ...[
                      ModernInfoBox(
                        message: _submissionMessage!,
                        icon: Icons.error_outline,
                        backgroundColor: const Color(0xFFFFF5F5),
                        textColor: const Color(0xFFDC2626),
                        borderColor: const Color(0xFFF87171),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing20),
                    ],
                    Text(
                      'Choose Your Profile Type',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: ProDesignSystem.spacing16,
                      mainAxisSpacing: ProDesignSystem.spacing16,
                      childAspectRatio: 0.9,
                      children: ProProfileType.values.map((type) {
                        final isSelected = _selectedProfileType == type;
                        return InkWell(
                          onTap: () => _onProfileSelected(type),
                          borderRadius: BorderRadius.circular(
                            ProDesignSystem.radiusLarge,
                          ),
                          child: ModernCard(
                            borderRadius: ProDesignSystem.radiusLarge,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                      .withValues(alpha: 0.5)
                                : Colors.white,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  ProModuleHelper.getProfileIcon(type),
                                  size: 40,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(
                                  height: ProDesignSystem.spacing12,
                                ),
                                Text(
                                  ProModuleHelper.getProfileName(type),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(
                                  height: ProDesignSystem.spacing8,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ProDesignSystem.spacing12,
                                  ),
                                  child: Text(
                                    ProModuleHelper.getProfileDescription(type),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing32),
                    if (_selectedProfileType != null) ...[
                      ModernInfoBox(
                        message: ProModuleHelper.getProfileDescription(
                          _selectedProfileType!,
                        ),
                        icon: ProModuleHelper.getProfileIcon(
                          _selectedProfileType!,
                        ),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        textColor: Colors.blue[700]!,
                        borderColor: Colors.blue[300]!,
                      ),
                      const SizedBox(height: ProDesignSystem.spacing24),
                      Text(
                        'Select Active Modules',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing16),
                      ...ProModuleHelper.getModulesForProfile(
                        _selectedProfileType!,
                      ).map((module) {
                        return CheckboxListTile(
                          title: Text(ProModuleHelper.getModuleName(module)),
                          subtitle: Text(
                            ProModuleHelper.getModuleDescription(module),
                          ),
                          secondary: Icon(
                            ProModuleHelper.getModuleIcon(module),
                          ),
                          value: _selectedModules.contains(module),
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (bool? value) {
                            setState(() {
                              _submissionMessage = null;
                              if (value == true) {
                                _selectedModules.add(module);
                              } else {
                                _selectedModules.remove(module);
                              }
                            });
                          },
                        );
                      }),
                      if (_selectedProfileType == ProProfileType.provider) ...[
                        const SizedBox(height: ProDesignSystem.spacing12),
                        ModernInfoBox(
                          message:
                              'After sign-up, create your own service listing from Availability, then configure services offered, activity zone, booking modes, and hours in Schedule.',
                          icon: Icons.tune_rounded,
                          backgroundColor: Colors.blue.withValues(alpha: 0.08),
                          textColor: Colors.blue[700]!,
                          borderColor: Colors.blue[200]!,
                        ),
                      ],
                      const SizedBox(height: ProDesignSystem.spacing24),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: 'Business / Display Name',
                          hintText:
                              'Enter the business, provider, clinic, fleet, or profile name',
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
                            return 'Business name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: ProDesignSystem.spacing32),
                      AppButton(
                        text: 'Complete Sign Up',
                        isLoading: proAuth.isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }
}
