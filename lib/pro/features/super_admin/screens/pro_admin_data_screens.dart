import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/money_format.dart';
import '../../../core/constants/pro_design_system.dart';

/// Shared scaffolding for super-admin data management screens: search bar,
/// paginated list with load-more, pull-to-refresh, and error states.

class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onSubmitted();
                  },
                ),
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProDesignSystem.radiusMedium),
        ),
      ),
    );
  }
}

class AdminErrorView extends StatelessWidget {
  const AdminErrorView({super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProDesignSystem.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: ProDesignSystem.spacing12),
            Text(
              'Could not load data: $error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: ProDesignSystem.spacing12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class AdminLoadMoreButton extends StatelessWidget {
  const AdminLoadMoreButton({
    super.key,
    required this.onLoadMore,
    required this.isLoading,
    required this.visible,
  });

  final VoidCallback onLoadMore;
  final bool isLoading;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ProDesignSystem.spacing12),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : OutlinedButton(onPressed: onLoadMore, child: const Text('Load more')),
      ),
    );
  }
}

/// Generic map-based row type so screens can render records without
/// duplicating parsing code for every endpoint.
typedef AdminRecord = Map<String, dynamic>;

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  List<AdminRecord> _users = [];
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;
  String _search = '';

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
          '/admin/users?page=1&take=25&search=$_search',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _users = (response['users'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _total = ((response["total"] as num?) ?? 0).toInt();
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
    if (_loadingMore || _users.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
          '/admin/users?page=${_page + 1}&take=25&search=$_search',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(
          (response['users'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _total = ((response["total"] as num?) ?? _total).toInt();
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _setBan(AdminRecord user, bool banned) async {
    try {
      await ApiClient.patch('/admin/users/${user['id']}/ban', {
        'banned': banned,
        if (banned) 'banReason': 'Account suspended by super admin.',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user['email']} ${banned ? 'banned' : 'unbanned'}.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users ($_total)'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(ProDesignSystem.spacing12),
            child: AdminSearchBar(
              controller: _searchController,
              hint: 'Search name, email, or phone',
              onSubmitted: () {
                setState(() => _search = _searchController.text.trim());
                _load();
              },
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
                      itemCount: _users.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          return AdminLoadMoreButton(
                            onLoadMore: _loadMore,
                            isLoading: _loadingMore,
                            visible: _users.length < _total,
                          );
                        }
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (user['banned'] as bool? ?? false)
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.12),
                              child: Icon(
                                (user['isPro'] as bool? ?? false)
                                    ? Icons.storefront
                                    : Icons.person_outline,
                                color: (user['banned'] as bool? ?? false)
                                    ? AppColors.error
                                    : AppColors.primaryDark,
                              ),
                            ),
                            title: Text(
                              '${user['name'] ?? ''}'
                              .trim()
                              .isEmpty
                                  ? '${user['email']}'
                                  : '${user['name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${user['email']}'
                              '${user['isPro'] == true ? ' • PRO: ${user['proBusinessName']}' : ''}'
                              '\nOrders: ${user['orders'] ?? 0} • Rides: ${user['rides'] ?? 0}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'ban') {
                                  _setBan(user, !(user['banned'] as bool? ?? false));
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'ban',
                                  child: Text(
                                    user['banned'] == true
                                        ? 'Unban account'
                                        : 'Ban account',
                                  ),
                                ),
                              ],
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

class AdminProAccountsScreen extends StatefulWidget {
  const AdminProAccountsScreen({super.key});

  @override
  State<AdminProAccountsScreen> createState() => _AdminProAccountsScreenState();
}

class _AdminProAccountsScreenState extends State<AdminProAccountsScreen> {
  final _searchController = TextEditingController();
  List<AdminRecord> _accounts = [];
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;
  String _search = '';

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
          '/admin/pro-accounts?page=1&take=25&search=$_search',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _accounts = (response['accounts'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _total = ((response["total"] as num?) ?? 0).toInt();
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
    if (_loadingMore || _accounts.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
          '/admin/pro-accounts?page=${_page + 1}&take=25&search=$_search',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _accounts.addAll(
          (response['accounts'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _total = ((response["total"] as num?) ?? _total).toInt();
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _setBan(AdminRecord account, bool banned) async {
    try {
      await ApiClient.patch('/admin/pro-accounts/${account['id']}/ban', {
        'banned': banned,
        if (banned) 'banReason': 'Account suspended by super admin.',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${account['email']} ${banned ? 'banned' : 'unbanned'}.'),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pro Accounts ($_total)'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(ProDesignSystem.spacing12),
            child: AdminSearchBar(
              controller: _searchController,
              hint: 'Search name, email, or phone',
              onSubmitted: () {
                setState(() => _search = _searchController.text.trim());
                _load();
              },
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
                      itemCount: _accounts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _accounts.length) {
                          return AdminLoadMoreButton(
                            onLoadMore: _loadMore,
                            isLoading: _loadingMore,
                            visible: _accounts.length < _total,
                          );
                        }
                        final account = _accounts[index];
                        final profile = account['proProfile'] as Map?;
                        final verified = profile?['isVerified'] == true;
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (account['banned'] as bool? ?? false)
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : verified
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : AppColors.warning.withValues(alpha: 0.15),
                              child: Icon(
                                account['banned'] == true
                                    ? Icons.block
                                    : verified
                                    ? Icons.verified_outlined
                                    : Icons.hourglass_top,
                                color: account['banned'] == true
                                    ? AppColors.error
                                    : verified
                                    ? Colors.green
                                    : AppColors.warning,
                              ),
                            ),
                            title: Text(
                              '${account['fullName'] ?? account['email']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${account['email']}'
                              '${profile != null ? '\n${profile['businessName']} • ${profile['type']}' : '\nNo pro profile'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'ban') {
                                  _setBan(
                                    account,
                                    !(account['banned'] as bool? ?? false),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'ban',
                                  child: Text(
                                    account['banned'] == true
                                        ? 'Unban account'
                                        : 'Ban account',
                                  ),
                                ),
                              ],
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

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key, this.initialModule = ''});

  final String initialModule;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  List<AdminRecord> _orders = [];
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;
  String _search = '';
  late String _module = widget.initialModule;
  static const _moduleOptions = <String, String>{
    '': 'All modules',
    'order': 'Store orders',
    'ride': 'Rides',
    'laundry': 'Laundry',
    'hotel': 'Hotels',
    'appointment': 'Appointments',
  };

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
          '/admin/orders?page=1&take=25&search=$_search&module=$_module',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _orders = (response['orders'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _total = ((response["total"] as num?) ?? 0).toInt();
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
    if (_loadingMore || _orders.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
          '/admin/orders?page=${_page + 1}&take=25&search=$_search&module=$_module',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _orders.addAll(
          (response['orders'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _total = ((response["total"] as num?) ?? _total).toInt();
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'ACCEPTED':
        return Colors.green;
      case 'CANCELLED':
      case 'REFUNDED':
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
      case 'REQUESTED':
      case 'DRAFT':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders ($_total)'),
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
              children: _moduleOptions.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(
                        right: ProDesignSystem.spacing8,
                      ),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _module == entry.key,
                        onSelected: (_) {
                          setState(() => _module = entry.key);
                          _load();
                        },
                      ),
                    ),
                  )
                  .toList(),
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
                      itemCount: _orders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _orders.length) {
                          return AdminLoadMoreButton(
                            onLoadMore: _loadMore,
                            isLoading: _loadingMore,
                            visible: _orders.length < _total,
                          );
                        }
                        final order = _orders[index];
                        final status = '${order['status']}';
                        final total = order['total'];
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(
                                status,
                              ).withValues(alpha: 0.15),
                              child: Icon(
                                switch (order['kind']) {
                                  'ride' => Icons.local_taxi_outlined,
                                  'laundry' => Icons.local_laundry_service_outlined,
                                  'hotel' => Icons.hotel_outlined,
                                  'appointment' => Icons.event_note_outlined,
                                  _ => Icons.receipt_long_outlined,
                                },
                                color: _statusColor(status),
                              ),
                            ),
                            title: Text(
                              '${order['customer']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${order['kind']} • ${order['customerEmail']}'
                              '${order['moduleType'] != null ? ' • ${order['moduleType']}' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(status),
                                  ),
                                ),
                                if (total != null)
                                  Text(
                                    'DJF ${money((total as num).toDouble())}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
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

class AdminRestaurantsScreen extends StatefulWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  State<AdminRestaurantsScreen> createState() => _AdminRestaurantsScreenState();
}

class _AdminRestaurantsScreenState extends State<AdminRestaurantsScreen> {
  final _searchController = TextEditingController();
  List<AdminRecord> _restaurants = [];
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;
  String _search = '';

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
          '/admin/restaurants?page=1&take=25&search=$_search',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _restaurants = (response['restaurants'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _total = ((response["total"] as num?) ?? 0).toInt();
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
    if (_loadingMore || _restaurants.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
          '/admin/restaurants?page=${_page + 1}&take=25&search=$_search',
          forceRefresh: true,
        ) as Map,
      );
      if (!mounted) return;
      setState(() {
        _restaurants.addAll(
          (response['restaurants'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _total = ((response["total"] as num?) ?? _total).toInt();
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _regenerateCode(AdminRecord restaurant) async {
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post(
          '/admin/restaurants/${restaurant['id']}/regenerate-code',
          {},
        ) as Map,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New code for ${response['name']}: ${response['redeemCode']}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurants ($_total)'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(ProDesignSystem.spacing12),
            child: AdminSearchBar(
              controller: _searchController,
              hint: 'Search restaurant name',
              onSubmitted: () {
                setState(() => _search = _searchController.text.trim());
                _load();
              },
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
                      itemCount: _restaurants.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _restaurants.length) {
                          return AdminLoadMoreButton(
                            onLoadMore: _loadMore,
                            isLoading: _loadingMore,
                            visible: _restaurants.length < _total,
                          );
                        }
                        final restaurant = _restaurants[index];
                        final code = '${restaurant['redeemCode'] ?? ''}';
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing8,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.food,
                              child: Icon(
                                Icons.restaurant_outlined,
                                color: AppColors.white,
                              ),
                            ),
                            title: Text(
                              '${restaurant['name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${restaurant['cuisine'] ?? 'No cuisine'}'
                              '${code.isNotEmpty ? ' • Code: $code' : ' • No code'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: 'Regenerate redeem code',
                              icon: const Icon(Icons.refresh),
                              onPressed: () => _regenerateCode(restaurant),
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
