import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/media_upload_service.dart';

class ShopProductCreateScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> stores;
  final String module;

  const ShopProductCreateScreen({
    super.key,
    required this.userId,
    required this.stores,
    this.module = 'shopping',
  });

  @override
  State<ShopProductCreateScreen> createState() =>
      _ShopProductCreateScreenState();
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
  final _dosageController = TextEditingController();
  final _packageSizeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _galleryImageUrlsController = TextEditingController();
  final _colorsController = TextEditingController();
  final _sizesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _featuresController = TextEditingController();
  Uint8List? _primaryImageBytes;
  bool _isUploadingPrimaryImage = false;
  final List<Uint8List> _galleryPreviewBytes = <Uint8List>[];
  bool _isUploadingGalleryImage = false;
  bool _inStock = true;
  bool _isOrganic = false;
  bool _requiresPrescription = false;
  bool _isSubmitting = false;

  bool get _isPharmacy => widget.module == 'pharmacy';

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.stores.isNotEmpty
        ? widget.stores.first['id']?.toString()
        : null;
    _unitController.text = _isPharmacy ? 'box' : '';
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
    _dosageController.dispose();
    _packageSizeController.dispose();
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

  Future<void> _pickAndUploadPrimaryImage() async {
    if (_isUploadingPrimaryImage) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _primaryImageBytes = bytes;
      _isUploadingPrimaryImage = true;
    });

    try {
      final uploaded = await MediaUploadService.uploadImage(
        scope: MediaUploadScope.product,
        ownerId: widget.userId,
        fileName: file.name,
        mimeType: file.mimeType,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _imageUrlController.text = uploaded.url;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) {
        setState(() => _isUploadingPrimaryImage = false);
      }
    }
  }

  Future<void> _pickAndUploadGalleryImage() async {
    if (_isUploadingGalleryImage) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _isUploadingGalleryImage = true);

    try {
      final uploaded = await MediaUploadService.uploadImage(
        scope: MediaUploadScope.product,
        ownerId: widget.userId,
        fileName: file.name,
        mimeType: file.mimeType,
        bytes: bytes,
      );
      if (!mounted) return;
      final existing = _parseTextList(_galleryImageUrlsController.text);
      if (!existing.contains(uploaded.url)) {
        existing.add(uploaded.url);
      }
      setState(() {
        _galleryPreviewBytes.add(bytes);
        _galleryImageUrlsController.text = existing.join('\n');
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) {
        setState(() => _isUploadingGalleryImage = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_isUploadingPrimaryImage || _isUploadingGalleryImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait for image uploads to finish first.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStoreId == null || _selectedStoreId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPharmacy
                ? 'Select a pharmacy business first.'
                : 'Select a store first.',
          ),
        ),
      );
      return;
    }

    final selectedStore = widget.stores.firstWhere(
      (store) => store['id']?.toString() == _selectedStoreId,
      orElse: () => const <String, dynamic>{},
    );

    final payload = <String, dynamic>{
      'module': widget.module,
      if (_isPharmacy)
        'businessName': (selectedStore['name']?.toString() ?? _selectedStoreId)
      else
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
      'tags': _parseTextList(_tagsController.text),
      'features': _parseTextList(_featuresController.text),
      if (!_isPharmacy) 'colors': _parseTextList(_colorsController.text),
      if (!_isPharmacy) 'sizes': _parseTextList(_sizesController.text),
      if (_isPharmacy) 'dosage': _dosageController.text.trim(),
      if (_isPharmacy) 'packageSize': _packageSizeController.text.trim(),
      if (_isPharmacy) 'requiresPrescription': _requiresPrescription,
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
        SnackBar(
          content: Text(
            _isPharmacy
                ? 'Medicine added to your pharmacy catalog.'
                : 'Product added to your catalog.',
          ),
        ),
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
    final title = _isPharmacy ? 'Add Medicine' : 'Add Shopping Product';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: widget.stores.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      _isPharmacy
                          ? 'No pharmacy business is connected yet. Connect one first to add medicines.'
                          : 'No store is connected yet. Create a store first to add products.',
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
                        _FormSectionTitle(
                          title: 'Basic details',
                          subtitle: _isPharmacy
                              ? 'Medicine identity and pharmacy binding.'
                              : 'Core catalog identity and description.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStoreId,
                          items: widget.stores
                              .map(
                                (store) => DropdownMenuItem<String>(
                                  value: store['id']?.toString(),
                                  child: Text(
                                    store['name']?.toString() ??
                                        (_isPharmacy ? 'Pharmacy' : 'Store'),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedStoreId = value),
                          decoration: InputDecoration(
                            labelText: _isPharmacy
                                ? 'Pharmacy business'
                                : 'Store',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            labelText: _isPharmacy
                                ? 'Medicine category'
                                : 'Catalog category',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().length < 2)
                              ? 'Enter a category'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: _isPharmacy
                                ? 'Medicine name'
                                : 'Product name',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().length < 2)
                              ? 'Enter a name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _brandController,
                          decoration: InputDecoration(
                            labelText: _isPharmacy
                                ? 'Lab / Brand (optional)'
                                : 'Brand (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: _isPharmacy
                                ? 'Medicine details'
                                : 'Description',
                          ),
                          minLines: 3,
                          maxLines: 4,
                          validator: (value) =>
                              (value == null || value.trim().length < 4)
                              ? 'Enter a description'
                              : null,
                        ),
                        if (_isPharmacy) ...[
                          const SizedBox(height: 18),
                          const _FormSectionTitle(
                            title: 'Medical specification',
                            subtitle:
                                'Dosage, package details, and prescription need.',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _dosageController,
                            decoration: const InputDecoration(
                              labelText: 'Dosage (optional)',
                              hintText: '1 tablet every 8 hours',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _packageSizeController,
                            decoration: const InputDecoration(
                              labelText: 'Package size (optional)',
                              hintText: '20 tablets / 100ml / 1 tube',
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _requiresPrescription,
                            onChanged: (value) =>
                                setState(() => _requiresPrescription = value),
                            title: const Text('Requires prescription'),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _FormSectionTitle(
                          title: 'Pricing',
                          subtitle:
                              'Commercial fields used in listing and checkout.',
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
                          decoration: InputDecoration(
                            labelText: 'Unit (optional)',
                            hintText: _isPharmacy
                                ? 'box, bottle, strip...'
                                : 'piece, box, pair...',
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
                          subtitle: 'Images and metadata.',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 156,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _primaryImageBytes != null
                              ? Image.memory(
                                  _primaryImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : (_imageUrlController.text.trim().isNotEmpty
                                    ? Image.network(
                                        _imageUrlController.text.trim(),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 42,
                                              ),
                                            ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 42,
                                        ),
                                      )),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isUploadingPrimaryImage
                              ? null
                              : _pickAndUploadPrimaryImage,
                          icon: _isUploadingPrimaryImage
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _isUploadingPrimaryImage
                                ? 'Uploading primary image...'
                                : 'Upload Primary Image',
                          ),
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
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isUploadingGalleryImage
                              ? null
                              : _pickAndUploadGalleryImage,
                          icon: _isUploadingGalleryImage
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.collections_outlined),
                          label: Text(
                            _isUploadingGalleryImage
                                ? 'Uploading gallery image...'
                                : 'Add Gallery Image',
                          ),
                        ),
                        if (_galleryPreviewBytes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _galleryPreviewBytes.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: Image.memory(
                                      _galleryPreviewBytes[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (!_isPharmacy) ...[
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
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tagsController,
                          decoration: InputDecoration(
                            labelText: 'Tags',
                            hintText: _isPharmacy
                                ? 'Pain relief, Cold, Antibiotic'
                                : 'Sport, Casual, Trending',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _featuresController,
                          decoration: const InputDecoration(
                            labelText: 'Features',
                            hintText:
                                'Fast action, Child-safe cap, Lightweight',
                          ),
                          minLines: 2,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                        const _FormSectionTitle(
                          title: 'Availability',
                          subtitle:
                              'Current stock state for storefront visibility.',
                        ),
                        const SizedBox(height: 8),
                        if (!_isPharmacy)
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
                      onPressed:
                          _isSubmitting ||
                              _isUploadingPrimaryImage ||
                              _isUploadingGalleryImage
                          ? null
                          : _submit,
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(
                        _isSubmitting
                            ? (_isPharmacy
                                  ? 'Saving medicine...'
                                  : 'Saving product...')
                            : (_isPharmacy
                                  ? 'Create Medicine'
                                  : 'Create Product'),
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

  const _FormSectionTitle({required this.title, required this.subtitle});

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
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
