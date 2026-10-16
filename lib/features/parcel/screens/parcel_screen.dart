import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';

class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  final _routeFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _dropoffAddress = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  Map<String, dynamic> _fees = const {
    'SMALL': 500,
    'MEDIUM': 800,
    'LARGE': 1200,
  };
  List<Map<String, dynamic>> _parcels = const [];
  String _size = 'SMALL';
  int _activeTab = 0;
  int _step = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Timer? _trackingTimer;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _senderName.text = '${user.firstName} ${user.lastName}'.trim();
      _senderPhone.text = user.phone;
    }
    _load();
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _load(showLoader: false),
    );
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _senderName.dispose();
    _senderPhone.dispose();
    _recipientName.dispose();
    _recipientPhone.dispose();
    _pickupAddress.dispose();
    _dropoffAddress.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true}) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/parcels/pricing', forceRefresh: true),
        if (userId != null)
          ApiClient.get('/parcels/user/$userId', forceRefresh: true),
      ]);
      if (!mounted) return;
      final pricing = Map<String, dynamic>.from(results.first as Map);
      final feeMap = Map<String, dynamic>.from(pricing['fees'] as Map);
      setState(() {
        _fees = feeMap;
        _parcels = results.length > 1
            ? (results[1] as List)
                  .map((entry) => Map<String, dynamic>.from(entry as Map))
                  .toList(growable: false)
            : const [];
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ApiClient.userFacingError(error);
      });
    }
  }

  String _text(String key) => l10n.t('parcel.$key');

  String? _required(String? value, {int minLength = 2}) {
    if (value == null || value.trim().length < minLength) {
      return _text('required');
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_step == 0) {
      if (!_routeFormKey.currentState!.validate()) return;
      setState(() => _step = 1);
      return;
    }
    if (!_detailsFormKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_text('sign_in_required'))));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient.post('/parcels', {
        'userId': user.id,
        'senderName': _senderName.text.trim(),
        'senderPhone': _senderPhone.text.trim(),
        'recipientName': _recipientName.text.trim(),
        'recipientPhone': _recipientPhone.text.trim(),
        'pickupAddress': _pickupAddress.text.trim(),
        'dropoffAddress': _dropoffAddress.text.trim(),
        'packageDescription': _description.text.trim(),
        'packageSize': _size,
        'notes': _notes.text.trim(),
      });
      if (!mounted) return;
      _recipientName.clear();
      _recipientPhone.clear();
      _dropoffAddress.clear();
      _description.clear();
      _notes.clear();
      setState(() {
        _step = 0;
        _activeTab = 1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_text('request_created'))));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> parcel) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      await ApiClient.post('/parcels/${parcel['id']}/cancel', {
        'userId': userId,
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return _text('status_requested');
      case 'ACCEPTED':
        return _text('status_accepted');
      case 'PICKED_UP':
        return _text('status_picked_up');
      case 'IN_TRANSIT':
        return _text('status_in_transit');
      case 'DELIVERED':
        return _text('status_delivered');
      case 'CANCELLED':
        return _text('status_cancelled');
      default:
        return status;
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator ?? _required,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_text('title')),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(_text('new_request')),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.route_outlined),
                  label: Text(_text('my_parcels')),
                ),
              ],
              selected: {_activeTab},
              onSelectionChanged: (selection) => setState(() {
                _activeTab = selection.first;
                _step = 0;
              }),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _activeTab == 0 ? _buildSendFlow() : _buildTracking(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _activeTab == 0 ? _buildActionBar() : null,
    );
  }

  Widget _buildSendFlow() {
    return SingleChildScrollView(
      key: const ValueKey('parcel-send'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 20),
          _buildStepHeader(),
          const SizedBox(height: 16),
          if (_step == 0) _buildRouteStep() else _buildDetailsStep(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('hero_title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text('hero_subtitle'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final firstStep = _step == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _text(firstStep ? 'step_route' : 'step_package'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              firstStep ? '01 / 02' : '02 / 02',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: firstStep ? 0.5 : 1,
            minHeight: 5,
            backgroundColor: AppColors.lightGrey.withValues(alpha: 0.45),
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteStep() {
    return Form(
      key: _routeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('route_hint'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.lightGrey.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              children: [
                _field(
                  _pickupAddress,
                  _text('pickup_address'),
                  validator: (value) => _required(value, minLength: 5),
                  maxLines: 1,
                  icon: Icons.radio_button_checked,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 21, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 19,
                      color: AppColors.lightGrey,
                    ),
                  ),
                ),
                _field(
                  _dropoffAddress,
                  _text('dropoff_address'),
                  validator: (value) => _required(value, minLength: 5),
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _infoStrip(Icons.schedule_outlined, _text('courier_eta')),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _routeSummary(),
          const SizedBox(height: 20),
          Text(
            _text('package_size'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _sizeOption('SMALL', Icons.mail_outline),
              const SizedBox(width: 8),
              _sizeOption('MEDIUM', Icons.inventory_2_outlined),
              const SizedBox(width: 8),
              _sizeOption('LARGE', Icons.all_inbox_outlined),
            ],
          ),
          const SizedBox(height: 16),
          _field(
            _description,
            _text('package_description'),
            icon: Icons.description_outlined,
          ),
          Text(
            _text('sender_details'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _field(_senderName, _text('sender_name'), icon: Icons.person_outline),
          _field(
            _senderPhone,
            _text('sender_phone'),
            validator: (value) => _required(value, minLength: 5),
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
          ),
          Text(
            _text('recipient_details'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _field(
            _recipientName,
            _text('recipient_name'),
            icon: Icons.person_add_alt_outlined,
          ),
          _field(
            _recipientPhone,
            _text('recipient_phone'),
            validator: (value) => _required(value, minLength: 5),
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
          ),
          _field(
            _notes,
            _text('notes_optional'),
            validator: (_) => null,
            maxLines: 2,
            icon: Icons.note_alt_outlined,
          ),
        ],
      ),
    );
  }

  Widget _routeSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pickupAddress.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  _dropoffAddress.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _text('edit_route'),
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _sizeOption(String size, IconData icon) {
    final selected = _size == size;
    final fee = (_fees[size] as num?)?.toInt() ?? 0;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _size = size),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.lightGrey,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.grey),
              const SizedBox(height: 7),
              Text(
                _text('size_${size.toLowerCase()}'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('$fee DJF', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoStrip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.dark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final fee = (_fees[_size] as num?)?.toInt() ?? 0;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.7)),
          ),
        ),
        child: Row(
          children: [
            if (_step == 1) ...[
              IconButton(
                onPressed: () => setState(() => _step = 0),
                tooltip: _text('back'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
            ],
            if (_step == 1)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _text('delivery_fee'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$fee DJF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _step == 0
                          ? Icons.arrow_forward
                          : Icons.local_shipping_outlined,
                    ),
              label: Text(_text(_step == 0 ? 'continue' : 'send_request')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracking() {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        key: const ValueKey('parcel-tracking'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(child: _buildTrackingHeader()),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(hasScrollBody: false, child: _errorState())
          else if (_parcels.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _emptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: _parcels.length,
                itemBuilder: (context, index) => _parcelTile(_parcels[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _text('track_title'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _text('track_subtitle'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _load,
          tooltip: _text('refresh'),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.outbox_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _text('empty'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _text('empty_hint'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => setState(() => _activeTab = 0),
              icon: const Icon(Icons.add),
              label: Text(_text('new_request')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(_text('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _parcelTile(Map<String, dynamic> parcel) {
    final status = parcel['status']?.toString() ?? 'REQUESTED';
    final courier = parcel['courier'] is Map
        ? Map<String, dynamic>.from(parcel['courier'] as Map)
        : null;
    final progress = _statusProgress(status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(status),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${(parcel['deliveryFee'] as num?)?.toInt() ?? 0} DJF · ${_text('size_${(parcel['packageSize'] ?? 'SMALL').toString().toLowerCase()}')}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                if (status == 'REQUESTED')
                  IconButton(
                    onPressed: () => _cancel(parcel),
                    tooltip: _text('cancel_request'),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _trackingProgress(progress),
            const SizedBox(height: 15),
            _routeLine(
              _text('from'),
              parcel['pickupAddress']?.toString() ?? '',
              Icons.radio_button_checked,
            ),
            const SizedBox(height: 10),
            _routeLine(
              _text('to'),
              parcel['dropoffAddress']?.toString() ?? '',
              Icons.location_on_outlined,
            ),
            const Divider(height: 22),
            Text(
              parcel['packageDescription']?.toString() ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (courier != null) ...[
              const SizedBox(height: 10),
              _infoStrip(
                Icons.person_outline,
                '${_text('courier')}: ${courier['name'] ?? ''} · ${courier['phone'] ?? ''}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trackingProgress(double progress) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.extraLightGrey,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                _text('status_accepted'),
                maxLines: 2,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.grey),
              ),
            ),
            Expanded(
              child: Text(
                _text('status_picked_up'),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.grey),
              ),
            ),
            Expanded(
              child: Text(
                _text('status_delivered'),
                textAlign: TextAlign.end,
                maxLines: 2,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _statusProgress(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return 0.25;
      case 'PICKED_UP':
        return 0.55;
      case 'IN_TRANSIT':
        return 0.8;
      case 'DELIVERED':
        return 1;
      default:
        return 0;
    }
  }

  Widget _routeLine(String title, String address, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 2),
              Text(address, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
