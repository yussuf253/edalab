import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';

const Map<String, List<String>> _djiboutiCityQuartiers = {
  'Djibouti': [
    'Plateau du Serpent',
    'Quartier 1',
    'Quartier 2',
    'Quartier 3',
    'Quartier 4',
    'Quartier 5',
    'Quartier 6',
    'Quartier 7',
    'Balbala',
    'Haramous',
  ],
  'Ali Sabieh': ['Ali Sabieh Centre', 'Holl-Holl', 'Assamo', 'Ali Addé'],
  'Arta': ['Arta Centre', 'Wea', 'Damerjog', 'Loyada'],
  'Dikhil': ['Dikhil Centre', 'Yoboki', 'As-Eyla', 'Galafi'],
  'Obock': ['Obock Centre', 'Khor Angar', 'Alaili Dadda'],
  'Tadjourah': ['Tadjourah Centre', 'Randa', 'Dorra', 'Balho'],
};

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  IconData _iconForLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('home')) return Icons.home_rounded;
    if (normalized.contains('work') || normalized.contains('office')) {
      return Icons.work_rounded;
    }
    if (normalized.contains('family') ||
        normalized.contains('mom') ||
        normalized.contains('dad')) {
      return Icons.favorite_rounded;
    }
    return Icons.location_on_rounded;
  }

  Future<void> _showAddressSheet(
    BuildContext context, {
    AddressModel? address,
  }) async {
    final l10n = context.l10n;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('addresses.login_manage')),
          action: SnackBarAction(
            label: l10n.t('addresses.login'),
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddressSheet(address: address);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authProvider = context.watch<AuthProvider>();
    final addresses = authProvider.user?.addresses ?? const [];
    final isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('addresses.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: addresses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.location_off_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isLoggedIn
                          ? l10n.t('addresses.empty_logged_in_title')
                          : l10n.t('addresses.empty_logged_out_title'),
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLoggedIn
                          ? l10n.t('addresses.empty_logged_in_subtitle')
                          : l10n.t('addresses.empty_logged_out_subtitle'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                final subtitle = [
                  if ((address.city ?? '').isNotEmpty) address.city!,
                  if ((address.quartier ?? '').isNotEmpty) address.quartier!,
                ].join(', ');
                final locationSubtitle =
                    address.latitude != null && address.longitude != null
                    ? '${address.latitude!.toStringAsFixed(5)}, ${address.longitude!.toStringAsFixed(5)}'
                    : null;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: address.isDefault
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForLabel(address.label),
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    address.label,
                                    style: AppTextStyles.labelLarge,
                                  ),
                                ),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l10n.t('addresses.default'),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: AppTextStyles.caption,
                              maxLines: 2,
                            ),
                            if (locationSubtitle != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.my_location_rounded,
                                    size: 12,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locationSubtitle,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.mediumGrey,
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _showAddressSheet(context, address: address);
                            return;
                          }

                          if (value == 'default') {
                            final success = await context
                                .read<AuthProvider>()
                                .setDefaultAddress(address.id);
                            if (!context.mounted || success) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  authProvider.errorMessage ??
                                      l10n.t('addresses.failed_default'),
                                ),
                              ),
                            );
                            return;
                          }

                          if (value == 'delete') {
                            final success = await context
                                .read<AuthProvider>()
                                .deleteAddress(address.id);
                            if (!context.mounted || success) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  authProvider.errorMessage ??
                                      l10n.t('addresses.failed_delete'),
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.t('addresses.edit')),
                          ),
                          if (!address.isDefault)
                            PopupMenuItem(
                              value: 'default',
                              child: Text(l10n.t('addresses.set_default')),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.t('addresses.delete')),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressSheet(context),
        backgroundColor: AppColors.primary,
        label: Text(
          isLoggedIn
              ? l10n.t('addresses.add')
              : l10n.t('addresses.login_required'),
          style: const TextStyle(color: AppColors.white),
        ),
        icon: Icon(
          isLoggedIn ? Icons.add_rounded : Icons.lock_outline_rounded,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  final AddressModel? address;

  const _AddressSheet({this.address});

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late final TextEditingController _labelController;
  late bool _isDefault;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;
  String? _selectedCity;
  String? _selectedQuartier;
  double? _latitude;
  double? _longitude;
  String? _resolvedLocationLabel;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _selectedCity = _normalizeCity(widget.address?.city);
    _selectedQuartier = _normalizeQuartier(
      widget.address?.quartier,
      _selectedCity,
    );
    _latitude = widget.address?.latitude;
    _longitude = widget.address?.longitude;
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  List<String> get _cities =>
      _djiboutiCityQuartiers.keys.toList(growable: false);

  String? _normalizeCity(String? candidate) {
    final value = candidate?.trim() ?? '';
    if (value.isEmpty) return null;
    for (final city in _cities) {
      if (city.toLowerCase() == value.toLowerCase()) {
        return city;
      }
    }
    return null;
  }

  List<String> _quartiersForCity(String? city) {
    if (city == null || city.isEmpty) return const <String>[];
    final quartiers = List<String>.from(
      _djiboutiCityQuartiers[city] ?? const [],
    );
    final existing = widget.address?.quartier?.trim() ?? '';
    final addressCity = widget.address?.city?.trim() ?? '';
    final shouldKeepExisting = addressCity.toLowerCase() == city.toLowerCase();
    if (shouldKeepExisting &&
        existing.isNotEmpty &&
        !quartiers.any(
          (entry) => entry.toLowerCase() == existing.toLowerCase(),
        )) {
      quartiers.add(existing);
    }
    return quartiers;
  }

  String? _normalizeQuartier(String? candidate, String? city) {
    final value = candidate?.trim() ?? '';
    if (value.isEmpty) return null;
    final quartiers = _quartiersForCity(city);
    for (final quartier in quartiers) {
      if (quartier.toLowerCase() == value.toLowerCase()) {
        return quartier;
      }
    }
    return null;
  }

  String _locationSummaryText(AppLocalizations l10n) {
    if (_latitude == null || _longitude == null) {
      return l10n.t('addresses.location_not_set');
    }

    final coordinates =
        '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}';
    final label = _resolvedLocationLabel?.trim() ?? '';
    if (label.isEmpty) return coordinates;
    return '$label\n$coordinates';
  }

  String? _inferCity(UserLocationData location) {
    final haystack = '${location.title} ${location.subtitle}'.toLowerCase();
    for (final city in _cities) {
      if (haystack.contains(city.toLowerCase())) {
        return city;
      }
    }
    return null;
  }

  String? _inferQuartier({
    required UserLocationData location,
    required String? city,
  }) {
    final quartiers = _quartiersForCity(city);
    if (quartiers.isEmpty) return null;
    final haystack = '${location.title} ${location.subtitle}'.toLowerCase();
    for (final quartier in quartiers) {
      if (haystack.contains(quartier.toLowerCase())) {
        return quartier;
      }
    }
    return null;
  }

  Future<void> _useCurrentLocation() async {
    final l10n = context.l10n;
    setState(() => _isFetchingLocation = true);

    final locationProvider = context.read<UserLocationProvider>();
    final success = await locationProvider.ensureCurrentLocation(
      requestPermission: true,
    );

    if (!mounted) return;
    if (!success || locationProvider.location == null) {
      setState(() => _isFetchingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('addresses.location_failed'))),
      );
      return;
    }

    final location = locationProvider.location!;
    final inferredCity = _inferCity(location);
    final inferredQuartier = _inferQuartier(
      location: location,
      city: inferredCity ?? _selectedCity,
    );

    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
      _resolvedLocationLabel = location.title;
      if (inferredCity != null) {
        _selectedCity = inferredCity;
      }
      if (inferredQuartier != null) {
        _selectedQuartier = inferredQuartier;
      }
      _isFetchingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cityItems = _cities.toSet().toList(growable: false);
    final selectedCityValue = cityItems.contains(_selectedCity)
        ? _selectedCity
        : null;
    final quartierItems = _quartiersForCity(
      selectedCityValue,
    ).toSet().toList(growable: false);
    final selectedQuartierValue = quartierItems.contains(_selectedQuartier)
        ? _selectedQuartier
        : null;

    if (_selectedCity != selectedCityValue ||
        _selectedQuartier != selectedQuartierValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCity = selectedCityValue;
          _selectedQuartier = selectedQuartierValue;
        });
      });
    }

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.address == null
                          ? l10n.t('addresses.sheet_add')
                          : l10n.t('addresses.sheet_edit'),
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _labelController,
                      decoration: InputDecoration(
                        labelText: l10n.t('addresses.label'),
                        prefixIcon: const Icon(Icons.label_outline_rounded),
                        hintText: l10n.t('addresses.label_hint'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey('city-$selectedCityValue'),
                      initialValue: selectedCityValue,
                      items: cityItems
                          .map(
                            (city) => DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: l10n.t('addresses.city'),
                        hintText: l10n.t('addresses.city_hint'),
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                          final currentQuartier = _selectedQuartier;
                          if (currentQuartier == null) return;
                          final valid = _quartiersForCity(value).any(
                            (entry) =>
                                entry.toLowerCase() ==
                                currentQuartier.toLowerCase(),
                          );
                          if (!valid) {
                            _selectedQuartier = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'quartier-$selectedCityValue-$selectedQuartierValue-${quartierItems.length}',
                      ),
                      initialValue: selectedQuartierValue,
                      items: quartierItems
                          .map(
                            (quartier) => DropdownMenuItem<String>(
                              value: quartier,
                              child: Text(quartier),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: l10n.t('addresses.quartier'),
                        hintText: l10n.t('addresses.quartier_hint'),
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                      onChanged: selectedCityValue == null
                          ? null
                          : (value) =>
                                setState(() => _selectedQuartier = value),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.extraLightGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('addresses.location'),
                            style: AppTextStyles.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _locationSummaryText(l10n),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isFetchingLocation
                                  ? null
                                  : _useCurrentLocation,
                              icon: _isFetchingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                l10n.t('addresses.use_current_location'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _isDefault,
                      onChanged: (value) => setState(() => _isDefault = value),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.t('addresses.set_default_switch')),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                widget.address == null
                                    ? l10n.t('addresses.sheet_add')
                                    : l10n.t('addresses.save'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final selectedCity = _selectedCity;
    final selectedQuartier = _selectedQuartier;
    final label = _labelController.text.trim();

    if (selectedCity == null || selectedCity.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('addresses.invalid_city'))));
      return;
    }
    if (selectedQuartier == null || selectedQuartier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('addresses.invalid_quartier'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = widget.address == null
        ? await auth.addAddress(
            label: label.isEmpty ? selectedQuartier : label,
            address: selectedQuartier,
            city: selectedCity,
            quartier: selectedQuartier,
            latitude: _latitude,
            longitude: _longitude,
            isDefault: _isDefault,
          )
        : await auth.updateAddress(
            addressId: widget.address!.id,
            label: label.isEmpty ? selectedQuartier : label,
            address: selectedQuartier,
            city: selectedCity,
            quartier: selectedQuartier,
            latitude: _latitude,
            longitude: _longitude,
            isDefault: _isDefault,
          );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.errorMessage ?? l10n.t('addresses.failed_save')),
      ),
    );
  }
}
