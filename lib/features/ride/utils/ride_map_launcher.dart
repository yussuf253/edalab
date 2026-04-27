import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../widgets/ride_route_preview.dart';

Future<void> openRideRouteInMaps(
  BuildContext context, {
  required String pickupLabel,
  required String destinationLabel,
  RideMapPoint? pickupPoint,
  RideMapPoint? destinationPoint,
}) async {
  final origin = pickupPoint != null
      ? '${pickupPoint.latitude},${pickupPoint.longitude}'
      : pickupLabel;
  final destination = destinationPoint != null
      ? '${destinationPoint.latitude},${destinationPoint.longitude}'
      : destinationLabel;
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&origin=${Uri.encodeComponent(origin)}'
    '&destination=${Uri.encodeComponent(destination)}'
    '&travelmode=driving',
  );

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || launched) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.t('ride.map_open_failed'))),
  );
}
