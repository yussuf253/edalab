import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';

void showContactUnavailableSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.t('doctor_booking.no_contact'))),
  );
}

Future<void> launchPhoneCall(BuildContext context, String? phone) async {
  final normalizedPhone = phone?.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalizedPhone == null || normalizedPhone.isEmpty) {
    showContactUnavailableSnackBar(context);
    return;
  }

  final launched = await launchUrl(
    Uri(scheme: 'tel', path: normalizedPhone),
    mode: LaunchMode.externalApplication,
  );

  if (!context.mounted || launched) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.t('doctor_booking.cannot_open_contact')),
    ),
  );
}
