import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/money_format.dart';
import '../../../core/constants/pro_design_system.dart';
import 'pro_admin_data_screens.dart';

/// Dedicated, module-specific operations screens for the super admin.
/// Each vertical (store orders, rides, laundry, hotels, appointments) gets its
/// own screen with status filters, a rich detail sheet, and status actions —
/// not just a filtered shared list.

class _ModuleConfig {
  const _ModuleConfig({
    required this.kind,
    required this.title,
    required this.icon,
    required this.statuses,
    required this.terminalStatuses,
  });

  final String kind;
  final String title;
  final IconData icon;
  final List<String> statuses;
  final List<String> terminalStatuses;
}

const _orderConfig = _ModuleConfig(
  kind: 'order',
  title: 'Store Orders',
  icon: Icons.receipt_long_outlined,
  statuses: [
    'DRAFT',
    'PENDING',
    'CONFIRMED',
    'PROCESSING',
    'DISPATCHED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED',
    'REFUNDED',
  ],
  terminalStatuses: ['COMPLETED', 'CANCELLED', 'REFUNDED'],
);

const _rideConfig = _ModuleConfig(
  kind: 'ride',
  title: 'Rides',
  icon: Icons.local_taxi_outlined,
  statuses: [
    'REQUESTED',
    'ACCEPTED',
    'DRIVER_ARRIVING',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED',
  ],
  terminalStatuses: ['COMPLETED', 'CANCELLED'],
);

const _laundryConfig = _ModuleConfig(
  kind: 'laundry',
  title: 'Laundry',
  icon: Icons.local_laundry_service_outlined,
  statuses: [
    'PENDING',
    'SCHEDULED',
    'PICKED_UP',
    'CLEANING',
    'OUT_FOR_DELIVERY',
    'COMPLETED',
    'CANCELLED',
  ],
  terminalStatuses: ['COMPLETED', 'CANCELLED'],
);

const _hotelConfig = _ModuleConfig(
  kind: 'hotel',
  title: 'Hotel Bookings',
  icon: Icons.hotel_outlined,
  statuses: ['PENDING', 'CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED'],
  terminalStatuses: ['CHECKED_OUT', 'CANCELLED'],
);

const _appointmentConfig = _ModuleConfig(
  kind: 'appointment',
  title: 'Appointments',
  icon: Icons.event_note_outlined,
  statuses: [
    'PENDING',
    'APPROVED',
    'UPCOMING',
    'COMPLETED',
    'CANCELLED',
    'NO_SHOW',
    'REJECTED',
  ],
  terminalStatuses: ['COMPLETED', 'CANCELLED', 'NO_SHOW', 'REJECTED'],
);

/// Public widgets so the router and control center can link each card to its
/// dedicated screen.
class AdminStoreOrdersScreen extends StatelessWidget {
  const AdminStoreOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminModuleOpsScreen(config: _orderConfig);
}

class AdminRidesScreen extends StatelessWidget {
  const AdminRidesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminModuleOpsScreen(config: _rideConfig);
}

class AdminLaundryScreen extends StatelessWidget {
  const AdminLaundryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminModuleOpsScreen(config: _laundryConfig);
}

class AdminHotelsScreen extends StatelessWidget {
  const AdminHotelsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminModuleOpsScreen(config: _hotelConfig);
}

class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminModuleOpsScreen(config: _appointmentConfig);
}

class AdminModuleOpsScreen extends StatefulWidget {
  const AdminModuleOpsScreen({super.key, required this.config});

  final _ModuleConfig config;

  @override
  State<AdminModuleOpsScreen> createState() => _AdminModuleOpsScreenState();
}

class _AdminModuleOpsScreenState extends State<AdminModuleOpsScreen> {
  _ModuleConfig get _config => widget.config;

  final _searchController = TextEditingController();
  List<AdminRecord> _records = [];
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;
  String _search = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
          '/admin/records/${_config.kind}?page=1&take=25'
          '&search=$_search&status=$_status',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _records = (response['records'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _total = ((response['total'] as num?) ?? 0).toInt();
        _page = 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _records.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
          '/admin/records/${_config.kind}?page=${_page + 1}&take=25'
          '&search=$_search&status=$_status',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _records.addAll(
          (response['records'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _total = ((response['total'] as num?) ?? _total).toInt();
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  Future<void> _openDetails(AdminRecord record) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ModuleDetailSheet(config: _config, record: record),
    );
    if (changed == true) _load();
  }

  Future<void> _quickAction(AdminRecord record, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Set status to $status?'),
        content: Text(
          "This will move ${record['customer']}'s ${_config.title.toLowerCase()} "
          'record to $status. This action is logged against your admin account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(status == 'CANCELLED' ? 'Cancel record' : 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _applyStatus(record['id'] as String, status);
    if (ok) {
      _showSnack('Record moved to $status');
      _load();
    }
  }

  Future<bool> _applyStatus(String id, String status) async {
    try {
      await ApiClient.post(
        '/admin/records/${_config.kind}/$id/status',
        {'status': status},
      );
      return true;
    } catch (error) {
      _showSnack('$error', error: true);
      return false;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'ACCEPTED':
      case 'APPROVED':
      case 'CHECKED_IN':
        return Colors.green;
      case 'CANCELLED':
      case 'REFUNDED':
      case 'REJECTED':
      case 'NO_SHOW':
        return AppColors.error;
      case 'PENDING':
      case 'REQUESTED':
      case 'DRAFT':
      case 'UPCOMING':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _cardSubtitle(AdminRecord record) {
    switch (_config.kind) {
      case 'order':
        return [
          record['moduleType'],
          record['customerEmail'],
        ].where((part) => part != null && '$part'.isNotEmpty).join(' • ');
      case 'ride':
        return [
          record['categoryName'],
          record['pickupLabel'],
          record['dropoffLabel'],
        ].where((part) => part != null && '$part'.isNotEmpty).join(' → ');
      case 'laundry':
        return [
          record['serviceName'],
          '${record['itemCount'] ?? 0} items',
          record['timeSlot'],
        ].where((part) => part != null && '$part'.isNotEmpty).join(' • ');
      case 'hotel':
        return [
          record['hotelName'],
          record['roomType'],
          '${record['nights'] ?? 0} nights',
        ].where((part) => part != null && '$part'.isNotEmpty).join(' • ');
      default:
        return [
          record['doctorName'],
          record['appointmentType'],
          record['timeSlot'],
        ].where((part) => part != null && '$part'.isNotEmpty).join(' • ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_config.title} ($_total)'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ProDesignSystem.spacing12,
              ProDesignSystem.spacing12,
              ProDesignSystem.spacing12,
              0,
            ),
            child: AdminSearchBar(
              controller: _searchController,
              hint: 'Search by customer name or email',
              onSubmitted: () {
                setState(() => _search = _searchController.text.trim());
                _load();
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: ProDesignSystem.spacing12,
                vertical: ProDesignSystem.spacing8,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: ProDesignSystem.spacing8,
                  ),
                  child: ChoiceChip(
                    label: const Text('All statuses'),
                    selected: _status.isEmpty,
                    onSelected: (_) {
                      setState(() => _status = '');
                      _load();
                    },
                  ),
                ),
                ..._config.statuses.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(
                      right: ProDesignSystem.spacing8,
                    ),
                    child: ChoiceChip(
                      label: Text(
                        status.replaceAll('_', ' ').toLowerCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _status == status,
                      onSelected: (_) {
                        setState(() => _status = status);
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? AdminErrorView(error: _error, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: ProDesignSystem.spacing12,
                      ),
                      itemCount: _records.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _records.length) {
                          return AdminLoadMoreButton(
                            onLoadMore: _loadMore,
                            isLoading: _loadingMore,
                            visible: _records.length < _total,
                          );
                        }
                        final record = _records[index];
                        final status = '${record['status']}';
                        final total = record['total'];
                        final terminal = _config.terminalStatuses.contains(
                          status,
                        );
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing8,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              ProDesignSystem.radiusMedium,
                            ),
                            onTap: () => _openDetails(record),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ProDesignSystem.spacing12,
                                vertical: ProDesignSystem.spacing8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _statusColor(
                                      status,
                                    ).withValues(alpha: 0.15),
                                    child: Icon(
                                      _config.icon,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${record['customer']}'
                                          '  ·  #${'${record['id']}'.substring(0, 8)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _cardSubtitle(record),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            status,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          status.replaceAll('_', ' '),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _statusColor(status),
                                          ),
                                        ),
                                      ),
                                      if (total != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            'DJF ${money((total as num).toDouble())}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (!terminal) ...[
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) =>
                                          _quickAction(record, value),
                                      itemBuilder: (context) => [
                                        if (_config.kind != 'hotel')
                                          const PopupMenuItem(
                                            value: 'COMPLETED',
                                            child: Text('Mark completed'),
                                          ),
                                        if (_config.kind == 'hotel') ...[
                                          const PopupMenuItem(
                                            value: 'CONFIRMED',
                                            child: Text('Confirm booking'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'CHECKED_IN',
                                            child: Text('Check in guest'),
                                          ),
                                        ],
                                        const PopupMenuItem(
                                          value: 'CANCELLED',
                                          child: Text('Cancel record'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModuleDetailSheet extends StatefulWidget {
  const _ModuleDetailSheet({required this.config, required this.record});

  final _ModuleConfig config;
  final AdminRecord record;

  @override
  State<_ModuleDetailSheet> createState() => _ModuleDetailSheetState();
}

class _ModuleDetailSheetState extends State<_ModuleDetailSheet> {
  _ModuleConfig get _config => widget.config;

  Map<String, dynamic>? _detail;
  List<String> _allowedStatuses = const [];
  Object? _error;
  bool _applying = false;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
          '/admin/records/${_config.kind}/${widget.record['id']}',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _detail = Map<String, dynamic>.from(response['record'] as Map);
        _allowedStatuses = ((response['allowedStatuses'] as List?) ?? const [])
            .map((e) => '$e')
            .toList();
        _selectedStatus = '${_detail?['status']}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _selectedStatus = '${widget.record['status']}';
      });
    }
  }

  Future<void> _apply(String status) async {
    setState(() => _applying = true);
    try {
      await ApiClient.post(
        '/admin/records/${_config.kind}/${widget.record['id']}/status',
        {'status': status},
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _fieldLabel(String key) => switch (key) {
        'createdAtIso' => 'Created',
        'pickupAtIso' => 'Pickup',
        'checkInAtIso' => 'Check-in',
        'checkOutAtIso' => 'Check-out',
        'appointmentAtIso' => 'Appointment',
        'customerEmail' => 'Customer email',
        'deliveryAddress' => 'Delivery address',
        'deliveryPhone' => 'Delivery phone',
        'driverAccount' => 'Driver account',
        'driverName' => 'Driver (ride record)',
        'driverPhone' => 'Driver phone',
        'vehicleName' => 'Vehicle',
        'pickupLabel' => 'Pickup',
        'dropoffLabel' => 'Drop-off',
        'distanceKm' => 'Distance',
        'etaLabel' => 'ETA',
        'categoryName' => 'Ride category',
        'moduleName' => null,
        'serviceName' => 'Laundry service',
        'itemCount' => 'Item count',
        'itemBreakdown' => 'Items',
        'timeSlot' => 'Time slot',
        'subtotal' => 'Subtotal',
        'deliveryFee' => 'Delivery fee',
        'discount' => 'Discount',
        'total' => 'Total',
        'hotelName' => 'Hotel',
        'hotelCity' => 'City',
        'roomType' => 'Room type',
        'guestName' => 'Guest',
        'guestEmail' => 'Guest email',
        'guestPhone' => 'Guest phone',
        'nights' => 'Nights',
        'guestCount' => 'Guests',
        'doctorName' => 'Doctor',
        'doctorSpecialty' => 'Specialty',
        'appointmentType' => 'Type',
        'notes' => 'Notes',
        'moduleType' => 'Module',
        'courier' => 'Courier',
        'tax' => 'Tax',
        _ => null, // hide id/kind/status duplicates and unknowns
      };

  String _formatValue(String key, Object? value) {
    if (value == null) return '—';
    if (value is num && key != 'itemCount' && key != 'nights' && key != 'guestCount') {
      return 'DJF ${money(value.toDouble())}';
    }
    if (key.endsWith('Iso')) {
      final dt = DateTime.tryParse(value.toString());
      if (dt != null) {
        return '${dt.day}/${dt.month}/${dt.year}, '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    if (value is List) return value.isEmpty ? '—' : value.join(', ');
    if (value is Map) return value.toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? widget.record;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(ProDesignSystem.spacing16),
                child: Row(
                  children: [
                    Icon(_config.icon, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_config.title} — ${detail['customer']}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: _error != null && _detail == null
                    ? AdminErrorView(error: _error, onRetry: _load)
                    : _detail == null
                    ? const Padding(
                        padding: EdgeInsets.all(ProDesignSystem.spacing24),
                        child: CircularProgressIndicator(),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(
                          ProDesignSystem.spacing16,
                        ),
                        children: [
                            for (final entry in detail.entries)
                            if (_fieldLabel(entry.key.toString()) != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        _fieldLabel(entry.key.toString())!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _formatValue(
                                          entry.key.toString(),
                                          entry.value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(ProDesignSystem.spacing16),
                child: Row(
                  children: [
                    Expanded(
                      child:                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: _allowedStatuses
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.replaceAll('_', ' ').toLowerCase(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed:
                          _applying ||
                              _selectedStatus == null ||
                              _selectedStatus == '${detail['status']}'
                          ? null
                          : () => _apply(_selectedStatus!),
                      child: _applying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
