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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate() || _submitting) return;
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
          border: const OutlineInputBorder(),
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
    final fee = (_fees[_size] as num?)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(_text('title'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              _text('new_request'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(_senderName, _text('sender_name')),
                  _field(
                    _senderPhone,
                    _text('sender_phone'),
                    validator: (value) => _required(value, minLength: 5),
                    keyboardType: TextInputType.phone,
                  ),
                  const Divider(height: 24),
                  _field(
                    _pickupAddress,
                    _text('pickup_address'),
                    validator: (value) => _required(value, minLength: 5),
                    maxLines: 2,
                  ),
                  _field(_recipientName, _text('recipient_name')),
                  _field(
                    _recipientPhone,
                    _text('recipient_phone'),
                    validator: (value) => _required(value, minLength: 5),
                    keyboardType: TextInputType.phone,
                  ),
                  _field(
                    _dropoffAddress,
                    _text('dropoff_address'),
                    validator: (value) => _required(value, minLength: 5),
                    maxLines: 2,
                  ),
                  _field(_description, _text('package_description')),
                  DropdownButtonFormField<String>(
                    initialValue: _size,
                    decoration: InputDecoration(
                      labelText: _text('package_size'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final size in ['SMALL', 'MEDIUM', 'LARGE'])
                        DropdownMenuItem(
                          value: size,
                          child: Text(_text('size_${size.toLowerCase()}')),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _size = value ?? 'SMALL'),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _notes,
                    _text('notes_optional'),
                    validator: (_) => null,
                    maxLines: 2,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_text('delivery_fee')}: $fee DJF',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(_text('send_request')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _text('my_parcels'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  tooltip: _text('refresh'),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(_error!),
                trailing: TextButton(
                  onPressed: _load,
                  child: Text(_text('retry')),
                ),
              )
            else if (_parcels.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(_text('empty'), textAlign: TextAlign.center),
              )
            else
              for (final parcel in _parcels) _parcelTile(parcel),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusLabel(status),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${(parcel['deliveryFee'] as num?)?.toInt() ?? 0} DJF'),
              ],
            ),
            const SizedBox(height: 10),
            Text('${_text('from')}: ${parcel['pickupAddress']}'),
            const SizedBox(height: 4),
            Text('${_text('to')}: ${parcel['dropoffAddress']}'),
            const SizedBox(height: 4),
            Text(
              '${parcel['packageDescription']} · ${_text('size_${(parcel['packageSize'] ?? 'SMALL').toString().toLowerCase()}')}',
            ),
            if (courier != null) ...[
              const Divider(height: 20),
              Text('${_text('courier')}: ${courier['name'] ?? ''}'),
              if ((courier['phone']?.toString() ?? '').isNotEmpty)
                Text('${_text('phone')}: ${courier['phone']}'),
            ],
            if (status == 'REQUESTED')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancel(parcel),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(_text('cancel_request')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
