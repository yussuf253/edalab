import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

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
    } catch (e) {
      setState(() {
        _allOrders = [];
        _isLoading = false;
        _error = null;
      });
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
    return value.map<Map<String, dynamic>>((entry) {
      final order = Map<String, dynamic>.from(entry as Map);
      final moduleType =
          order['moduleType']?.toString().toUpperCase() ?? 'ORDER';
      final items = (order['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final firstItem = items.isNotEmpty ? items.first : null;
      return {
        ...order,
        'moduleType': moduleType,
        'moduleName':
            order['moduleName']?.toString() ??
            firstItem?['brand']?.toString() ??
            firstItem?['name']?.toString() ??
            moduleType,
        'trackingRoute':
            order['trackingRoute']?.toString() ??
            _defaultTrackingRoute(moduleType, order['id']?.toString()),
      };
    }).where((order) => order['moduleType'] != 'GROCERY').toList();
  }

  List<Map<String, dynamic>> _normalizeAppointments(dynamic value) {
    if (value is! List) return const [];
    return value.map<Map<String, dynamic>>((entry) {
      final appointment = Map<String, dynamic>.from(entry as Map);
      return {
        'id': appointment['id'],
        'moduleType': 'DOCTOR',
        'moduleName': appointment['doctorName']?.toString() ?? 'Appointment',
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
                'Consultation',
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
            : ride['vehicle']?.toString() ?? 'Ride',
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('My Orders')),
        body: const OrdersShimmer(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('My Orders')),
        body: Center(
          child: Text(
            _error!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      );
    }

    // Split orders by status natively
    final activeOrders = _allOrders
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
    final completedOrders = _allOrders
        .where(
          (o) => [
            'COMPLETED',
            'CHECKED_OUT',
          ].contains(o['status'].toString().toUpperCase()),
        )
        .toList();
    final cancelledOrders = _allOrders
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
      appBar: AppBar(
        title: Text('My Orders', style: AppTextStyles.h3),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _ModuleFilterBar(
              selectedModule: _selectedModule,
              modules: _availableModules(_allOrders),
              onSelected: (value) =>
                  setState(() => _selectedModule = value),
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
    final modules = orders
        .map((entry) => (entry as Map)['moduleType']?.toString().toUpperCase() ?? '')
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

  const _OrderList({
    required this.orders,
    required this.selectedModule,
  });

  IconData _getIcon(String mod) {
    switch (mod) {
      case 'FOOD':
        return Icons.restaurant_rounded;
      case 'LAUNDRY':
        return Icons.local_laundry_service_rounded;
      case 'SHOPPING':
        return Icons.shopping_bag_rounded;
      case 'HOTEL':
        return Icons.hotel_rounded;
      case 'DOCTOR':
        return Icons.medical_services_rounded;
      case 'PHARMACY':
        return Icons.local_pharmacy_rounded;
      case 'GROCERY':
        return Icons.local_grocery_store_rounded;
      case 'RIDE':
        return Icons.directions_car_rounded;
      case 'HOME_SERVICES':
        return Icons.home_repair_service_rounded;
      default:
        return Icons.receipt_long_rounded;
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
        return AppColors.homeServices;
      default:
        return AppColors.primary;
    }
  }

  String _getGroupLabel(String mod) {
    switch (mod) {
      case 'DOCTOR':
        return 'Appointments';
      case 'HOME_SERVICES':
        return 'Home Services';
      case 'RIDE':
        return 'Rides';
      case 'FOOD':
        return 'Food Orders';
      case 'SHOPPING':
        return 'Shopping Orders';
      case 'GROCERY':
        return 'Grocery Orders';
      case 'PHARMACY':
        return 'Pharmacy Orders';
      case 'HOTEL':
        return 'Hotel Bookings';
      case 'LAUNDRY':
        return 'Laundry Orders';
      default:
        return 'Other Orders';
    }
  }

  int _getGroupPriority(String mod) {
    switch (mod) {
      case 'DOCTOR':
        return 0;
      case 'HOME_SERVICES':
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
    final module = order['moduleType'].toString().toUpperCase();
    final items = (order['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};

    if (module == 'DOCTOR') {
      return order['moduleName']?.toString() ?? 'Doctor Appointment';
    }
    if (module == 'HOME_SERVICES') {
      return metadata['serviceName']?.toString() ??
          firstItem?['name']?.toString() ??
          order['moduleName']?.toString() ??
          'Home Service';
    }
    if (module == 'RIDE') {
      return order['moduleName']?.toString() ?? 'Ride';
    }

    return firstItem?['name']?.toString() ??
        order['moduleName']?.toString() ??
        'Order';
  }

  String _displaySubtitle(Map<String, dynamic> order) {
    final module = order['moduleType'].toString().toUpperCase();
    final items = (order['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};

    if (module == 'DOCTOR') {
      final type = firstItem?['name']?.toString() ?? 'Consultation';
      final date = _formatDate(metadata['date']?.toString());
      final time = _formatTime(metadata['timeSlot']?.toString());
      return [type, date, time]
          .where((part) => part.trim().isNotEmpty)
          .join(' • ');
    }
    if (module == 'HOME_SERVICES') {
      final provider = firstItem?['brand']?.toString() ??
          order['moduleName']?.toString() ??
          'Service Provider';
      final date = _formatDate(metadata['scheduledDate']?.toString());
      return [provider, date]
          .where((part) => part.trim().isNotEmpty)
          .join(' • ');
    }
    if (module == 'RIDE') {
      final pickup = metadata['pickup']?.toString() ?? '';
      final destination = metadata['destination']?.toString() ?? '';
      if (pickup.isNotEmpty || destination.isNotEmpty) {
        return '$pickup → $destination'.trim();
      }
      return order['moduleName']?.toString() ?? 'Ride details';
    }

    final quantity = items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
    final brand = firstItem?['brand']?.toString() ?? order['moduleName']?.toString() ?? '';
    final quantityLabel = quantity > 0 ? '$quantity item${quantity == 1 ? '' : 's'}' : '';
    return [brand, quantityLabel]
        .where((part) => part.trim().isNotEmpty)
        .join(' • ');
  }

  String _actionLabel(Map<String, dynamic> order) {
    final module = order['moduleType'].toString().toUpperCase();
    final trackingRoute = order['trackingRoute']?.toString();
    if (trackingRoute != null && trackingRoute.isNotEmpty) {
      if (module == 'DOCTOR' || module == 'HOME_SERVICES') {
        return 'Open';
      }
      return module == 'RIDE' ? 'Track Ride' : 'Track';
    }
    return 'Details';
  }

  Map<String, List<Map<String, dynamic>>> _groupOrders(List<dynamic> source) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in source) {
      final order = Map<String, dynamic>.from(entry as Map);
      final module = order['moduleType']?.toString().toUpperCase() ?? 'OTHER';
      if (selectedModule != 'ALL' && module != selectedModule) continue;
      grouped.putIfAbsent(module, () => []).add(order);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _getGroupPriority(a).compareTo(_getGroupPriority(b)));

    return {
      for (final key in sortedKeys)
        key: (grouped[key]!..sort((a, b) {
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
    if (orders.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No orders',
          subtitle: 'You have no orders in this status',
        ),
      );
    }
    final grouped = _groupOrders(orders);

    if (grouped.isEmpty) {
      return Center(
        child: EmptyState(
          icon: _getIcon(selectedModule),
          title: 'Nothing here',
          subtitle: 'No ${selectedModule == 'ALL' ? 'items' : _getGroupLabel(selectedModule).toLowerCase()} in this status',
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
                  Text(_getGroupLabel(module), style: AppTextStyles.h4),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightGrey,
                      borderRadius: BorderRadius.circular(999),
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 112,
                        decoration: BoxDecoration(
                          color: _getColor(module),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _getColor(module).withValues(
                                        alpha: 0.12,
                                      ),
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
                                            color: _getColor(
                                              module,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            _getGroupLabel(module),
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color: _getColor(module),
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
                                _displayTitle(o),
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displaySubtitle(o),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.grey,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.extraLightGrey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Amount',
                                          style: AppTextStyles.caption,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '\$${amount.toStringAsFixed(2)}',
                                          style: AppTextStyles.priceSmall
                                              .copyWith(
                                                color: _getColor(module),
                                              ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        if (trackingRoute != null &&
                                            trackingRoute.isNotEmpty) {
                                          if (module == 'RIDE' ||
                                              module == 'HOME_SERVICES' ||
                                              module == 'SHOPPING' ||
                                              module == 'HOTEL' ||
                                              module == 'PHARMACY') {
                                            context.push(
                                              trackingRoute,
                                              extra: o,
                                            );
                                            return;
                                          }
                                          context.push(trackingRoute);
                                          return;
                                        }
                                        if (module == 'DOCTOR') {
                                          context.push('/doctor/appointments');
                                          return;
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Detailed tracking will appear here next.',
                                                ),
                                              ),
                                            );
                                      },
                                      child: Text(
                                        _actionLabel(o),
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
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
        return 'All';
      case 'DOCTOR':
        return 'Appointments';
      case 'HOME_SERVICES':
        return 'Home';
      case 'SHOPPING':
        return 'Shopping';
      case 'FOOD':
        return 'Food';
      case 'GROCERY':
        return 'Grocery';
      case 'PHARMACY':
        return 'Pharmacy';
      case 'HOTEL':
        return 'Hotels';
      case 'LAUNDRY':
        return 'Laundry';
      case 'RIDE':
        return 'Rides';
      default:
        return module;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? null
                    : Border.all(color: AppColors.lightGrey),
              ),
              child: Text(
                _label(module),
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.dark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
