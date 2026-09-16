import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/city_availability_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Pro-flavored full-screen gate shown whenever
/// [CityAvailabilityProvider.isBlocking] is true — the pro variant of the
/// user app's CityNotAvailableScreen. Pro operatives work inside active
/// service zones only, so the gate blocks every route until the check
/// clears (or sends the user to device settings for permissions).
class ProCityGateScreen extends StatelessWidget {
  const ProCityGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityAvailabilityProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    size: 48,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.temporarilyUnavailable,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _messageFor(context, provider, l10n),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => provider.checkAvailability(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _messageFor(
    BuildContext context,
    CityAvailabilityProvider provider,
    AppLocalizations l10n,
  ) {
    switch (provider.status) {
      case CityAvailabilityStatus.locationServiceDisabled:
        return 'Enable location services so we can confirm you are in a '
            'supported service zone.';
      case CityAvailabilityStatus.permissionDeniedForever:
        return 'Location permission is permanently denied. Allow it from '
            'device settings to continue.';
      case CityAvailabilityStatus.permissionDenied:
      case CityAvailabilityStatus.outOfZone:
      case CityAvailabilityStatus.error:
      case CityAvailabilityStatus.unknown:
      case CityAvailabilityStatus.checking:
      case CityAvailabilityStatus.available:
        return 'EdaLab Pro is not yet available in your area. We will let '
            'you know as soon as we launch near you.';
    }
  }
}
