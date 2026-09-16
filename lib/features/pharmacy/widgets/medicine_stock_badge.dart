import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';

/// Small in-stock / low-stock / out-of-stock indicator used on medicine
/// cards, placed in the space under the medicine name. When the backend
/// reports a quantity (stockQty in metadata), in-stock items show the exact
/// amount left, e.g. "In stock · 12 left".
class MedicineStockBadge extends StatelessWidget {
  final PharmacyModel medicine;

  const MedicineStockBadge({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inStock = medicine.inStock;
    final lowStock = medicine.isLowStock;

    final Color statusColor;
    final String statusText;
    if (!inStock) {
      statusColor = AppColors.warning;
      statusText = l10n.t('pharmacy.out_of_stock_short');
    } else if (lowStock) {
      statusColor = AppColors.warning;
      statusText = l10n.t('pharmacy.low_stock_short');
    } else {
      statusColor = AppColors.success;
      statusText = l10n.t('pharmacy.in_stock_short');
    }

    final qty = medicine.stockQty;
    final quantitySuffix = inStock && qty != null && !lowStock
        ? ' · ${l10n.t('pharmacy.items_left_short').replaceAll('{count}', '$qty')}'
        : '';

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
            '$statusText$quantitySuffix',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(color: statusColor),
          ),
        ),
      ],
    );
  }
}
