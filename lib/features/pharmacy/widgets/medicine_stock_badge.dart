import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';

/// Small availability indicator used on medicine cards, placed in the space
/// under the medicine name. Deliberately shows only "In stock" or
/// "Out of stock" — exact stock quantities are not surfaced to customers.
class MedicineStockBadge extends StatelessWidget {
  final PharmacyModel medicine;

  const MedicineStockBadge({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inStock = medicine.inStock;

    final Color statusColor;
    final String statusText;
    if (!inStock) {
      statusColor = AppColors.warning;
      statusText = l10n.t('pharmacy.out_of_stock_short');
    } else {
      statusColor = AppColors.success;
      statusText = l10n.t('pharmacy.in_stock_short');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(color: statusColor),
          ),
        ),
      ],
    );
  }
}
