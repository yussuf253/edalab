import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
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
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  int _selectedDate = 1;
  int _selectedTime = 1;
  int _selectedMode = 0;
  int _selectedService = 0;
  HomeServiceProviderModel? _provider;
  bool _isLoading = true;

  final _dates = [
    ('Mon', '22'),
    ('Tue', '23'),
    ('Wed', '24'),
    ('Thu', '25'),
    ('Fri', '26'),
    ('Sat', '27'),
  ];

  final _times = ['09:00', '10:00', '11:00', '02:00', '03:00', '04:00'];

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    try {
      final response = await ApiClient.get(
        '/catalog/home-service-providers/${widget.providerId}',
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _provider = HomeServiceProviderModel.fromApi(
          Map<String, dynamic>.from(response as Map),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Service'),
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
                      final serviceOptions = provider.services.isNotEmpty
                          ? provider.services
                          : [provider.categoryName ?? provider.title];
                      final modeOptions = provider.bookingModes.isNotEmpty
                          ? provider.bookingModes
                          : [provider.primaryMode];
                      final selectedService =
                          _selectedService < serviceOptions.length
                          ? _selectedService
                          : 0;
                      final selectedMode = _selectedMode < modeOptions.length
                          ? _selectedMode
                          : 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.homeServicesBg,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    provider.categoryIcon,
                                    color: AppColors.homeServices,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.name,
                                        style: AppTextStyles.labelLarge,
                                      ),
                                      Text(
                                        provider.title,
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Choose Service', style: AppTextStyles.h4),
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
                                    style: AppTextStyles.labelSmall.copyWith(
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
                          Text('Service Mode', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(
                              modeOptions.take(3).length,
                              (index) {
                                final mode = modeOptions[index];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: index < 2 ? 12 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedMode = index),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selectedMode == index
                                              ? AppColors.homeServices
                                              : AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: selectedMode == index
                                              ? null
                                              : Border.all(
                                                  color: AppColors.lightGrey,
                                                ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            mode,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color: selectedMode == index
                                                      ? AppColors.white
                                                      : AppColors.dark,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Select Date', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _dates.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final selected = _selectedDate == index;
                                final date = _dates[index];
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDate = index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
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
                                          date.$1,
                                          style: AppTextStyles.caption.copyWith(
                                            color: selected
                                                ? Colors.white70
                                                : AppColors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          date.$2,
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
                          Text('Select Time', style: AppTextStyles.h4),
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
                          const SizedBox(height: 24),
                          Text('Service Address', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your address',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Notes (optional)', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Add any service instructions...',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.homeServicesBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _SummaryRow('Professional', provider.name),
                                _SummaryRow(
                                  'Service',
                                  serviceOptions[selectedService],
                                ),
                                _SummaryRow(
                                  'Date',
                                  '${_dates[_selectedDate].$1}, Mar ${_dates[_selectedDate].$2}, 2026',
                                ),
                                _SummaryRow('Time', _times[_selectedTime]),
                                _SummaryRow('Mode', modeOptions[selectedMode]),
                                const Divider(height: 20),
                                _SummaryRow(
                                  'Fee',
                                  '\$${provider.startingPrice.toInt()}',
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'Confirm Booking',
                            color: AppColors.homeServices,
                            onPressed: () async {
                              final auth = context.read<AuthProvider>();
                              final allowed = await requireLoggedIn(
                                context,
                                message:
                                    'Please log in to book a home service.',
                              );
                              if (!context.mounted || !allowed) return;

                              final address = _addressController.text.trim();
                              if (address.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter your address.'),
                                  ),
                                );
                                return;
                              }

                              final order = await ApiClient.post('/orders', {
                                'userId': auth.user!.id,
                                'moduleType': 'HOME_SERVICES',
                                'subtotal': provider.startingPrice,
                                'tax': 0,
                                'deliveryFee': 0,
                                'discount': 0,
                                'total': provider.startingPrice,
                                'notes': _notesController.text.trim(),
                                'items': [
                                  {
                                    'id': provider.id,
                                    'name': serviceOptions[selectedService],
                                    'brand': provider.name,
                                    'price': provider.startingPrice,
                                    'quantity': 1,
                                    'metadata': {
                                      'providerId': provider.id,
                                      'categorySlug': provider.categorySlug,
                                      'providerTitle': provider.title,
                                      'serviceName':
                                          serviceOptions[selectedService],
                                      'scheduledDate':
                                          '2026-03-${_dates[_selectedDate].$2}',
                                      'timeSlot': _times[_selectedTime],
                                      'address': address,
                                      'bookingMode': modeOptions[selectedMode],
                                    },
                                  },
                                ],
                              });
                              if (!context.mounted) return;
                              context.go(
                                '/checkout/success',
                                extra: {
                                  'orderId': order['id'],
                                  'amount': provider.startingPrice,
                                  'payment': 'Pay on confirmation',
                                  'delivery': modeOptions[selectedMode],
                                  'moduleName': serviceOptions[selectedService],
                                  'itemCount': 1,
                                  'address': address,
                                  'trackingRoute': '/orders',
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTextStyles.labelLarge
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.priceSmall.copyWith(
                    color: AppColors.homeServices,
                  )
                : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
