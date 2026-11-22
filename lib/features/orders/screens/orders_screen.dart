import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/module_screen_app_bar.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/money_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _canonicalOrderModuleType(String? moduleType) {
  final normalized = (moduleType ?? '').toUpperCase();
  if (normalized == 'HOUSE_HELP') return 'HOME_SERVICES';
  return normalized;
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedModule = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() {
        _allOrders = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    try {
      final results = await Future.wait<Map<String, dynamic>>([
        _loadHistoryList('/orders/$userId'),
        _loadHistoryList('/appointments/$userId'),
        _loadHistoryList('/rides/user/$userId'),
      ]);
      final orders = _normalizeOrders(results[0]['data']);
      final appointments = _normalizeAppointments(results[1]['data']);
      final rides = _normalizeRides(results[2]['data']);
      final data = [...orders, ...appointments, ...rides]
        ..sort((a, b) {
          final aDate =
              DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      final hasLiveResponse = results.any((result) => result['ok'] == true);

      setState(() {
        _allOrders = hasLiveResponse ? data : [];
        _isLoading = false;
        _error = null;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'orders',
          'entity_type': 'order',
          'result_count': _allOrders.length,
          'source': hasLiveResponse ? 'remote' : 'fallback_empty',
        },
      );
    } catch (e) {
      setState(() {
        _allOrders = [];
        _isLoading = false;
        _error = null;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'orders',
          'entity_type': 'order',
          'result_count': 0,
          'source': 'error',
        },
      );
    }
  }

  Future<Map<String, dynamic>> _loadHistoryList(String endpoint) async {
    try {
      final data = await ApiClient.get(endpoint);
      return {'ok': true, 'data': data};
    } catch (_) {
      return {'ok': false, 'data': const []};
    }
  }

  List<Map<String, dynamic>> _normalizeOrders(dynamic value) {
    if (value is! List) return const [];
    return value
        .map<Map<String, dynamic>>((entry) {
          final order = Map<String, dynamic>.from(entry as Map);
          final rawModuleType =
              order['moduleType']?.toString().toUpperCase() ?? 'ORDER';
          final moduleType = _canonicalOrderModuleType(rawModuleType);
          final items = (order['items'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          final firstItem = items.isNotEmpty ? items.first : null;
          return {
            ...order,
            'rawModuleType': rawModuleType,
            'moduleType': moduleType,
            'moduleName':
                order['moduleName']?.toString() ??
                firstItem?['brand']?.toString() ??
                firstItem?['name']?.toString() ??
                moduleType,
            'trackingRoute':
                order['trackingRoute']?.toString() ??
                _defaultTrackingRoute(rawModuleType, order['id']?.toString()),
          };
        })
        .where((order) => order['moduleType'] != 'GROCERY')
        .toList();
  }

  List<Map<String, dynamic>> _normalizeAppointments(dynamic value) {
    if (value is! List) return const [];
    return value.map<Map<String, dynamic>>((entry) {
      final appointment = Map<String, dynamic>.from(entry as Map);
      return {
        'id': appointment['id'],
        'moduleType': 'DOCTOR',
        'moduleName':
            appointment['doctorName']?.toString() ??
            'orders.group_appointments',
        'status': appointment['status']?.toString().toUpperCase() ?? 'UPCOMING',
        'total': appointment['fee'] ?? 0,
        'createdAt':
            appointment['createdAt']?.toString() ??
            appointment['date']?.toString() ??
            DateTime.now().toIso8601String(),
        'updatedAt':
            appointment['updatedAt']?.toString() ??
            appointment['date']?.toString() ??
            DateTime.now().toIso8601String(),
        'trackingRoute': '/doctor/appointments',
        'items': [
          {
            'name':
                appointment['typeLabel']?.toString() ??
                appointment['type']?.toString() ??
                'orders.consultation',
            'quantity': 1,
            'metadata': {
              'doctorId': appointment['doctorId'],
              'date': appointment['date'],
              'timeSlot': appointment['timeSlot'],
            },
          },
        ],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _normalizeRides(dynamic value) {
    if (value is! List) return const [];
    return value.map<Map<String, dynamic>>((entry) {
      final ride = Map<String, dynamic>.from(entry as Map);
      return {
        'id': ride['id'],
        'moduleType': 'RIDE',
        'moduleName': ride['rideCategory'] is Map
            ? Map<String, dynamic>.from(ride['rideCategory'] as Map)['name']
            : ride['vehicle']?.toString() ?? 'orders.ride',
        'status': ride['status']?.toString().toUpperCase() ?? 'REQUESTED',
        'total': ride['total'] ?? 0,
        'createdAt':
            ride['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        'updatedAt':
            ride['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
        'trackingRoute':
            [
              'COMPLETED',
              'CANCELLED',
            ].contains(ride['status']?.toString().toUpperCase())
            ? null
            : '/ride/tracking/${ride['id']}',
        'items': [
          {
            'name':
                ride['vehicle']?.toString() ??
                ride['moduleName']?.toString() ??
                'Ride',
            'quantity': 1,
            'metadata': {
              'pickup': ride['pickup'],
              'destination': ride['destination'],
            },
          },
        ],
      };
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _defaultTrackingRoute(String moduleType, String? id) {
    if (id == null || id.isEmpty) return null;
    switch (moduleType) {
      case 'HOME_SERVICES':
      case 'HOUSE_HELP':
        return '/home-services/booking/$id';
      case 'SHOPPING':
        return '/shopping/order/$id';
      case 'HOTEL':
        return '/hotel/order/$id';
      case 'PHARMACY':
        return '/pharmacy/order/$id';
      case 'LAUNDRY':
        return '/laundry/tracking/$id';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moduleProvider = context.watch<ModuleProvider>();
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleScreenAppBar(
          title: l10n.t('orders.title'),
          showBack: false,
        ),
        body: const OrdersShimmer(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleScreenAppBar(
          title: l10n.t('orders.title'),
          showBack: false,
        ),
        body: Center(
          child: Text(
            _error!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      );
    }

    final enabledOrders = _allOrders.where((entry) {
      final order = entry as Map;
      final module = _canonicalOrderModuleType(order['moduleType']?.toString());
      return moduleProvider.isEnabled(module);
    }).toList();
    final availableModules = _availableModules(enabledOrders);
    if (!availableModules.contains(_selectedModule)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedModule = 'ALL');
      });
    }

    // Split orders by status natively
    final activeOrders = enabledOrders
        .where(
          (o) => [
            'PENDING',
            'CONFIRMED',
            'PROCESSING',
            'DISPATCHED',
            'IN_PROGRESS',
            'UPCOMING',
            'REQUESTED',
            'ACCEPTED',
            'DRIVER_ARRIVING',
            'SCHEDULED',
            'PICKED_UP',
            'CLEANING',
            'OUT_FOR_DELIVERY',
            'CHECKED_IN',
          ].contains(o['status'].toString().toUpperCase()),
        )
        .toList();
    final completedOrders = enabledOrders
        .where(
          (o) => [
            'COMPLETED',
            'CHECKED_OUT',
          ].contains(o['status'].toString().toUpperCase()),
        )
        .toList();
    final cancelledOrders = enabledOrders
        .where(
          (o) => [
            'CANCELLED',
            'REFUNDED',
            'NO_SHOW',
          ].contains(o['status'].toString().toUpperCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleScreenAppBar(
        title: l10n.t('orders.title'),
        showBack: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _OrdersTabBar(
              controller: _tabController,
              labels: [
                l10n.t('orders.active'),
                l10n.t('orders.completed'),
                l10n.t('orders.cancelled'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _ModuleFilterBar(
              selectedModule: _selectedModule,
              modules: availableModules,
              onSelected: (value) {
                setState(() => _selectedModule = value);
                AnalyticsService.instance.track(
                  AnalyticsEvents.filterApplied,
                  properties: {
                    'module': 'orders',
                    'filter_type': 'module',
                    'filter_value': value,
                  },
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OrderList(
                  orders: activeOrders,
                  selectedModule: _selectedModule,
                ),
                _OrderList(
                  orders: completedOrders,
                  selectedModule: _selectedModule,
                ),
                _OrderList(
                  orders: cancelledOrders,
                  selectedModule: _selectedModule,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _availableModules(List<dynamic> orders) {
    final modules =
        orders
            .map(
              (entry) => _canonicalOrderModuleType(
                (entry as Map)['moduleType']?.toString(),
              ),
            )
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['ALL', ...modules];
  }
}

class _OrderList extends StatelessWidget {
  final List<dynamic> orders;
  final String selectedModule;

  const _OrderList({required this.orders, required this.selectedModule});

  IconData _getIcon(String mod) {
    switch (mod) {
      case 'FOOD':
        return LucideIcons.utensilsCrossed;
      case 'LAUNDRY':
        return LucideIcons.washingMachine;
      case 'SHOPPING':
        return LucideIcons.shoppingBag;
      case 'HOTEL':
        return LucideIcons.hotel;
      case 'DOCTOR':
        return LucideIcons.briefcaseMedical;
      case 'PHARMACY':
        return LucideIcons.pill;
      case 'GROCERY':
        return LucideIcons.shoppingCart;
      case 'RIDE':
        return LucideIcons.car;
      case 'HOME_SERVICES':
      case 'HOUSE_HELP':
        return LucideIcons.hammer;
      default:
        return LucideIcons.receiptText;
    }
  }

  Color _getColor(String mod) {
    switch (mod) {
      case 'FOOD':
        return AppColors.food;
      case 'LAUNDRY':
        return AppColors.laundry;
      case 'SHOPPING':
        return AppColors.shopping;
      case 'HOTEL':
        return AppColors.hotel;
      case 'DOCTOR':
        return AppColors.doctor;
      case 'PHARMACY':
        return AppColors.pharmacy;
      case 'GROCERY':
        return AppColors.grocery;
      case 'RIDE':
        return AppColors.ride;
      case 'HOME_SERVICES':
      case 'HOUSE_HELP':
        return AppColors.homeServices;
      default:
        return AppColors.primary;
    }
  }

  String _getGroupLabel(String mod) {
    switch (mod) {
      case 'DOCTOR':
        return 'orders.group_appointments';
      case 'HOME_SERVICES':
      case 'HOUSE_HELP':
        return 'orders.group_home_services';
      case 'RIDE':
        return 'orders.group_rides';
      case 'FOOD':
        return 'orders.group_food';
      case 'SHOPPING':
        return 'orders.group_shopping';
      case 'GROCERY':
        return 'orders.group_grocery';
      case 'PHARMACY':
        return 'orders.group_pharmacy';
      case 'HOTEL':
        return 'orders.group_hotels';
      case 'LAUNDRY':
        return 'orders.group_laundry';
      default:
        return 'orders.group_other';
    }
  }

  int _getGroupPriority(String mod) {
    switch (mod) {
      case 'DOCTOR':
        return 0;
      case 'HOME_SERVICES':
      case 'HOUSE_HELP':
        return 1;
      case 'RIDE':
        return 2;
      case 'FOOD':
        return 3;
      case 'SHOPPING':
        return 4;
      case 'GROCERY':
        return 5;
      case 'PHARMACY':
        return 6;
      case 'HOTEL':
        return 7;
      case 'LAUNDRY':
        return 8;
      default:
        return 9;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
      case 'CHECKED_OUT':
        return AppColors.success;
      case 'CANCELLED':
      case 'REFUNDED':
      case 'NO_SHOW':
        return AppColors.error;
      case 'UPCOMING':
      case 'PENDING':
      case 'CONFIRMED':
      case 'REQUESTED':
      case 'ACCEPTED':
      case 'IN_PROGRESS':
      case 'DRIVER_ARRIVING':
      case 'PROCESSING':
      case 'DISPATCHED':
      case 'SCHEDULED':
      case 'PICKED_UP':
      case 'CLEANING':
      case 'OUT_FOR_DELIVERY':
      case 'CHECKED_IN':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  String _displayTitle(Map<String, dynamic> order) {
    final module = _canonicalOrderModuleType(order['moduleType']?.toString());
    final items = (order['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};

    if (module == 'DOCTOR') {
      return order['moduleName']?.toString() ?? 'orders.doctor_appointment';
    }
    if (module == 'HOME_SERVICES') {
      return metadata['serviceName']?.toString() ??
          firstItem?['name']?.toString() ??
          order['moduleName']?.toString() ??
          'orders.home_service';
    }
    if (module == 'RIDE') {
      return order['moduleName']?.toString() ?? 'orders.ride';
    }

    return firstItem?['name']?.toString() ??
        order['moduleName']?.toString() ??
        'orders.order';
  }

  String _displaySubtitle(Map<String, dynamic> order) {
    final module = _canonicalOrderModuleType(order['moduleType']?.toString());
    final items = (order['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};

    if (module == 'DOCTOR') {
      final type = firstItem?['name']?.toString() ?? 'orders.consultation';
      final date = _formatDate(metadata['date']?.toString());
      final time = _formatTime(metadata['timeSlot']?.toString());
      return [
        type,
        date,
        time,
      ].where((part) => part.trim().isNotEmpty).join(' • ');
    }
    if (module == 'HOME_SERVICES') {
      final provider =
          firstItem?['brand']?.toString() ??
          order['moduleName']?.toString() ??
          'orders.service_provider';
      final date = _formatDate(metadata['scheduledDate']?.toString());
      return [
        provider,
        date,
      ].where((part) => part.trim().isNotEmpty).join(' • ');
    }
    if (module == 'RIDE') {
      final pickup = metadata['pickup']?.toString() ?? '';
      final destination = metadata['destination']?.toString() ?? '';
      if (pickup.isNotEmpty || destination.isNotEmpty) {
        return '$pickup → $destination'.trim();
      }
      return order['moduleName']?.toString() ?? 'orders.ride_details';
    }

    final quantity = items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
    final brand =
        firstItem?['brand']?.toString() ??
        order['moduleName']?.toString() ??
        '';
    final quantityLabel = quantity > 0
        ? 'orders.item_count|$quantity|${quantity == 1 ? '' : 's'}'
        : '';
    return [
      brand,
      quantityLabel,
    ].where((part) => part.trim().isNotEmpty).join(' • ');
  }

  String _actionLabel(Map<String, dynamic> order) {
    final module = _canonicalOrderModuleType(order['moduleType']?.toString());
    final trackingRoute = order['trackingRoute']?.toString();
    if (trackingRoute != null && trackingRoute.isNotEmpty) {
      if (module == 'DOCTOR' || module == 'HOME_SERVICES') {
        return 'orders.open';
      }
      return module == 'RIDE' ? 'orders.track_ride' : 'orders.track';
    }
    return 'orders.details';
  }

  Map<String, List<Map<String, dynamic>>> _groupOrders(List<dynamic> source) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in source) {
      final order = Map<String, dynamic>.from(entry as Map);
      final module = _canonicalOrderModuleType(order['moduleType']?.toString());
      final normalizedModule = module.isEmpty ? 'OTHER' : module;
      if (selectedModule != 'ALL' && module != selectedModule) continue;
      grouped.putIfAbsent(normalizedModule, () => []).add(order);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _getGroupPriority(a).compareTo(_getGroupPriority(b)));

    return {
      for (final key in sortedKeys)
        key: (grouped[key]!
          ..sort((a, b) {
            final aDate =
                DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          })),
    };
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    return DateFormat('dd MMM').format(parsed);
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final normalized = raw.trim();
    final parsedDateTime = DateTime.tryParse(normalized);
    if (parsedDateTime != null) {
      return DateFormat('HH:mm').format(parsedDateTime);
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(normalized);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour != null && minute != null) {
        final dt = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('HH:mm').format(dt);
      }
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (orders.isEmpty) {
      return Center(
        child: EmptyState(
          icon: LucideIcons.receiptText,
          title: l10n.t('orders.empty_title'),
          subtitle: l10n.t('orders.empty_subtitle'),
        ),
      );
    }
    final grouped = _groupOrders(orders);

    if (grouped.isEmpty) {
      return Center(
        child: EmptyState(
          icon: _getIcon(selectedModule),
          title: l10n.t('orders.empty_filtered_title'),
          subtitle: l10n.t(
            'orders.empty_filtered_subtitle',
            params: {
              'label': selectedModule == 'ALL'
                  ? l10n.t('common.everything').toLowerCase()
                  : l10n.t(_getGroupLabel(selectedModule)).toLowerCase(),
            },
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: grouped.entries.map((entry) {
        final module = entry.key;
        final sectionOrders = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _getColor(module).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(module),
                      color: _getColor(module),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.t(_getGroupLabel(module)), style: AppTextStyles.h4),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tile,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${sectionOrders.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...sectionOrders.map((o) {
                final status = o['status'].toString().toUpperCase();
                final trackingRoute = o['trackingRoute']?.toString();
                final amount = ((o['total'] as num?)?.toDouble() ?? 0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _getColor(
                                        module,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getIcon(module),
                                      color: _getColor(module),
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.tile,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.t(_getGroupLabel(module)),
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color: AppColors.primaryDark,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 10.5,
                                                ),
                                          ),
                                        ),
                                        StatusBadge(
                                          text: status.replaceAll('_', ' '),
                                          color: _statusColor(status),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _resolveLabel(_displayTitle(o), l10n),
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _resolveSubtitle(_displaySubtitle(o), l10n),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.grey,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.t('orders.amount'),
                                        style: AppTextStyles.caption,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'DJF${money(amount)}',
                                        style: AppTextStyles.priceSmall
                                            .copyWith(color: _getColor(module)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      AnalyticsService.instance.track(
                                        AnalyticsEvents.entityOpened,
                                        properties: {
                                          'module': 'orders',
                                          'entity_type': 'order_action',
                                          'entity_id':
                                              o['id']
                                                      ?.toString()
                                                      .trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? o['id'].toString().trim()
                                              : 'unknown',
                                          'order_module': module,
                                          'has_tracking_route':
                                              trackingRoute != null &&
                                              trackingRoute.isNotEmpty,
                                        },
                                      );
                                      if (trackingRoute != null &&
                                          trackingRoute.isNotEmpty) {
                                        if (module == 'RIDE' ||
                                            module == 'HOME_SERVICES' ||
                                            module == 'SHOPPING' ||
                                            module == 'HOTEL' ||
                                            module == 'PHARMACY') {
                                          context.push(trackingRoute, extra: o);
                                          return;
                                        }
                                        context.push(trackingRoute);
                                        return;
                                      }
                                      if (module == 'DOCTOR') {
                                        context.push('/doctor/appointments');
                                        return;
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.t(
                                              'orders.tracking_coming_soon',
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.primarySurface,
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _resolveLabel(_actionLabel(o), l10n),
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Segmented tab control for active / completed / cancelled orders.
class _OrdersTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const _OrdersTabBar({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = controller.index == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: selected ? AppColors.white : AppColors.grey,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _ModuleFilterBar extends StatelessWidget {
  final String selectedModule;
  final List<String> modules;
  final ValueChanged<String> onSelected;

  const _ModuleFilterBar({
    required this.selectedModule,
    required this.modules,
    required this.onSelected,
  });

  String _label(String module) {
    switch (module) {
      case 'ALL':
        return 'common.all';
      case 'DOCTOR':
        return 'orders.group_appointments';
      case 'HOME_SERVICES':
      case 'HOUSE_HELP':
        return 'module.home_services';
      case 'SHOPPING':
        return 'module.shopping';
      case 'FOOD':
        return 'module.food';
      case 'GROCERY':
        return 'module.grocery';
      case 'PHARMACY':
        return 'module.pharmacy';
      case 'HOTEL':
        return 'module.hotel';
      case 'LAUNDRY':
        return 'module.laundry';
      case 'RIDE':
        return 'orders.group_rides';
      default:
        return module;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final module = modules[index];
          final selected = module == selectedModule;
          return GestureDetector(
            onTap: () => onSelected(module),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Text(
                l10n.t(_label(module)),
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.dark,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension on _OrderList {
  String _resolveLabel(String value, AppLocalizations l10n) {
    if (value.startsWith('orders.') ||
        value.startsWith('module.') ||
        value.startsWith('common.')) {
      return l10n.t(value);
    }
    return value;
  }

  String _resolveSubtitle(String value, AppLocalizations l10n) {
    if (!value.contains('|')) return _resolveLabel(value, l10n);
    final parts = value.split('|');
    if (parts.length == 3 && parts.first == 'orders.item_count') {
      return l10n.t(
        parts.first,
        params: {'count': parts[1], 'suffix': parts[2]},
      );
    }
    return value;
  }
}
