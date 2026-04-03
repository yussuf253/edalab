import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';

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
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    final userId = auth.user?.id;

    if (userId == null || userId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please log in from the user app first')),
      );
      return;
    }

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
      await proAuth.signUpAsPro(
        userId: userId,
        type: _selectedProfileType!,
        selectedModules: _selectedModules.toList(),
        businessName: _businessNameController.text.trim(),
      );

      await proAuth.fetchProfile(userId);

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

      context.go(ProRoutePaths.homeForProfileType(proAuth.currentProfile!.type));
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (proAuth.isLoading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Creating your pro workspace...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_submissionMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _submissionMessage!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'Choose Your Profile Type',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: ProProfileType.values.map((type) {
                        final isSelected = _selectedProfileType == type;
                        return InkWell(
                          onTap: () => _onProfileSelected(type),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline
                                          .withValues(alpha: 0.5),
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.5)
                                  : null,
                            ),
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
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
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
                    const SizedBox(height: 32),
                    if (_selectedProfileType != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              ProModuleHelper.getProfileIcon(
                                _selectedProfileType!,
                              ),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ProModuleHelper.getProfileDescription(
                                  _selectedProfileType!,
                                ),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Select Active Modules',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: 'Business / Display Name',
                          hintText:
                              'Enter the business, provider, clinic, fleet, or profile name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Business name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
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
