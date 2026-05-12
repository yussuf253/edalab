import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showContactUnavailableSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n?.doctorBookingNoContact ?? 'No contact information available',
      ),
    ),
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
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n?.doctorBookingCannotOpenContact ??
            'Cannot open contact information',
      ),
    ),
  );
}
