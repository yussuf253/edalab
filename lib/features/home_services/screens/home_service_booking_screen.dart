import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class HomeServiceBookingScreen extends StatefulWidget {
  final String providerId;
  const HomeServiceBookingScreen({super.key, required this.providerId});

  @override
  State<HomeServiceBookingScreen> createState() =>
      _HomeServiceBookingScreenState();
}

class _HomeServiceBookingScreenState extends State<HomeServiceBookingScreen> {
  static const String _zoneDispatchProviderId = 'house-help-zone';
  int _selectedDate = 1;
  int _selectedTime = 1;
  int _selectedService = 0;
  int _selectedAddress = 0;
  int _selectedHouseHelpPlan = 0;
  int _selectedHouseHelpShift = 0;
  int _selectedHouseHelpHomeSize = 0;
  int _selectedHouseHelpUrgency = 1;
  bool _houseHelpBringSupplies = false;
  HomeServiceProviderModel? _provider;
  List<HomeServiceProviderModel> _zonePoolProviders = const [];
  bool _isLoading = true;
  bool _didInitializeAddress = false;

  final _times = ['09:00', '10:00', '11:00', '02:00', '03:00', '04:00'];

  final _houseHelpPlans = const [
    'One-time job',
    'Daily recurring',
    'Weekly recurring',
  ];

  final _houseHelpShiftOptions = const [
    ('2 hours', 1.0),
    ('4 hours', 1.8),
    ('8 hours', 3.2),
  ];

  final _houseHelpHomeSizes = const ['F2', 'F3', 'F4'];
  final _houseHelpUrgency = const ['Within 30 min', 'Scheduled slot'];

  bool get _isZoneDispatchRoute => widget.providerId == _zoneDispatchProviderId;

  bool _isHouseHelpProvider(HomeServiceProviderModel provider) {
    final slug = (provider.categorySlug ?? '').toLowerCase();
    final name = (provider.categoryName ?? '').toLowerCase();
    final title = provider.title.toLowerCase();
    final services = provider.services.join(' ').toLowerCase();
    return slug.contains('house-help') ||
        slug.contains('house_help') ||
        slug.contains('househelp') ||
        slug.contains('maid') ||
        name.contains('house help') ||
        name.contains('maid') ||
        title.contains('house help') ||
        title.contains('maid') ||
        services.contains('house help') ||
        services.contains('maid');
  }

  bool _isInstantArrivalLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('schedule')) return false;
    return normalized.contains('instant') ||
        normalized.contains('now') ||
        normalized.contains('15') ||
        normalized.contains('30');
  }

  HomeServiceProviderModel _buildZoneDispatchProvider(
    List<HomeServiceProviderModel> providers,
  ) {
    final primary = providers.isNotEmpty ? providers.first : null;
    final minStartingPrice = providers.isEmpty
        ? 25.0
        : providers
              .map((provider) => provider.startingPrice)
              .reduce((left, right) => left < right ? left : right);
    final unionServices = providers
        .expand((provider) => provider.services)
        .map((service) => service.trim())
        .where((service) => service.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return HomeServiceProviderModel(
      id: _zoneDispatchProviderId,
      categoryId: primary?.categoryId ?? 'hs-house-help',
      categoryName: primary?.categoryName ?? 'House Help',
      categorySlug: primary?.categorySlug ?? 'house-help',
      categoryIconKey: primary?.categoryIconKey ?? 'house_help',
      categoryColorHex: primary?.categoryColorHex ?? '#1A9A77',
      name: 'House Help Dispatch',
      title: 'Nearest available helper',
      rating: providers.isEmpty
          ? 0
          : providers
                .map((provider) => provider.rating)
                .reduce((left, right) => left > right ? left : right),
      reviewCount: providers.fold<int>(
        0,
        (count, provider) => count + provider.reviewCount,
      ),
      startingPrice: minStartingPrice,
      isAvailable: true,
      isVerified: true,
      services: unionServices,
      bookingModes: const ['Home Visit'],
      availability: providers.isEmpty
          ? const <String, dynamic>{}
          : providers.first.availability,
    );
  }

  Map<String, List<String>> _houseHelpConfigFromProviders(
    List<HomeServiceProviderModel> providers,
  ) {
    final bookingTypes = <String>{};
    final shiftDurations = <String>{};
    final homeSizes = <String>{};
    final arrivalTargets = <String>{};
    final supplyModes = <String>{};

    for (final provider in providers) {
      final config = provider.availability['houseHelpConfig'];
      if (config is! Map) continue;
      final map = Map<String, dynamic>.from(config);
      for (final value in (map['bookingTypes'] as List<dynamic>? ?? const [])) {
        final text = value.toString().trim();
        if (text.isNotEmpty) bookingTypes.add(text);
      }
      for (final value
          in (map['shiftDurations'] as List<dynamic>? ?? const [])) {
        final text = value.toString().trim();
        if (text.isNotEmpty) shiftDurations.add(text);
      }
      for (final value in (map['homeSizes'] as List<dynamic>? ?? const [])) {
        final text = value.toString().trim();
        if (text.isNotEmpty) homeSizes.add(text);
      }
      for (final value
          in (map['arrivalTargets'] as List<dynamic>? ?? const [])) {
        final text = value.toString().trim();
        if (text.isNotEmpty) arrivalTargets.add(text);
      }
      for (final value in (map['supplyModes'] as List<dynamic>? ?? const [])) {
        final text = value.toString().trim();
        if (text.isNotEmpty) supplyModes.add(text);
      }
    }

    return {
      'bookingTypes': bookingTypes.isEmpty
          ? [..._houseHelpPlans]
          : bookingTypes.toList(growable: false),
      'shiftDurations': shiftDurations.isEmpty
          ? _houseHelpShiftOptions
                .map((entry) => entry.$1)
                .toList(growable: false)
          : shiftDurations.toList(growable: false),
      'homeSizes': homeSizes.isEmpty
          ? [..._houseHelpHomeSizes]
          : homeSizes.toList(growable: false),
      'arrivalTargets': arrivalTargets.isEmpty
          ? [..._houseHelpUrgency]
          : arrivalTargets.toList(growable: false),
      'supplyModes': supplyModes.isEmpty
          ? const ['Customer supplies', 'Provider supplies']
          : supplyModes.toList(growable: false),
    };
  }

  List<DateTime> get _dateOptions {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return List<DateTime>.generate(
      6,
      (index) => start.add(Duration(days: index + 1)),
      growable: false,
    );
  }

  static const List<String> _weekdayShortNames = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String _weekdayShortLabel(DateTime date) =>
      _weekdayShortNames[date.weekday - 1];

  String _dayTwoDigits(DateTime date) => date.day.toString().padLeft(2, '0');

  String _monthTwoDigits(DateTime date) =>
      date.month.toString().padLeft(2, '0');

  String _summaryDateLabel(DateTime date) =>
      '${_weekdayShortLabel(date)}, ${_dayTwoDigits(date)}/${_monthTwoDigits(date)}/${date.year}';

  String _isoDateLabel(DateTime date) =>
      '${date.year}-${_monthTwoDigits(date)}-${_dayTwoDigits(date)}';

  String _normalizeServiceOption(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _houseHelpServiceOptions(List<String> options) {
    final filtered = options.toList(growable: true);
    final hasRoomCleaning = filtered.any((option) {
      final normalized = _normalizeServiceOption(option);
      return normalized == 'room clean' ||
          normalized == 'room cleaning' ||
          normalized == 'quick room cleaning' ||
          normalized == 'room tidying';
    });
    if (!hasRoomCleaning) {
      filtered.insert(0, 'Room cleaning');
    }
    final hasFloorCleaning = filtered.any((option) {
      final normalized = _normalizeServiceOption(option);
      return normalized == 'floor clean' || normalized == 'floor cleaning';
    });
    if (!hasFloorCleaning) {
      filtered.add('Floor cleaning');
    }
    return filtered;
  }

  double _shiftMultiplierFromLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('8')) return 3.2;
    if (normalized.contains('4')) return 1.8;
    if (normalized.contains('2')) return 1.0;
    return 1.0;
  }

  double _estimateHouseHelpPrice(
    HomeServiceProviderModel provider, {
    required String selectedShiftLabel,
    required int selectedHomeSizeIndex,
    required int selectedPlanIndex,
    required bool providerSupplies,
  }) {
    final basePrice = provider.startingPrice;
    final shiftMultiplier = _shiftMultiplierFromLabel(selectedShiftLabel);
    const sizeMultipliers = [1.0, 1.15, 1.3];
    const planMultipliers = [1.0, 0.92, 0.95];
    final safeHomeSizeIndex = selectedHomeSizeIndex.clamp(
      0,
      sizeMultipliers.length - 1,
    );
    final safePlanIndex = selectedPlanIndex.clamp(
      0,
      planMultipliers.length - 1,
    );
    final sizeMultiplier = sizeMultipliers[safeHomeSizeIndex];
    final planMultiplier = planMultipliers[safePlanIndex];
    final suppliesFee = providerSupplies ? 5.0 : 0.0;
    final total =
        basePrice * shiftMultiplier * sizeMultiplier * planMultiplier +
        suppliesFee;
    return double.parse(total.toStringAsFixed(2));
  }

  String _formatAmount(double amount) {
    final rounded = amount.roundToDouble();
    if ((amount - rounded).abs() < 0.01) {
      return rounded.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  String _localizedHouseHelpPlanLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized.contains('daily')) {
      return l10n.t('home_service_booking.house_help_plan_daily');
    }
    if (normalized.contains('weekly')) {
      return l10n.t('home_service_booking.house_help_plan_weekly');
    }
    if (normalized.contains('one') ||
        normalized.contains('single') ||
        normalized.contains('once')) {
      return l10n.t('home_service_booking.house_help_plan_one_time');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  String _localizedHouseHelpShiftLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized.contains('8')) {
      return l10n.t('home_service_booking.house_help_shift_8h');
    }
    if (normalized.contains('4')) {
      return l10n.t('home_service_booking.house_help_shift_4h');
    }
    if (normalized.contains('2')) {
      return l10n.t('home_service_booking.house_help_shift_2h');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  String _localizedHouseHelpHomeSizeLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized == 'f2') {
      return l10n.t('home_service_booking.house_help_home_size_small');
    }
    if (normalized == 'f3') {
      return l10n.t('home_service_booking.house_help_home_size_medium');
    }
    if (normalized == 'f4') {
      return l10n.t('home_service_booking.house_help_home_size_large');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  String _localizedHouseHelpArrivalLabel(String value, AppLocalizations l10n) {
    final normalized = value.toLowerCase();
    if (normalized.contains('30')) {
      return l10n.t('home_service_booking.house_help_arrival_30');
    }
    if (normalized.contains('scheduled')) {
      return l10n.t('home_service_booking.house_help_arrival_scheduled');
    }
    return l10n.homeServiceDynamicLabel(value);
  }

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    try {
      if (_isZoneDispatchRoute) {
        final response = await ApiClient.get(
          '/catalog/home-service-providers',
          forceRefresh: true,
        );
        final providers = (response as List<dynamic>)
            .map(
              (entry) => HomeServiceProviderModel.fromApi(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .where(_isHouseHelpProvider)
            .where((provider) => provider.isAvailable)
            .toList(growable: false);
        if (!mounted) return;
        setState(() {
          _zonePoolProviders = providers;
          _provider = _buildZoneDispatchProvider(providers);
          _isLoading = false;
        });
        return;
      }

      final response = await ApiClient.get(
        '/catalog/home-service-providers/${widget.providerId}',
        forceRefresh: true,
      );
      if (!mounted) return;
      final provider = HomeServiceProviderModel.fromApi(
        Map<String, dynamic>.from(response as Map),
      );
      setState(() {
        _provider = provider;
        _zonePoolProviders = [provider];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeAddress) return;
    final addresses = context.read<AuthProvider>().user?.addresses ?? const [];
    final defaultIndex = addresses.indexWhere((address) => address.isDefault);
    _selectedAddress = defaultIndex >= 0 ? defaultIndex : 0;
    _didInitializeAddress = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = _provider;
    final auth = context.watch<AuthProvider>();
    final addresses = auth.user?.addresses ?? const [];
    final selectedAddress = addresses.isNotEmpty
        ? addresses[_selectedAddress.clamp(0, addresses.length - 1)]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('home_service_booking.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isLoading || provider == null
            ? const AppShimmer(
                child: Column(
                  children: [
                    ShimmerBlock(
                      width: double.infinity,
                      height: 84,
                      radius: 16,
                    ),
                    SizedBox(height: 24),
                    ShimmerBlock(
                      width: double.infinity,
                      height: 160,
                      radius: 16,
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final isHouseHelp = _isHouseHelpProvider(provider);
                      final houseHelpProviderPool = _isZoneDispatchRoute
                          ? _zonePoolProviders
                          : [provider];
                      final houseHelpConfig = isHouseHelp
                          ? _houseHelpConfigFromProviders(houseHelpProviderPool)
                          : const <String, List<String>>{};
                      final houseHelpPlanOptionsRaw =
                          houseHelpConfig['bookingTypes'] ?? _houseHelpPlans;
                      final houseHelpShiftOptionsRaw =
                          houseHelpConfig['shiftDurations'] ??
                          _houseHelpShiftOptions
                              .map((entry) => entry.$1)
                              .toList(growable: false);
                      final houseHelpHomeSizeOptionsRaw =
                          houseHelpConfig['homeSizes'] ?? _houseHelpHomeSizes;
                      final houseHelpArrivalOptionsRaw =
                          houseHelpConfig['arrivalTargets'] ??
                          _houseHelpUrgency;
                      final selectedHouseHelpPlan = _selectedHouseHelpPlan
                          .clamp(0, houseHelpPlanOptionsRaw.length - 1);
                      final selectedHouseHelpShift = _selectedHouseHelpShift
                          .clamp(0, houseHelpShiftOptionsRaw.length - 1);
                      final selectedHouseHelpHomeSize =
                          _selectedHouseHelpHomeSize.clamp(
                            0,
                            houseHelpHomeSizeOptionsRaw.length - 1,
                          );
                      final selectedHouseHelpArrival = _selectedHouseHelpUrgency
                          .clamp(0, houseHelpArrivalOptionsRaw.length - 1);
                      final providerServiceOptionsRaw =
                          provider.services.isNotEmpty
                          ? provider.services
                          : [provider.categoryName ?? provider.title];
                      final serviceOptionsRaw = isHouseHelp
                          ? _houseHelpServiceOptions(providerServiceOptionsRaw)
                          : providerServiceOptionsRaw;
                      final serviceOptions = serviceOptionsRaw
                          .map((option) => l10n.homeServiceDynamicLabel(option))
                          .toList(growable: false);
                      final selectedService =
                          _selectedService < serviceOptionsRaw.length
                          ? _selectedService
                          : 0;
                      final selectedDateIndex = _selectedDate.clamp(
                        0,
                        _dateOptions.length - 1,
                      );
                      final selectedDateValue = _dateOptions[selectedDateIndex];
                      final selectedArrivalOption = isHouseHelp
                          ? houseHelpArrivalOptionsRaw[selectedHouseHelpArrival]
                          : '';
                      final isInstantHouseHelp =
                          isHouseHelp &&
                          _isInstantArrivalLabel(selectedArrivalOption);
                      final serviceFee = isHouseHelp
                          ? _estimateHouseHelpPrice(
                              provider,
                              selectedShiftLabel:
                                  houseHelpShiftOptionsRaw[selectedHouseHelpShift],
                              selectedHomeSizeIndex: selectedHouseHelpHomeSize,
                              selectedPlanIndex: selectedHouseHelpPlan,
                              providerSupplies: _houseHelpBringSupplies,
                            )
                          : provider.startingPrice;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('home_service_booking.choose_service'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(serviceOptions.length, (
                              index,
                            ) {
                              final selected = selectedService == index;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedService = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.homeServices
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: selected
                                        ? null
                                        : Border.all(
                                            color: AppColors.lightGrey,
                                          ),
                                  ),
                                  child: Text(
                                    serviceOptions[index],
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: selected
                                          ? AppColors.white
                                          : AppColors.dark,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 24),
                          if (isHouseHelp) ...[
                            Text(
                              l10n.t(
                                'home_service_booking.house_help_format_title',
                              ),
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.lightGrey),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t(
                                      'home_service_booking.house_help_booking_type',
                                    ),
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      houseHelpPlanOptionsRaw.length,
                                      (index) => _BookingOptionChip(
                                        label: _localizedHouseHelpPlanLabel(
                                          houseHelpPlanOptionsRaw[index],
                                          l10n,
                                        ),
                                        selected:
                                            selectedHouseHelpPlan == index,
                                        onTap: () => setState(
                                          () => _selectedHouseHelpPlan = index,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.t(
                                      'home_service_booking.house_help_shift_duration',
                                    ),
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      houseHelpShiftOptionsRaw.length,
                                      (index) => _BookingOptionChip(
                                        label: _localizedHouseHelpShiftLabel(
                                          houseHelpShiftOptionsRaw[index],
                                          l10n,
                                        ),
                                        selected:
                                            selectedHouseHelpShift == index,
                                        onTap: () => setState(
                                          () => _selectedHouseHelpShift = index,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.t(
                                      'home_service_booking.house_help_home_size',
                                    ),
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      houseHelpHomeSizeOptionsRaw.length,
                                      (index) => _BookingOptionChip(
                                        label: _localizedHouseHelpHomeSizeLabel(
                                          houseHelpHomeSizeOptionsRaw[index],
                                          l10n,
                                        ),
                                        selected:
                                            selectedHouseHelpHomeSize == index,
                                        onTap: () => setState(
                                          () => _selectedHouseHelpHomeSize =
                                              index,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.t(
                                      'home_service_booking.house_help_arrival_target',
                                    ),
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      houseHelpArrivalOptionsRaw.length,
                                      (index) => _BookingOptionChip(
                                        label: _localizedHouseHelpArrivalLabel(
                                          houseHelpArrivalOptionsRaw[index],
                                          l10n,
                                        ),
                                        selected:
                                            selectedHouseHelpArrival == index,
                                        onTap: () => setState(
                                          () =>
                                              _selectedHouseHelpUrgency = index,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    value: _houseHelpBringSupplies,
                                    activeThumbColor: AppColors.homeServices,
                                    title: Text(
                                      l10n.t(
                                        'home_service_booking.house_help_bring_supplies',
                                      ),
                                      style: AppTextStyles.labelLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      l10n.t(
                                        'home_service_booking.house_help_supplies_fee',
                                      ),
                                      style: AppTextStyles.caption,
                                    ),
                                    onChanged: (value) => setState(
                                      () => _houseHelpBringSupplies = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (!isInstantHouseHelp) ...[
                            Text(
                              l10n.t('home_service_booking.select_date'),
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _dateOptions.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final selected = _selectedDate == index;
                                  final date = _dateOptions[index];
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedDate = index),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.homeServices
                                            : AppColors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: selected
                                            ? null
                                            : Border.all(
                                                color: AppColors.lightGrey,
                                              ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _weekdayShortLabel(date),
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: selected
                                                      ? Colors.white70
                                                      : AppColors.grey,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _dayTwoDigits(date),
                                            style: AppTextStyles.h4.copyWith(
                                              color: selected
                                                  ? AppColors.white
                                                  : AppColors.dark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.t('home_service_booking.select_time'),
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(_times.length, (index) {
                                final selected = _selectedTime == index;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedTime = index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.homeServices
                                          : AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: selected
                                          ? null
                                          : Border.all(
                                              color: AppColors.lightGrey,
                                            ),
                                    ),
                                    child: Text(
                                      _times[index],
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: selected
                                            ? AppColors.white
                                            : AppColors.dark,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            l10n.t('home_service_booking.service_address'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 12),
                          if (addresses.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.lightGrey),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      l10n.t(
                                        'home_service_booking.no_saved_addresses',
                                      ),
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                  AppButton(
                                    text: context.l10n.t('checkout.add'),
                                    width: 84,
                                    isSmall: true,
                                    onPressed: () =>
                                        context.push('/profile/addresses'),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: addresses.asMap().entries.map((entry) {
                                final index = entry.key;
                                final address = entry.value;
                                final isSelected = _selectedAddress == index;
                                final subtitle = [
                                  address.address,
                                  if ((address.city ?? '').isNotEmpty)
                                    address.city!,
                                  if ((address.zipCode ?? '').isNotEmpty)
                                    address.zipCode!,
                                ].join(', ');

                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedAddress = index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: isSelected
                                          ? Border.all(
                                              color: AppColors.homeServices,
                                              width: 2,
                                            )
                                          : Border.all(
                                              color: AppColors.extraLightGrey,
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.homeServicesBg,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: AppColors.homeServices,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      address.label,
                                                      style: AppTextStyles
                                                          .labelMedium,
                                                    ),
                                                  ),
                                                  if (address.isDefault) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .homeServicesBg,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        l10n.t(
                                                          'home_service_booking.default',
                                                        ),
                                                        style: AppTextStyles
                                                            .labelSmall
                                                            .copyWith(
                                                              color: AppColors
                                                                  .homeServices,
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
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          if (selectedAddress?.latitude != null &&
                              selectedAddress?.longitude != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                height: 168,
                                width: double.infinity,
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      selectedAddress!.latitude!,
                                      selectedAddress.longitude!,
                                    ),
                                    zoom: 15.2,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId(
                                        'selected-address',
                                      ),
                                      position: LatLng(
                                        selectedAddress.latitude!,
                                        selectedAddress.longitude!,
                                      ),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                  mapToolbarEnabled: false,
                                  rotateGesturesEnabled: false,
                                  scrollGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  zoomGesturesEnabled: false,
                                  liteModeEnabled: true,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.homeServicesBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _SummaryRow(
                                  l10n.t('home_service_booking.professional'),
                                  provider.name,
                                ),
                                _SummaryRow(
                                  l10n.t('home_service_booking.service'),
                                  serviceOptions[selectedService],
                                ),
                                if (isHouseHelp)
                                  _SummaryRow(
                                    l10n.t(
                                      'home_service_booking.house_help_summary_booking_format',
                                    ),
                                    _localizedHouseHelpPlanLabel(
                                      houseHelpPlanOptionsRaw[selectedHouseHelpPlan],
                                      l10n,
                                    ),
                                  ),
                                if (isHouseHelp)
                                  _SummaryRow(
                                    l10n.t(
                                      'home_service_booking.house_help_summary_shift',
                                    ),
                                    _localizedHouseHelpShiftLabel(
                                      houseHelpShiftOptionsRaw[selectedHouseHelpShift],
                                      l10n,
                                    ),
                                  ),
                                if (isHouseHelp)
                                  _SummaryRow(
                                    l10n.t(
                                      'home_service_booking.house_help_summary_home_size',
                                    ),
                                    _localizedHouseHelpHomeSizeLabel(
                                      houseHelpHomeSizeOptionsRaw[selectedHouseHelpHomeSize],
                                      l10n,
                                    ),
                                  ),
                                if (isHouseHelp)
                                  _SummaryRow(
                                    l10n.t(
                                      'home_service_booking.house_help_summary_arrival_target',
                                    ),
                                    _localizedHouseHelpArrivalLabel(
                                      houseHelpArrivalOptionsRaw[selectedHouseHelpArrival],
                                      l10n,
                                    ),
                                  ),
                                if (isHouseHelp)
                                  _SummaryRow(
                                    l10n.t(
                                      'home_service_booking.house_help_summary_supplies',
                                    ),
                                    _houseHelpBringSupplies
                                        ? l10n.t(
                                            'home_service_booking.house_help_summary_supplies_provider',
                                          )
                                        : l10n.t(
                                            'home_service_booking.house_help_summary_supplies_customer',
                                          ),
                                  ),
                                if (!isInstantHouseHelp)
                                  _SummaryRow(
                                    l10n.t('home_service_booking.date'),
                                    _summaryDateLabel(selectedDateValue),
                                  ),
                                if (!isInstantHouseHelp)
                                  _SummaryRow(
                                    l10n.t('home_service_booking.time'),
                                    _times[_selectedTime],
                                  ),
                                if (selectedAddress != null)
                                  _SummaryRow(
                                    l10n.t('home_service_booking.address'),
                                    '${selectedAddress.address}${selectedAddress.city != null ? ', ${selectedAddress.city}' : ''}',
                                  ),
                                const Divider(height: 20),
                                _SummaryRow(
                                  isHouseHelp
                                      ? l10n.t(
                                          'home_service_booking.house_help_estimated_first_visit',
                                        )
                                      : l10n.t('home_service_booking.fee'),
                                  '\$${_formatAmount(serviceFee)}',
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: l10n.t(
                              'home_service_booking.confirm_booking',
                            ),
                            color: AppColors.homeServices,
                            onPressed: () async {
                              final allowed = await requireLoggedIn(
                                context,
                                message: l10n.t(
                                  'home_service_booking.login_required',
                                ),
                              );
                              if (!context.mounted || !allowed) return;
                              if (_isZoneDispatchRoute &&
                                  _zonePoolProviders.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No house-help providers are available in your zone right now.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (selectedAddress == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.t(
                                        'home_service_booking.select_address',
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final addressText =
                                  '${selectedAddress.address}${selectedAddress.city != null ? ', ${selectedAddress.city}' : ''}';
                              final bookingMetadata = <String, dynamic>{
                                'categorySlug': provider.categorySlug,
                                'providerTitle': provider.title,
                                'serviceName':
                                    serviceOptionsRaw[selectedService],
                                'address': addressText,
                                'addressId': selectedAddress.id,
                                'addressLabel': selectedAddress.label,
                                if (!_isZoneDispatchRoute)
                                  'providerId': provider.id,
                                if (_isZoneDispatchRoute) ...{
                                  'dispatchMode': 'ZONE_POOL',
                                  'providerPoolIds': _zonePoolProviders
                                      .map((entry) => entry.id)
                                      .toList(growable: false),
                                  'zoneDispatch': true,
                                },
                                if (selectedAddress.latitude != null &&
                                    selectedAddress.longitude != null)
                                  'serviceLocation': {
                                    'latitude': selectedAddress.latitude,
                                    'longitude': selectedAddress.longitude,
                                  },
                              };
                              if (!isInstantHouseHelp) {
                                bookingMetadata['scheduledDate'] =
                                    _isoDateLabel(selectedDateValue);
                                bookingMetadata['timeSlot'] =
                                    _times[_selectedTime];
                              } else {
                                bookingMetadata['dispatchWindow'] =
                                    houseHelpArrivalOptionsRaw[selectedHouseHelpArrival];
                              }
                              if (isHouseHelp) {
                                bookingMetadata['bookingFormat'] = {
                                  'vertical': 'HOUSE_HELP',
                                  'type':
                                      houseHelpPlanOptionsRaw[selectedHouseHelpPlan],
                                  'shift':
                                      houseHelpShiftOptionsRaw[selectedHouseHelpShift],
                                  'homeSize':
                                      houseHelpHomeSizeOptionsRaw[selectedHouseHelpHomeSize],
                                  'arrivalTarget':
                                      houseHelpArrivalOptionsRaw[selectedHouseHelpArrival],
                                  'bringSupplies': _houseHelpBringSupplies,
                                };
                              }
                              final bookingModuleType = isHouseHelp
                                  ? 'HOUSE_HELP'
                                  : 'HOME_SERVICES';
                              final orderItem = <String, dynamic>{
                                if (!_isZoneDispatchRoute) 'id': provider.id,
                                'name': serviceOptions[selectedService],
                                'brand': provider.name,
                                'price': serviceFee,
                                'quantity': 1,
                                'metadata': bookingMetadata,
                              };
                              final order = await ApiClient.post('/orders', {
                                'userId': auth.user!.id,
                                'moduleType': bookingModuleType,
                                'subtotal': serviceFee,
                                'tax': 0,
                                'deliveryFee': 0,
                                'discount': 0,
                                'total': serviceFee,
                                'notes': '',
                                'items': [orderItem],
                              });
                              if (!context.mounted) return;
                              context.go(
                                '/checkout/success',
                                extra: {
                                  'orderId': order['id'],
                                  'amount': serviceFee,
                                  'payment': l10n.t(
                                    'home_service_booking.pay_on_confirmation',
                                  ),
                                  'delivery': isInstantHouseHelp
                                      ? houseHelpArrivalOptionsRaw[selectedHouseHelpArrival]
                                      : '${_summaryDateLabel(selectedDateValue)}, ${_times[_selectedTime]}',
                                  'moduleName': serviceOptions[selectedService],
                                  'itemCount': 1,
                                  'address': addressText,
                                  'trackingRoute':
                                      '/home-services/booking/${order['id']}',
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _BookingOptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BookingOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.homeServices : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: AppColors.lightGrey),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? AppColors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold
                  ? AppTextStyles.labelLarge
                  : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bold
                  ? AppTextStyles.priceSmall.copyWith(
                      color: AppColors.homeServices,
                    )
                  : AppTextStyles.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
