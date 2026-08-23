import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/config/service_zones.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/city_availability_provider.dart';

/// Full-screen gate shown whenever [CityAvailabilityProvider.isBlocking] is
/// true — either because the device is outside every active service zone,
/// or because we couldn't get a location fix at all (permission/GPS issue).
///
/// Wired into the router in `app_router.dart`: any route redirects here
/// while blocking, and back to the app the moment the check clears.
class CityNotAvailableScreen extends StatelessWidget {
  const CityNotAvailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityAvailabilityProvider>();
    final t = AppLocalizations.of(context);
    final languageCode = AppLocalizations.of(context).languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _contentFor(
                  context: context,
                  status: provider.status,
                  t: t,
                  languageCode: languageCode,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contentFor({
    required BuildContext context,
    required CityAvailabilityStatus status,
    required AppLocalizations t,
    required String languageCode,
  }) {
    switch (status) {
      case CityAvailabilityStatus.locationServiceDisabled:
        return _infoLayout(
          context: context,
          icon: Icons.location_disabled_rounded,
          iconColor: AppColors.warning,
          title: t.t('city_gate.location_disabled_title'),
          message: t.t('city_gate.location_disabled_message'),
          primaryButtonLabel: t.t('city_gate.retry_button'),
        );

      case CityAvailabilityStatus.permissionDenied:
        return _infoLayout(
          context: context,
          icon: Icons.location_off_rounded,
          iconColor: AppColors.warning,
          title: t.t('city_gate.permission_denied_title'),
          message: t.t('city_gate.permission_denied_message'),
          primaryButtonLabel: t.t('city_gate.retry_button'),
        );

      case CityAvailabilityStatus.permissionDeniedForever:
        return _infoLayout(
          context: context,
          icon: Icons.location_off_rounded,
          iconColor: AppColors.error,
          title: t.t('city_gate.permission_denied_title'),
          message: t.t('city_gate.permission_denied_forever_message'),
          primaryButtonLabel: t.t('city_gate.open_settings_button'),
          onPrimaryPressed: () => Geolocator.openAppSettings(),
          secondaryButtonLabel: t.t('city_gate.retry_button'),
        );

      case CityAvailabilityStatus.error:
        return _infoLayout(
          context: context,
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          title: t.t('city_gate.title'),
          message: t.t('city_gate.error_message'),
          primaryButtonLabel: t.t('city_gate.retry_button'),
        );

      case CityAvailabilityStatus.checking:
      case CityAvailabilityStatus.unknown:
        return [
          const SizedBox(height: 40),
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          const SizedBox(height: 16),
          Text(
            t.t('city_gate.checking'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ];

      case CityAvailabilityStatus.outOfZone:
      case CityAvailabilityStatus.available:
        return _outOfZoneLayout(context: context, t: t, languageCode: languageCode);
    }
  }

  List<Widget> _outOfZoneLayout({
    required BuildContext context,
    required AppLocalizations t,
    required String languageCode,
  }) {
    final activeCityNames = kActiveServiceZones
        .map((z) => z.localizedName(languageCode))
        .join(', ');
    final upcoming = kUpcomingServiceZones;

    return [
      Icon(Icons.map_outlined, size: 88, color: AppColors.primary),
      const SizedBox(height: 24),
      Text(
        t.t('city_gate.title'),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        t.t('city_gate.message', params: {'cities': activeCityNames}),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        textAlign: TextAlign.center,
      ),
      if (upcoming.isNotEmpty) ...[
        const SizedBox(height: 28),
        Text(
          t.t('city_gate.coming_soon_label'),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: upcoming
              .map(
                (zone) => Chip(
                  label: Text(zone.localizedName(languageCode)),
                  backgroundColor: AppColors.primarySurface,
                  labelStyle: const TextStyle(color: AppColors.primaryDark),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
      const SizedBox(height: 32),
      ElevatedButton.icon(
        onPressed: () =>
            context.read<CityAvailabilityProvider>().checkAvailability(),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(t.t('city_gate.retry_button')),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ];
  }

  List<Widget> _infoLayout({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String primaryButtonLabel,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
  }) {
    return [
      Icon(icon, size: 80, color: iconColor),
      const SizedBox(height: 24),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed:
            onPrimaryPressed ??
            () => context.read<CityAvailabilityProvider>().checkAvailability(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(primaryButtonLabel),
      ),
      if (secondaryButtonLabel != null) ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              context.read<CityAvailabilityProvider>().checkAvailability(),
          child: Text(secondaryButtonLabel),
        ),
      ],
    ];
  }
}
