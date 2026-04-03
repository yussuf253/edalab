import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/message_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class MedicineDetailScreen extends StatefulWidget {
  final String medicineId;
  const MedicineDetailScreen({super.key, required this.medicineId});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late PharmacyModel _medicine;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _medicine = PharmacyModel.sampleItems.firstWhere(
      (item) => item.id == widget.medicineId,
      orElse: () => PharmacyModel.sampleItems.first,
    );
    _loadMedicine();
  }

  Future<void> _loadMedicine() async {
    try {
      final response = await ApiClient.get(
        '/catalog/products/${widget.medicineId}',
      );
      if (!mounted) return;
      setState(() {
        _medicine = PharmacyModel.fromApi(
          Map<String, dynamic>.from(response as Map),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openPharmacyChat() async {
    final sourceBusiness = _medicine.sourceBusiness?.trim() ?? '';
    if (sourceBusiness.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pharmacy contact is not available for this item yet.'),
        ),
      );
      return;
    }

    await openConversation(
      context,
      moduleType: 'PHARMACY',
      entityType: 'SHOP',
      entityId: sourceBusiness,
      title: sourceBusiness,
      subtitle: _medicine.category,
      accentColor: '#27AE60',
      metadata: {
        'merchantName': sourceBusiness,
        'sourceBusiness': sourceBusiness,
        'productId': _medicine.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final medicine = _medicine;
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.getModuleItemCount('pharmacy');
    final moduleTotal = cartProvider.getModuleSubtotal('pharmacy');
    final cartItems = cartProvider.getModuleItems('pharmacy');
    final existingCartItem = cartItems.cast<CartItem?>().firstWhere(
      (item) => item?.id == medicine.id,
      orElse: () => null,
    );
    final isInCart = existingCartItem != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                splashRadius: 24,
                constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                padding: const EdgeInsets.all(12),
                onPressed: () => context.push('/pharmacy/cart'),
                icon: const Icon(Icons.shopping_bag_outlined, size: 24),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartItemCount',
                        style: AppTextStyles.badge.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const DetailContentShimmer(
                accentColor: AppColors.pharmacy,
                showHero: false,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.pharmacyBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: AppColors.pharmacy,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(medicine.name, style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text(
                    '${medicine.category} • ${medicine.size}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '\$${medicine.price.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(
                          color: AppColors.pharmacy,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.t('medicine_detail.in_stock'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      if (medicine.requiresPrescription) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.t('medicine_detail.prescription_required'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.t('medicine_detail.description'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medicine.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.t('medicine_detail.dosage'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.pharmacy,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            medicine.dosage,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.t('medicine_detail.warnings'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.t('medicine_detail.warning_text'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: isInCart
            ? GestureDetector(
                onTap: () => context.push('/pharmacy/cart'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pharmacy,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pharmacy.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '$cartItemCount',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.t('medicine_detail.view_cart'),
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      Text(
                        '\$${moduleTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : AppButton(
                text: l10n.t(
                  'medicine_detail.add_to_cart',
                  params: {'amount': medicine.price.toStringAsFixed(2)},
                ),
                color: AppColors.pharmacy,
                onPressed: () {
                  cartProvider.addItem(
                    CartItem(
                      id: medicine.id,
                      name: medicine.name,
                      price: medicine.price,
                      moduleType: 'pharmacy',
                      brand: medicine.category,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
