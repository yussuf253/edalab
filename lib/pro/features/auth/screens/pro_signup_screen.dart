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
import '../../../l10n/app_localizations.dart';

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

    final l10n = AppLocalizations.of(context)!;
    if (_selectedProfileType == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.chooseProfileType)));
      return;
    }
    if (_selectedModules.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.selectActiveModules)));
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
          _submissionMessage = l10n.signupFailed('');
        });
        return;
      }

      await AppPreferences.setHasSeenProOnboarding(true);
      if (!mounted) return;

      if (_selectedProfileType == ProProfileType.doctor) {
        context.go(ProRoutePaths.doctorSetup);
      } else {
        context.go(
          ProRoutePaths.homeForProfileType(proAuth.currentProfile!.type),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submissionMessage = l10n.signupFailed(
          error.toString().replaceFirst('Exception: ', ''),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signupTitle), centerTitle: true),
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
                      Text(l10n.signupInfo, textAlign: TextAlign.center),
                      const SizedBox(height: ProDesignSystem.spacing16),
                      AppButton(
                        text: l10n.goToProSignIn,
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
                        message: l10n.signedInAsMessage(
                          proAuth.currentAccount!.email,
                        ),
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
                        l10n.creatingWorkspace,
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
                      l10n.chooseProfileType,
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
                                  isSelected && type == ProProfileType.doctor
                                      ? l10n.profileTypeDoctor
                                      : isSelected &&
                                            type == ProProfileType.provider
                                      ? l10n.profileTypeProvider
                                      : isSelected &&
                                            type == ProProfileType.shop
                                      ? l10n.profileTypeShop
                                      : isSelected &&
                                            type == ProProfileType.delivery
                                      ? l10n.profileTypeDelivery
                                      : isSelected &&
                                            type == ProProfileType.rider
                                      ? l10n.profileTypeRide
                                      : ProModuleHelper.getProfileName(type),
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
                        l10n.selectActiveModules,
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
                          message: l10n.providerInfo,
                          icon: Icons.tune_rounded,
                          backgroundColor: Colors.blue.withValues(alpha: 0.08),
                          textColor: Colors.blue[700]!,
                          borderColor: Colors.blue[200]!,
                        ),
                      ],
                      if (_selectedProfileType == ProProfileType.doctor) ...[
                        const SizedBox(height: ProDesignSystem.spacing12),
                        ModernInfoBox(
                          message: l10n.doctorInfo,
                          icon: Icons.medical_services_outlined,
                          backgroundColor: Colors.teal.withValues(alpha: 0.08),
                          textColor: Colors.teal[700]!,
                          borderColor: Colors.teal[200]!,
                        ),
                      ],
                      const SizedBox(height: ProDesignSystem.spacing24),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: l10n.businessNameLabel,
                          hintText: l10n.businessNameHint,
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
                            return l10n.businessNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: ProDesignSystem.spacing32),
                      AppButton(
                        text: l10n.completeSignUp,
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
