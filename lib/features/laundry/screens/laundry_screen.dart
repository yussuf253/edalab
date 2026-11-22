import 'package:flutter/material.dart';

import '../../../core/widgets/module_screen_app_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/config/zone_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  List<LaundryService> _services = const [];
  bool _isLoading = true;

  IconData _getIcon(String _) {
    return LucideIcons.washingMachine;
  }

  Color _getColor(String _) {
    return AppColors.laundry;
  }

  String _profileDisplayName(LaundryService service) {
    final profileName = service.profileName.trim();
    if (profileName.isNotEmpty) return profileName;
    return service.name;
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final response = await ApiClient.get(
        ZoneScope.appendZone('/catalog/laundry-services'),
      );
      final items = (response as List)
          .map(
            (item) =>
                LaundryService.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _services = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final services = _services;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleScreenAppBar(title: l10n.t('laundry.title')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.laundryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.laundry.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('laundry.hero_title'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.t('laundry.hero_subtitle'),
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final allowed = await requireLoggedIn(
                                context,
                                message: l10n.t('laundry.login_required'),
                              );
                              if (!context.mounted || !allowed) return;
                              context.push('/laundry/order');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.laundry,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.t('laundry.order_now'),
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.washingMachine,
                        color: AppColors.laundry,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Services
              Text(l10n.t('laundry.our_services'), style: AppTextStyles.h4),
              const SizedBox(height: 14),
              if (_isLoading)
                const InlineSectionListShimmer(itemCount: 4)
              else
                ...services.map((s) {
                  final hasServiceImage = s.iconUrl
                      .trim()
                      .toLowerCase()
                      .startsWith('http');
                  return GestureDetector(
                    onTap: () => context.push(
                      '/laundry/order?serviceId=${Uri.encodeComponent(s.id)}&locked=1',
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _getColor(s.id).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: hasServiceImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      s.iconUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        _getIcon(s.id),
                                        color: _getColor(s.id),
                                        size: 28,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _getIcon(s.id),
                                    color: _getColor(s.id),
                                    size: 28,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profileDisplayName(s),
                                  style: AppTextStyles.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (s.profileName.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    s.name,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  l10n.t(
                                    'laundry.starting_from',
                                    params: {
                                      'price': '${s.price.toInt()}',
                                      'unit': s.unit,
                                    },
                                  ),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: AppColors.mediumGrey,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              // How it works
              Text(l10n.t('laundry.how_it_works'), style: AppTextStyles.h4),
              const SizedBox(height: 14),
              ...[
                (
                  '1',
                  l10n.t('laundry.step1_title'),
                  l10n.t('laundry.step1_subtitle'),
                  LucideIcons.calendar,
                ),
                (
                  '2',
                  l10n.t('laundry.step2_title'),
                  l10n.t('laundry.step2_subtitle'),
                  LucideIcons.car,
                ),
                (
                  '3',
                  l10n.t('laundry.step3_title'),
                  l10n.t('laundry.step3_subtitle'),
                  LucideIcons.washingMachine,
                ),
                (
                  '4',
                  l10n.t('laundry.step4_title'),
                  l10n.t('laundry.step4_subtitle'),
                  LucideIcons.home,
                ),
              ].map(
                (s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            s.$1,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$2, style: AppTextStyles.labelMedium),
                            Text(s.$3, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Icon(s.$4, size: 22, color: AppColors.mediumGrey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
