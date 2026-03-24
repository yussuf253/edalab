import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _methods = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiClient.get('/users/$userId/payment-methods');
      if (!mounted) return;
      setState(() {
        _methods = (response as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefault(String paymentMethodId) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      await ApiClient.patch(
        '/users/$userId/payment-methods/$paymentMethodId/default',
        {},
      );
      await _loadMethods();
    } catch (_) {}
  }

  Future<void> _deleteMethod(String paymentMethodId) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    try {
      await ApiClient.delete('/users/$userId/payment-methods/$paymentMethodId');
      await _loadMethods();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const PaymentMethodsShimmer()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cards', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  if (_methods.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'No saved payment methods yet.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  else
                    ..._methods.map((method) {
                      final color =
                          (method['type']?.toString() ?? '').contains('CARD')
                          ? AppColors.primary
                          : AppColors.secondary;
                      final last4 = method['last4']?.toString() ?? '0000';
                      final month = method['expiryMonth']?.toString() ?? '--';
                      final year = method['expiryYear']?.toString() ?? '--';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  method['brand']?.toString() ??
                                      method['type']?.toString() ??
                                      'Payment',
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                if (method['isDefault'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: AppTextStyles.badge.copyWith(
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '•••• •••• •••• $last4',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Expires $month/$year',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                const Spacer(),
                                if (method['isDefault'] != true)
                                  TextButton(
                                    onPressed: () =>
                                        _setDefault(method['id'].toString()),
                                    child: Text(
                                      'Set default',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () =>
                                      _deleteMethod(method['id'].toString()),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
