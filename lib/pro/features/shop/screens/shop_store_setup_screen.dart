import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

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
  late final TextEditingController _imageUrlController;
  bool _isSubmitting = false;

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
    _imageUrlController = TextEditingController(
      text: widget.initialStore?['imageUrl']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'tagline': _taglineController.text.trim(),
      'description': _descriptionController.text.trim(),
      'imageUrl': _imageUrlController.text.trim(),
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
                ? 'Store created and connected to your profile.'
                : 'Store setup updated.',
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
          widget.initialStore == null ? 'Create Store' : 'Store Setup',
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
              child: const Text(
                'Configure your public storefront details. This setup is used by customers when browsing your store.',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Store name'),
              validator: (value) => (value == null || value.trim().length < 2)
                  ? 'Enter a valid store name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taglineController,
              decoration: const InputDecoration(
                labelText: 'Tagline',
                hintText: 'Short statement shown under the store name',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell customers about your store',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Store image URL',
                hintText: 'https://...',
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
          label: Text(_isSubmitting ? 'Saving...' : 'Save Store Setup'),
        ),
      ),
    );
  }
}
