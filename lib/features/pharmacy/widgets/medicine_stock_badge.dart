import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';

/// Small in-stock / out-of-stock indicator used on medicine cards, placed in
/// the space under the medicine name.
class MedicineStockBadge extends StatelessWidget {
  final PharmacyModel medicine;

  const MedicineStockBadge({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inStock = medicine.inStock;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: inStock ? AppColors.success : AppColors.warning,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          inStock
              ? l10n.t('pharmacy.in_stock_short')
              : l10n.t('pharmacy.out_of_stock_short'),
          style: AppTextStyles.labelSmall.copyWith(
            color: inStock ? AppColors.success : AppColors.warning,
          ),
        ),
      ],
    );
  }
}
