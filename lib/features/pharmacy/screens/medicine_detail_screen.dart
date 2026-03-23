import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class MedicineDetailScreen extends StatelessWidget {
  final String medicineId;
  const MedicineDetailScreen({super.key, required this.medicineId});

  @override
  Widget build(BuildContext context) {
    final m = PharmacyModel.sampleItems.firstWhere(
      (item) => item.id == medicineId,
      orElse: () => PharmacyModel.sampleItems.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(color: AppColors.pharmacyBg, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.medication_rounded, color: AppColors.pharmacy, size: 64),
              ),
            ),
            const SizedBox(height: 24),
            Text(m.name, style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text('${m.category} • ${m.size}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('\$${m.price.toStringAsFixed(2)}', style: AppTextStyles.price.copyWith(color: AppColors.pharmacy, fontSize: 24)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)),
                  child: Text('In Stock', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                ),
                if (m.requiresPrescription) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(6)),
                    child: Text('Prescription Required', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Text('Description', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              m.description,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey, height: 1.6),
            ),
            const SizedBox(height: 20),
            Text('Dosage', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.pharmacy),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m.dosage, style: AppTextStyles.bodyMedium)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Warnings', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Do not exceed the stated dose. Consult your doctor if symptoms persist.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.dark)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: AppButton(
            text: 'Add to Cart • \$${m.price.toStringAsFixed(2)}', 
            color: AppColors.pharmacy, 
            onPressed: () {
              context.read<CartProvider>().addItem(CartItem(
                id: m.id,
                name: m.name,
                price: m.price,
                moduleType: 'pharmacy',
                brand: m.category,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${m.name} added to cart!'), backgroundColor: AppColors.success),
              );
              context.pop();
            },
          ),
        ),
      ),
    );
  }
}
