import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/message_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class HomeServiceAppointmentDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? initialOrder;

  const HomeServiceAppointmentDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<HomeServiceAppointmentDetailScreen> createState() =>
      _HomeServiceAppointmentDetailScreenState();
}

class _HomeServiceAppointmentDetailScreenState
    extends State<HomeServiceAppointmentDetailScreen> {
  Map<String, dynamic>? _order;
  HomeServiceProviderModel? _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;

    try {
      Map<String, dynamic>? order = _order;
      if (order == null || order.isEmpty) {
        try {
          final response = await ApiClient.get(
            '/orders/detail/${widget.orderId}',
            forceRefresh: true,
          );
          if (response is Map) {
            final candidate = Map<String, dynamic>.from(response);
            if (candidate['id']?.toString() == widget.orderId) {
              order = candidate;
            }
          }
        } catch (_) {}
      }

      if ((order == null || order.isEmpty) &&
          userId != null &&
          userId.isNotEmpty) {
        try {
          final response = await ApiClient.get(
            '/orders/$userId',
            forceRefresh: true,
          );
          final orders = response is List ? response : const [];
          for (final entry in orders) {
            final candidate = Map<String, dynamic>.from(entry as Map);
            if (candidate['id']?.toString() == widget.orderId) {
              order = candidate;
              break;
            }
          }
        } catch (_) {}
      }

      HomeServiceProviderModel? provider;
      final providerId = _extractProviderId(order);
      if (providerId != null && providerId.isNotEmpty) {
        try {
          final providerResponse = await ApiClient.get(
            '/catalog/home-service-providers/$providerId',
            forceRefresh: true,
          );
          provider = HomeServiceProviderModel.fromApi(
            Map<String, dynamic>.from(providerResponse as Map),
          );
        } catch (_) {
          provider = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _order = order;
        _provider = provider;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String? _extractProviderId(Map<String, dynamic>? order) {
    if (order == null) return null;
    final items = (order['items'] as List? ?? const []);
    if (items.isEmpty) return null;
    final firstItem = Map<String, dynamic>.from(items.first as Map);
    final metadata = firstItem['metadata'];
    if (metadata is Map) {
      final assignedProviderId = metadata['assignedProviderId']
          ?.toString()
          .trim();
      if (assignedProviderId != null &&
          assignedProviderId.isNotEmpty &&
          assignedProviderId != 'house-help-zone') {
        return assignedProviderId;
      }
      final value = metadata['providerId']?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'house-help-zone') {
        return value;
      }
    }
    final externalRefId = firstItem['externalRefId']?.toString().trim();
    if (externalRefId != null &&
        externalRefId.isNotEmpty &&
        externalRefId != 'house-help-zone') {
      return externalRefId;
    }
    return null;
  }

  String _metadataValue(String key) {
    final metadata = _metadataMap();
    return metadata[key]?.toString() ?? '';
  }

  Map<String, dynamic> _metadataMap() {
    final order = _order;
    if (order == null) return const <String, dynamic>{};
    final items = (order['items'] as List? ?? const []);
    if (items.isEmpty) return const <String, dynamic>{};
    final firstItem = Map<String, dynamic>.from(items.first as Map);
    final metadata = firstItem['metadata'];
    if (metadata is Map) {
      return Map<String, dynamic>.from(metadata);
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _bookingFormatMap() {
    final metadata = _metadataMap();
    final format = metadata['bookingFormat'];
    if (format is Map) {
      return Map<String, dynamic>.from(format);
    }
    return const <String, dynamic>{};
  }

  bool _isHouseHelpOrder(Map<String, dynamic>? order) {
    final moduleType = order?['moduleType']?.toString().toUpperCase() ?? '';
    if (moduleType == 'HOUSE_HELP') return true;
    if (_bookingFormatMap().isNotEmpty) return true;
    final dispatchMode = _metadataValue('dispatchMode').toUpperCase();
    return dispatchMode == 'ZONE_POOL';
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y';
  }

  String _localizedHouseHelpPlanLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized.contains('daily')) {
      return l10n.t('home_service_booking.house_help_plan_daily');
    }
    if (normalized.contains('weekly')) {
      return l10n.t('home_service_booking.house_help_plan_weekly');
    }
    if (normalized.contains('one') ||
        normalized.contains('single') ||
        normalized.contains('once')) {
      return l10n.t('home_service_booking.house_help_plan_one_time');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  String _localizedHouseHelpShiftLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized.contains('8')) {
      return l10n.t('home_service_booking.house_help_shift_8h');
    }
    if (normalized.contains('4')) {
      return l10n.t('home_service_booking.house_help_shift_4h');
    }
    if (normalized.contains('2')) {
      return l10n.t('home_service_booking.house_help_shift_2h');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  String _localizedHouseHelpHomeSizeLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized == 'f2') {
      return l10n.t('home_service_booking.house_help_home_size_small');
    }
    if (normalized == 'f3') {
      return l10n.t('home_service_booking.house_help_home_size_medium');
    }
    if (normalized == 'f4') {
      return l10n.t('home_service_booking.house_help_home_size_large');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  String _localizedHouseHelpArrivalLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized.contains('30')) {
      return l10n.t('home_service_booking.house_help_arrival_30');
    }
    if (normalized.contains('scheduled')) {
      return l10n.t('home_service_booking.house_help_arrival_scheduled');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  String _formatDateTimeValue(String value) {
    if (value.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _twoDigits(int input) => input.toString().padLeft(2, '0');

  Future<void> _callProvider() async {
    final phone = _provider?.contactPhone?.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = _order;
    final provider = _provider;
    final metadata = _metadataMap();
    final bookingFormat = _bookingFormatMap();
    final isHouseHelpOrder = _isHouseHelpOrder(order);
    final serviceName = _metadataValue('serviceName').isNotEmpty
        ? _metadataValue('serviceName')
        : (((order?['items'] as List?)?.isNotEmpty ?? false)
              ? Map<String, dynamic>.from(
                      (order!['items'] as List).first as Map,
                    )['name']?.toString() ??
                    l10n.t('module.home_services')
              : l10n.t('module.home_services'));
    final bookingMode = _metadataValue('bookingMode');
    final scheduledDate = _metadataValue('scheduledDate');
    final timeSlot = _metadataValue('timeSlot');
    final address = _metadataValue('address');
    final bookingType = bookingFormat['type']?.toString().trim() ?? '';
    final shiftDuration = bookingFormat['shift']?.toString().trim() ?? '';
    final homeSize = bookingFormat['homeSize']?.toString().trim() ?? '';
    final arrivalTargetRaw =
        bookingFormat['arrivalTarget']?.toString().trim() ??
        _metadataValue('dispatchWindow');
    final bringSupplies = _boolValue(bookingFormat['bringSupplies']);
    final dispatchMode = metadata['dispatchMode']?.toString().trim() ?? '';
    final assignedProviderId =
        metadata['assignedProviderId']?.toString().trim().isNotEmpty == true
        ? metadata['assignedProviderId']!.toString().trim()
        : (metadata['providerId']?.toString().trim() ?? '');
    final assignedAt = _formatDateTimeValue(
      metadata['assignedAt']?.toString().trim() ?? '',
    );
    final providerPoolCount =
        (metadata['providerPoolIds'] as List<dynamic>?)?.length ?? 0;
    final showDispatchDetails =
        isHouseHelpOrder &&
        (dispatchMode.isNotEmpty ||
            assignedProviderId.isNotEmpty ||
            providerPoolCount > 0);
    final orderModuleType =
        order?['moduleType']?.toString().toUpperCase() == 'HOUSE_HELP'
        ? 'HOUSE_HELP'
        : 'HOME_SERVICES';

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/home-services');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('home_service_detail.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home-services');
              }
            },
          ),
        ),
        body: _isLoading
            ? const DetailContentShimmer(
                accentColor: AppColors.homeServices,
                showHero: false,
              )
            : order == null
            ? Center(
                child: Text(
                  l10n.t('home_service_detail.unavailable'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.homeServices,
                            AppColors.secondaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              provider?.categoryIcon ??
                                  Icons.home_repair_service_rounded,
                              color: AppColors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  serviceName,
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider?.name ??
                                      order['moduleName']?.toString() ??
                                      l10n.t(
                                        'home_service_detail.provider_name',
                                      ),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    order['status']?.toString() ?? 'PENDING',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailCard(
                      title: l10n.t('home_service_detail.summary'),
                      children: [
                        _DetailRow(
                          l10n.t('home_service_detail.booking_id'),
                          '#${order['id']}',
                        ),
                        _DetailRow(
                          l10n.t('home_service_detail.service'),
                          l10n.homeServiceDynamicLabel(serviceName),
                        ),
                        _DetailRow(
                          l10n.t('home_service_detail.price'),
                          '\$${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                        ),
                        if (bookingMode.isNotEmpty)
                          _DetailRow(
                            l10n.t('home_service_detail.mode'),
                            bookingMode,
                          ),
                        if (scheduledDate.isNotEmpty)
                          _DetailRow(
                            l10n.t('home_service_detail.date'),
                            scheduledDate,
                          ),
                        if (timeSlot.isNotEmpty)
                          _DetailRow(
                            l10n.t('home_service_detail.time'),
                            timeSlot,
                          ),
                        if (address.isNotEmpty)
                          _DetailRow(
                            l10n.t('home_service_detail.address'),
                            address,
                          ),
                      ],
                    ),
                    if (isHouseHelpOrder) ...[
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: l10n.t(
                          'home_service_booking.house_help_format_title',
                        ),
                        children: [
                          if (bookingType.isNotEmpty)
                            _DetailRow(
                              l10n.t(
                                'home_service_booking.house_help_booking_type',
                              ),
                              _localizedHouseHelpPlanLabel(bookingType, l10n),
                            ),
                          if (shiftDuration.isNotEmpty)
                            _DetailRow(
                              l10n.t(
                                'home_service_booking.house_help_shift_duration',
                              ),
                              _localizedHouseHelpShiftLabel(
                                shiftDuration,
                                l10n,
                              ),
                            ),
                          if (homeSize.isNotEmpty)
                            _DetailRow(
                              l10n.t(
                                'home_service_booking.house_help_home_size',
                              ),
                              _localizedHouseHelpHomeSizeLabel(homeSize, l10n),
                            ),
                          if (arrivalTargetRaw.isNotEmpty)
                            _DetailRow(
                              l10n.t(
                                'home_service_booking.house_help_arrival_target',
                              ),
                              _localizedHouseHelpArrivalLabel(
                                arrivalTargetRaw,
                                l10n,
                              ),
                            ),
                          _DetailRow(
                            l10n.t(
                              'home_service_booking.house_help_summary_supplies',
                            ),
                            bringSupplies
                                ? l10n.t(
                                    'home_service_booking.house_help_summary_supplies_provider',
                                  )
                                : l10n.t(
                                    'home_service_booking.house_help_summary_supplies_customer',
                                  ),
                          ),
                        ],
                      ),
                    ],
                    if (showDispatchDetails) ...[
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: l10n.t('home_service_detail.dispatch_title'),
                        children: [
                          _DetailRow(
                            l10n.t('home_service_detail.dispatch_mode'),
                            dispatchMode.toUpperCase() == 'ZONE_POOL'
                                ? l10n.t('home_service_detail.dispatch_zone')
                                : l10n.homeServiceDynamicLabel(dispatchMode),
                          ),
                          if (providerPoolCount > 0)
                            _DetailRow(
                              l10n.t('home_service_detail.dispatch_pool'),
                              l10n.t(
                                'home_service_detail.dispatch_pool_count',
                                params: {'count': '$providerPoolCount'},
                              ),
                            ),
                          _DetailRow(
                            l10n.t('home_service_detail.dispatch_assignment'),
                            assignedProviderId.isEmpty
                                ? l10n.t(
                                    'home_service_detail.dispatch_assignment_pending',
                                  )
                                : l10n.t(
                                    'home_service_detail.dispatch_assignment_assigned',
                                  ),
                          ),
                          if (assignedAt.isNotEmpty)
                            _DetailRow(
                              l10n.t(
                                'home_service_detail.dispatch_assigned_at',
                              ),
                              assignedAt,
                            ),
                        ],
                      ),
                    ],
                    if (provider != null) ...[
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: l10n.t('home_service_detail.provider'),
                        children: [
                          _DetailRow(
                            l10n.t('home_service_detail.name'),
                            provider.name,
                          ),
                          _DetailRow(
                            l10n.t('home_service_detail.role'),
                            provider.title,
                          ),
                          if ((provider.contactPhone ?? '').isNotEmpty)
                            _DetailRow(
                              l10n.t('home_service_detail.phone'),
                              provider.contactPhone!,
                            ),
                          _DetailRow(
                            l10n.t('home_service_detail.availability'),
                            provider.isAvailable
                                ? l10n.t('home_service_detail.available_today')
                                : l10n.t('home_service_detail.by_confirmation'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (provider != null)
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: l10n.t('home_service_detail.message'),
                              isOutlined: true,
                              color: AppColors.homeServices,
                              onPressed: () => openConversation(
                                context,
                                moduleType: orderModuleType,
                                entityType: 'HOME_SERVICE_PROVIDER',
                                entityId: provider.id,
                                title: provider.name,
                                subtitle: provider.title,
                                avatarUrl: provider.imageUrl,
                                accentColor: '#0F9D92',
                                metadata: {
                                  'providerId': provider.id,
                                  'categorySlug': provider.categorySlug,
                                  'serviceModes': provider.bookingModes,
                                  'orderId': order['id'],
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: l10n.t('home_service_detail.call_provider'),
                              color: AppColors.homeServices,
                              onPressed: _callProvider,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: l10n.t('home_service_detail.view_orders'),
                      isOutlined: true,
                      color: AppColors.homeServices,
                      onPressed: () => context.go('/orders'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.labelMedium)),
        ],
      ),
    );
  }
}
