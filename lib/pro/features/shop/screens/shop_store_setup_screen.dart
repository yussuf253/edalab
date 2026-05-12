import 'dart:typed_data';

import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/media_upload_service.dart';

class ShopStoreSetupScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final Map<String, dynamic>? initialStore;

  const ShopStoreSetupScreen({
    super.key,
    required this.userId,
    required this.businessName,
    this.initialStore,
  });

  @override
  State<ShopStoreSetupScreen> createState() => _ShopStoreSetupScreenState();
}

class _ShopStoreSetupScreenState extends State<ShopStoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _descriptionController;
  String? _uploadedImageUrl;
  Uint8List? _pickedImageBytes;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialStore?['name']?.toString().trim().isNotEmpty == true
          ? widget.initialStore!['name'].toString()
          : widget.businessName,
    );
    _taglineController = TextEditingController(
      text: widget.initialStore?['subtitle']?.toString() ?? '',
    );
    _descriptionController = TextEditingController();
    _uploadedImageUrl = widget.initialStore?['imageUrl']?.toString().trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadStoreImage() async {
    if (_isUploadingImage) return;
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
      _pickedImageBytes = bytes;
      _isUploadingImage = true;
    });

    try {
      final uploaded = await MediaUploadService.uploadImage(
        scope: MediaUploadScope.store,
        ownerId: widget.userId,
        fileName: file.name,
        mimeType: file.mimeType,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = uploaded.url;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'tagline': _taglineController.text.trim(),
      'description': _descriptionController.text.trim(),
      'imageUrl': _uploadedImageUrl?.trim() ?? '',
    };

    setState(() => _isSubmitting = true);
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/pro/${widget.userId}/shopping-store', payload)
            as Map,
      );
      if (!mounted) return;
      final created = response['created'] as bool? ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created
                ? l10n.storeCreatedSuccessfully
                : l10n.storeUpdatedSuccessfully,
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialStore == null ? l10n.createStore : l10n.storeSetup,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                l10n.storeSetupSubtitle,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.storeNameLabel),
              validator: (value) => (value == null || value.trim().length < 2)
                  ? l10n.enterStoreNameError
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taglineController,
              decoration: InputDecoration(
                labelText: l10n.taglineLabel,
                hintText: l10n.taglineHint,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                hintText: l10n.storeDescriptionHint,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _pickedImageBytes != null
                  ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                  : ((_uploadedImageUrl?.isNotEmpty ?? false)
                        ? Image.network(
                            _uploadedImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.storefront_outlined, size: 42),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.storefront_outlined, size: 42),
                          )),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isUploadingImage ? null : _pickAndUploadStoreImage,
              icon: _isUploadingImage
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(
                _isUploadingImage ? l10n.uploadingImage : l10n.uploadStoreImage,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSubmitting ? l10n.saving : l10n.saveStoreSetup),
        ),
      ),
    );
  }
}
