import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

class ShopProductCreateScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> stores;

  const ShopProductCreateScreen({
    super.key,
    required this.userId,
    required this.stores,
  });

  @override
  State<ShopProductCreateScreen> createState() => _ShopProductCreateScreenState();
}

class _ShopProductCreateScreenState extends State<ShopProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStoreId;
  final _categoryController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _unitController = TextEditingController();
  final _badgeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _galleryImageUrlsController = TextEditingController();
  final _colorsController = TextEditingController();
  final _sizesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _featuresController = TextEditingController();
  bool _inStock = true;
  bool _isOrganic = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.stores.isNotEmpty
        ? widget.stores.first['id']?.toString()
        : null;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _unitController.dispose();
    _badgeController.dispose();
    _imageUrlController.dispose();
    _galleryImageUrlsController.dispose();
    _colorsController.dispose();
    _sizesController.dispose();
    _tagsController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  List<String> _parseTextList(String value) {
    return value
        .split(RegExp(r'[,\n]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStoreId == null || _selectedStoreId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a store first.')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'storeId': _selectedStoreId,
      'categoryName': _categoryController.text.trim(),
      'name': _nameController.text.trim(),
      'brand': _brandController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'unit': _unitController.text.trim(),
      'badge': _badgeController.text.trim(),
      'imageUrl': _imageUrlController.text.trim(),
      'imageUrls': _parseTextList(_galleryImageUrlsController.text),
      'colors': _parseTextList(_colorsController.text),
      'sizes': _parseTextList(_sizesController.text),
      'tags': _parseTextList(_tagsController.text),
      'features': _parseTextList(_featuresController.text),
      'isOrganic': _isOrganic,
      'inStock': _inStock,
    };
    final originalPrice = _originalPriceController.text.trim();
    if (originalPrice.isNotEmpty) {
      payload['originalPrice'] = double.parse(originalPrice);
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      await ApiClient.post('/pro/${widget.userId}/shopping-products', payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to your catalog.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Shopping Product')),
      body: widget.stores.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'No store is connected yet. Create a store first to add products.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const _FormSectionTitle(
                          title: 'Basic details',
                          subtitle: 'Core catalog identity and description.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStoreId,
                          items: widget.stores
                              .map(
                                (store) => DropdownMenuItem<String>(
                                  value: store['id']?.toString(),
                                  child: Text(
                                    store['name']?.toString() ?? 'Store',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedStoreId = value),
                          decoration: const InputDecoration(labelText: 'Store'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Catalog category',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().length < 2)
                              ? 'Enter a category'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Product name',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().length < 2)
                              ? 'Enter a product name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          minLines: 3,
                          maxLines: 4,
                          validator: (value) =>
                              (value == null || value.trim().length < 4)
                              ? 'Enter a description'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        const _FormSectionTitle(
                          title: 'Pricing',
                          subtitle: 'Commercial fields used in listing and checkout.',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Price'),
                          validator: (value) =>
                              (double.tryParse(value ?? '') ?? 0) <= 0
                              ? 'Enter a valid price'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Original price (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit (optional)',
                            hintText: 'piece, box, pair...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _badgeController,
                          decoration: const InputDecoration(
                            labelText: 'Badge (optional)',
                            hintText: 'Best Seller, New, Limited...',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _FormSectionTitle(
                          title: 'Media and attributes',
                          subtitle: 'Images and variant metadata.',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Primary image URL',
                            hintText: 'https://...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _galleryImageUrlsController,
                          decoration: const InputDecoration(
                            labelText: 'Gallery image URLs',
                            hintText: 'Comma or new-line separated URLs',
                          ),
                          minLines: 2,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _colorsController,
                          decoration: const InputDecoration(
                            labelText: 'Colors',
                            hintText: 'Black, White, Blue',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _sizesController,
                          decoration: const InputDecoration(
                            labelText: 'Sizes',
                            hintText: 'S, M, L or 40, 41, 42',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags',
                            hintText: 'Sport, Casual, Trending',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _featuresController,
                          decoration: const InputDecoration(
                            labelText: 'Features',
                            hintText: 'Breathable mesh, Lightweight',
                          ),
                          minLines: 2,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                        const _FormSectionTitle(
                          title: 'Availability',
                          subtitle: 'Current stock state for storefront visibility.',
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isOrganic,
                          onChanged: (value) =>
                              setState(() => _isOrganic = value),
                          title: const Text('Mark as organic'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _inStock,
                          onChanged: (value) =>
                              setState(() => _inStock = value),
                          title: const Text('Available in stock'),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(
                        _isSubmitting ? 'Saving product...' : 'Create Product',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
