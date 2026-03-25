import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/models.dart';
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
  bool _usingSampleData = false;

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
        _allOrders = _sampleOrders();
        _isLoading = false;
        _usingSampleData = true;
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
        _allOrders = hasLiveResponse ? data : _sampleOrders();
        _isLoading = false;
        _usingSampleData = !hasLiveResponse;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _allOrders = _sampleOrders();
        _isLoading = false;
        _usingSampleData = true;
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
        'trackingRoute': order['trackingRoute']?.toString(),
      };
    }).toList();
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

  List<Map<String, dynamic>> _sampleOrders() {
    return OrderModel.sampleOrders.map((order) {
      final status = order.status.toUpperCase() == 'ACTIVE'
          ? 'DISPATCHED'
          : order.status.toUpperCase() == 'COMPLETED'
          ? 'COMPLETED'
          : 'CANCELLED';
      return {
        'id': order.id,
        'moduleType': order.moduleType.toUpperCase(),
        'status': status,
        'total': order.total,
        'createdAt': order.createdAt.toIso8601String(),
        'items': order.items
            .map((item) => {'name': item.name, 'quantity': item.quantity})
            .toList(),
        'moduleName': order.moduleName,
      };
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          if (_usingSampleData)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Showing demo orders so you can keep reviewing the app flow while backend work is paused.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OrderList(orders: activeOrders),
                _OrderList(orders: completedOrders),
                _OrderList(orders: cancelledOrders),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<dynamic> orders;
  const _OrderList({required this.orders});

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
      default:
        return AppColors.primary;
    }
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
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final o = orders[index];
        final module = o['moduleType'].toString().toUpperCase();

        Color statusColor = AppColors.primary;
        final st = o['status'].toString().toUpperCase();
        if (st == 'COMPLETED') statusColor = AppColors.success;
        if (st == 'CANCELLED') statusColor = AppColors.error;

        // Parse items just to show a summary target name
        String displayItem = 'Order #${o['id'].toString().substring(0, 5)}';
        if (o['items'] != null) {
          try {
            final List items = o['items'] as List;
            if (items.isNotEmpty && items[0]['name'] != null) {
              displayItem = items[0]['name'] ?? displayItem;
            } else if (items.isNotEmpty && items[0]['service'] != null) {
              displayItem = items[0]['service'] ?? displayItem;
            } else if (items.isNotEmpty && items[0]['vehicle'] != null) {
              displayItem = items[0]['vehicle'] ?? displayItem;
            }
          } catch (_) {}
        }
        if (displayItem.startsWith('Order #') &&
            (o['moduleName']?.toString().isNotEmpty ?? false)) {
          displayItem = o['moduleName'].toString();
        }

        final trackingRoute = o['trackingRoute']?.toString();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppSpacing.shadowSm,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getColor(module).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getIcon(module),
                      color: _getColor(module),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayItem, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          o['moduleName']?.toString() ?? module,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusBadge(text: st, color: statusColor),
                            const Spacer(),
                            Text(
                              '\$${(o['total'] ?? 0).toStringAsFixed(2)}',
                              style: AppTextStyles.priceSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Order ${o['id']}', style: AppTextStyles.caption),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (trackingRoute != null && trackingRoute.isNotEmpty) {
                        if (module == 'RIDE') {
                          context.push(trackingRoute, extra: o);
                          return;
                        }
                        context.push(trackingRoute);
                      } else if (module == 'DOCTOR') {
                        context.push('/doctor/appointments');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Detailed tracking will appear here next.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      trackingRoute != null && trackingRoute.isNotEmpty
                          ? 'Track'
                          : module == 'DOCTOR'
                          ? 'Open'
                          : 'Details',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
