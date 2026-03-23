import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
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
      final data = await ApiClient.get('/orders/$userId');
      setState(() {
        _allOrders = data;
        _isLoading = false;
        _usingSampleData = false;
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
            .map((item) => {
                  'name': item.name,
                  'quantity': item.quantity,
                })
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('My Orders')),
        body: Center(child: Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
      );
    }

    // Split orders by status natively
    final activeOrders = _allOrders.where((o) => ['PENDING', 'PROCESSING', 'DISPATCHED', 'IN_PROGRESS'].contains(o['status'].toString().toUpperCase())).toList();
    final completedOrders = _allOrders.where((o) => o['status'].toString().toUpperCase() == 'COMPLETED').toList();
    final cancelledOrders = _allOrders.where((o) => o['status'].toString().toUpperCase() == 'CANCELLED').toList();

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
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Showing demo orders so you can keep reviewing the app flow while backend work is paused.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.dark),
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
      case 'FOOD': return Icons.restaurant_rounded;
      case 'LAUNDRY': return Icons.local_laundry_service_rounded;
      case 'SHOPPING': return Icons.shopping_bag_rounded;
      case 'HOTEL': return Icons.hotel_rounded;
      case 'PHARMACY': return Icons.local_pharmacy_rounded;
      case 'GROCERY': return Icons.local_grocery_store_rounded;
      case 'RIDE': return Icons.directions_car_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  Color _getColor(String mod) {
    switch (mod) {
      case 'FOOD': return AppColors.food;
      case 'LAUNDRY': return AppColors.laundry;
      case 'SHOPPING': return AppColors.shopping;
      case 'HOTEL': return AppColors.hotel;
      case 'PHARMACY': return AppColors.pharmacy;
      case 'RIDE': return AppColors.ride;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: EmptyState(icon: Icons.receipt_long_rounded, title: 'No orders', subtitle: 'You have no orders in this status'));
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
                    child: Icon(_getIcon(module), color: _getColor(module), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayItem, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 2),
                        Text(o['moduleName']?.toString() ?? module, style: AppTextStyles.caption),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusBadge(text: st, color: statusColor),
                            const Spacer(),
                            Text('\$${(o['total'] ?? 0).toStringAsFixed(2)}', style: AppTextStyles.priceSmall),
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
                  Text(
                    'Order ${o['id']}',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (module == 'FOOD' && st != 'COMPLETED' && st != 'CANCELLED') {
                        context.push('/food/tracking/${o['id']}');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Detailed tracking will appear here next.')),
                        );
                      }
                    },
                    child: Text(
                      module == 'FOOD' && st != 'COMPLETED' && st != 'CANCELLED'
                          ? 'Track'
                          : 'Details',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
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
