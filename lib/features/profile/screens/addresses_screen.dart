import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  IconData _iconForLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('home')) return Icons.home_rounded;
    if (normalized.contains('work') || normalized.contains('office')) return Icons.work_rounded;
    if (normalized.contains('family') || normalized.contains('mom') || normalized.contains('dad')) {
      return Icons.favorite_rounded;
    }
    return Icons.location_on_rounded;
  }

  Future<void> _showAddressSheet(
    BuildContext context, {
    AddressModel? address,
  }) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to manage your addresses.'),
          action: SnackBarAction(
            label: 'Login',
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
    final authProvider = context.watch<AuthProvider>();
    final addresses = authProvider.user?.addresses ?? const [];
    final isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Addresses'),
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
                      isLoggedIn ? 'No saved addresses yet' : 'Log in to manage addresses',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLoggedIn
                          ? 'Add delivery locations to make checkout faster and keep your favorite places handy.'
                          : 'Save delivery locations after logging in so checkout is faster across the app.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
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
                  address.address,
                  if ((address.city ?? '').isNotEmpty) address.city!,
                  if ((address.zipCode ?? '').isNotEmpty) address.zipCode!,
                ].join(', ');

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: address.isDefault ? Border.all(color: AppColors.primary, width: 1.5) : null,
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
                        child: Icon(_iconForLabel(address.label), color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(address.label, style: AppTextStyles.labelLarge),
                                ),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Default',
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
                            Text(subtitle, style: AppTextStyles.caption, maxLines: 2),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.mediumGrey),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _showAddressSheet(context, address: address);
                            return;
                          }

                          if (value == 'default') {
                            final success = await context.read<AuthProvider>().setDefaultAddress(address.id);
                            if (!context.mounted || success) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProvider.errorMessage ?? 'Failed to update default address.'),
                              ),
                            );
                            return;
                          }

                          if (value == 'delete') {
                            final success = await context.read<AuthProvider>().deleteAddress(address.id);
                            if (!context.mounted || success) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProvider.errorMessage ?? 'Failed to delete address.'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          if (!address.isDefault)
                            const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
          isLoggedIn ? 'Add Address' : 'Login Required',
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
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipCodeController;
  late bool _isDefault;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _addressController = TextEditingController(text: widget.address?.address ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _zipCodeController = TextEditingController(text: widget.address?.zipCode ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      widget.address == null ? 'Add Address' : 'Edit Address',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                        hintText: 'Home, Work, Mom\'s House',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _zipCodeController,
                      decoration: const InputDecoration(
                        labelText: 'ZIP Code',
                        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _isDefault,
                      onChanged: (value) => setState(() => _isDefault = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set as default'),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text(widget.address == null ? 'Add Address' : 'Save Changes'),
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
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = widget.address == null
        ? await auth.addAddress(
            label: _labelController.text,
            address: _addressController.text,
            city: _cityController.text,
            zipCode: _zipCodeController.text,
            isDefault: _isDefault,
          )
        : await auth.updateAddress(
            addressId: widget.address!.id,
            label: _labelController.text,
            address: _addressController.text,
            city: _cityController.text,
            zipCode: _zipCodeController.text,
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
        content: Text(auth.errorMessage ?? 'Failed to save address.'),
      ),
    );
  }
}
