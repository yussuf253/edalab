import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/providers/pro_auth_provider.dart';

class ParcelDeliveryQueueScreen extends StatefulWidget {
  const ParcelDeliveryQueueScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  final String userId;
  final String businessName;

  @override
  State<ParcelDeliveryQueueScreen> createState() =>
      _ParcelDeliveryQueueScreenState();
}

class _ParcelDeliveryQueueScreenState extends State<ParcelDeliveryQueueScreen> {
  List<Map<String, dynamic>> _parcels = const [];
  final Set<String> _busyIds = {};
  bool _loading = true;
  String? _error;

  String _text(BuildContext context, String en, String fr, String ar) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return fr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.get(
        '/parcels/pro/${widget.userId}/queue',
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _parcels = (response as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(growable: false);
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

  Future<void> _act(Map<String, dynamic> parcel) async {
    final id = parcel['id']?.toString() ?? '';
    if (id.isEmpty || _busyIds.contains(id)) return;
    final isOnline =
        context.read<ProAuthProvider>().currentProfile?.isOnline ?? true;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              context,
              'Go online before managing parcels.',
              'Passez en ligne pour gérer les colis.',
              'اتصل بالإنترنت لإدارة الطرود.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _busyIds.add(id));
    try {
      final queueType = parcel['queueType']?.toString();
      if (queueType == 'open') {
        await ApiClient.post(
          '/parcels/pro/${widget.userId}/$id/claim',
          const {},
        );
      } else {
        final nextStatus = switch (parcel['status']?.toString().toUpperCase()) {
          'ACCEPTED' => 'PICKED_UP',
          'PICKED_UP' => 'IN_TRANSIT',
          'IN_TRANSIT' => 'DELIVERED',
          _ => null,
        };
        if (nextStatus != null) {
          await ApiClient.patch('/parcels/pro/${widget.userId}/$id/status', {
            'status': nextStatus,
          });
        }
      }
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  String _actionLabel(BuildContext context, Map<String, dynamic> parcel) {
    if (parcel['queueType'] == 'open') {
      return _text(context, 'Accept parcel', 'Accepter le colis', 'قبول الطرد');
    }
    switch (parcel['status']?.toString().toUpperCase()) {
      case 'ACCEPTED':
        return _text(
          context,
          'Mark picked up',
          'Confirmer la collecte',
          'تأكيد الاستلام',
        );
      case 'PICKED_UP':
        return _text(
          context,
          'Start delivery',
          'Démarrer la livraison',
          'بدء التوصيل',
        );
      case 'IN_TRANSIT':
        return _text(
          context,
          'Mark delivered',
          'Confirmer la livraison',
          'تأكيد التسليم',
        );
      default:
        return _text(context, 'Delivered', 'Livré', 'تم التسليم');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            context,
            'Parcel dispatch',
            'Livraison de colis',
            'توصيل الطرود',
          ),
        ),
        backgroundColor: AppColors.shopping,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 90),
                  const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _load,
                    child: Text(
                      _text(context, 'Retry', 'Réessayer', 'إعادة المحاولة'),
                    ),
                  ),
                ],
              )
            : _parcels.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 90),
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 42,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _text(
                      context,
                      'No parcel requests right now.',
                      'Aucune demande de colis pour le moment.',
                      'لا توجد طلبات طرود حالياً.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _parcels.length,
                itemBuilder: (context, index) =>
                    _parcelCard(context, _parcels[index]),
              ),
      ),
    );
  }

  Widget _parcelCard(BuildContext context, Map<String, dynamic> parcel) {
    final isOpen = parcel['queueType'] == 'open';
    final busy = _busyIds.contains(parcel['id']?.toString());
    final customerPhone = parcel['customerPhone']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.shopping,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${parcel['packageSize'] ?? ''} · ${(parcel['deliveryFee'] as num?)?.toInt() ?? 0} DJF',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  isOpen
                      ? _text(context, 'OPEN', 'LIBRE', 'متاح')
                      : _text(context, 'ASSIGNED', 'ATTRIBUÉ', 'مُعيّن'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${parcel['packageDescription'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              '${_text(context, 'From', 'De', 'من')}: ${parcel['pickupAddress'] ?? ''}',
            ),
            Text(
              '${_text(context, 'To', 'À', 'إلى')}: ${parcel['dropoffAddress'] ?? ''}',
            ),
            const SizedBox(height: 8),
            Text(
              '${_text(context, 'Sender', 'Expéditeur', 'المرسل')}: ${parcel['customerName'] ?? ''} · ${parcel['senderPhone'] ?? customerPhone}',
            ),
            Text(
              '${_text(context, 'Recipient', 'Destinataire', 'المستلم')}: ${parcel['recipientName'] ?? ''} · ${parcel['recipientPhone'] ?? ''}',
            ),
            if ((parcel['notes']?.toString() ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_text(context, 'Notes', 'Notes', 'ملاحظات')}: ${parcel['notes']}',
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : () => _act(parcel),
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isOpen ? Icons.check : Icons.arrow_forward),
                label: Text(_actionLabel(context, parcel)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
