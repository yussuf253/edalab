import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../l10n/app_localizations.dart';

class _EditableOption {
  String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  _EditableOption({required this.id, String name = '', double priceDelta = 0})
    : nameController = TextEditingController(text: name),
      priceController = TextEditingController(
        text: priceDelta == 0 ? '' : priceDelta.toStringAsFixed(0),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': nameController.text.trim(),
    'priceDelta': double.tryParse(priceController.text.trim()) ?? 0,
  };
}

class _EditableGroup {
  String id;
  final TextEditingController nameController;
  bool multiSelect;
  bool required;
  final TextEditingController maxSelectionsController;
  List<_EditableOption> options;

  _EditableGroup({
    required this.id,
    String name = '',
    this.multiSelect = false,
    this.required = false,
    int? maxSelections,
    List<_EditableOption>? options,
  }) : nameController = TextEditingController(text: name),
       maxSelectionsController = TextEditingController(
         text: maxSelections?.toString() ?? '',
       ),
       options = options ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': nameController.text.trim(),
    'type': multiSelect ? 'multiple' : 'single',
    'required': required,
    if (maxSelectionsController.text.trim().isNotEmpty)
      'maxSelections': int.tryParse(maxSelectionsController.text.trim()),
    'options': options
        .where((o) => o.nameController.text.trim().isNotEmpty)
        .map((o) => o.toJson())
        .toList(),
  };
}

class RestaurantMenuItemEditScreen extends StatefulWidget {
  final String userId;
  final String restaurantId;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? existingItem;

  const RestaurantMenuItemEditScreen({
    super.key,
    required this.userId,
    required this.restaurantId,
    required this.categories,
    this.existingItem,
  });

  @override
  State<RestaurantMenuItemEditScreen> createState() =>
      _RestaurantMenuItemEditScreenState();
}

class _RestaurantMenuItemEditScreenState
    extends State<RestaurantMenuItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  String? _selectedCategoryId;
  bool _isPopular = false;
  bool _isAvailable = true;
  bool _isSubmitting = false;
  final List<_EditableGroup> _groups = [];
  int _idCounter = 0;

  bool get _isEditing => widget.existingItem != null;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?['name']?.toString());
    _descriptionController = TextEditingController(
      text: item?['description']?.toString(),
    );
    _priceController = TextEditingController(
      text: item == null ? '' : (item['price'] as num?)?.toString() ?? '',
    );
    _imageUrlController = TextEditingController(
      text: item?['imageUrl']?.toString(),
    );
    _selectedCategoryId = item?['categoryId']?.toString();
    _isPopular = item?['isPopular'] as bool? ?? false;
    _isAvailable = item?['isAvailable'] as bool? ?? true;

    final customizations = item?['customizations'];
    final groupsJson = customizations is Map
        ? (customizations['groups'] as List? ?? [])
        : const [];
    for (final rawGroup in groupsJson) {
      final group = Map<String, dynamic>.from(rawGroup as Map);
      final optionsJson = group['options'] as List? ?? [];
      _groups.add(
        _EditableGroup(
          id: group['id']?.toString() ?? _nextId('group'),
          name: group['name']?.toString() ?? '',
          multiSelect: group['type'] == 'multiple',
          required: group['required'] as bool? ?? false,
          maxSelections: (group['maxSelections'] as num?)?.toInt(),
          options: optionsJson.map((rawOption) {
            final option = Map<String, dynamic>.from(rawOption as Map);
            return _EditableOption(
              id: option['id']?.toString() ?? _nextId('option'),
              name: option['name']?.toString() ?? '',
              priceDelta: (option['priceDelta'] as num?)?.toDouble() ?? 0,
            );
          }).toList(),
        ),
      );
    }
  }

  void _addGroup() {
    setState(() {
      _groups.add(_EditableGroup(id: _nextId('group')));
    });
  }

  void _removeGroup(_EditableGroup group) {
    setState(() => _groups.remove(group));
  }

  void _addOption(_EditableGroup group) {
    setState(() {
      group.options.add(_EditableOption(id: _nextId('option')));
    });
  }

  void _removeOption(_EditableGroup group, _EditableOption option) {
    setState(() => group.options.remove(option));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final payload = {
      'restaurantId': widget.restaurantId,
      'categoryId': _selectedCategoryId,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'imageUrl': _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      'isPopular': _isPopular,
      'isAvailable': _isAvailable,
      'customizationGroups': _groups
          .where((g) => g.nameController.text.trim().isNotEmpty)
          .map((g) => g.toJson())
          .toList(),
    };

    try {
      if (_isEditing) {
        final id = widget.existingItem!['id'].toString();
        await ApiClient.patch(
          '/pro/${widget.userId}/restaurant-menu/items/$id',
          payload,
        );
      } else {
        await ApiClient.post(
          '/pro/${widget.userId}/restaurant-menu/items',
          payload,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.menuItemSaved)));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteMenuItemConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final id = widget.existingItem!['id'].toString();
      await ApiClient.delete('/pro/${widget.userId}/restaurant-menu/items/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.menuItemDeleted)));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editMenuItem : l10n.newMenuItem),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _isSubmitting ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(ProDesignSystem.spacing16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.itemNameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.enterNameError : null,
            ),
            const SizedBox(height: ProDesignSystem.spacing12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.description),
              maxLines: 2,
            ),
            const SizedBox(height: ProDesignSystem.spacing12),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(labelText: '${l10n.price} (DJF)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null || parsed < 0) {
                  return l10n.enterValidPriceError;
                }
                return null;
              },
            ),
            const SizedBox(height: ProDesignSystem.spacing12),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: ProDesignSystem.spacing12),
            DropdownButtonFormField<String?>(
              value: _selectedCategoryId,
              decoration: InputDecoration(labelText: l10n.itemCategoryLabel),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.noCategoryOption),
                ),
                ...widget.categories.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c['id'].toString(),
                    child: Text(c['name']?.toString() ?? ''),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedCategoryId = value),
            ),
            const SizedBox(height: ProDesignSystem.spacing8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.isPopularLabel),
              value: _isPopular,
              activeColor: AppColors.food,
              onChanged: (v) => setState(() => _isPopular = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.isAvailableLabel),
              value: _isAvailable,
              activeColor: AppColors.food,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            const SizedBox(height: ProDesignSystem.spacing20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customizationGroupsTitle,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        l10n.customizationGroupsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _addGroup,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.addCustomizationGroup),
                ),
              ],
            ),
            const SizedBox(height: ProDesignSystem.spacing8),
            for (final group in _groups) _GroupEditor(
              group: group,
              l10n: l10n,
              onRemove: () => _removeGroup(group),
              onAddOption: () => _addOption(group),
              onRemoveOption: (option) => _removeOption(group, option),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: ProDesignSystem.spacing32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.food,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(l10n.save),
              ),
            ),
            const SizedBox(height: ProDesignSystem.spacing24),
          ],
        ),
      ),
    );
  }
}

class _GroupEditor extends StatelessWidget {
  final _EditableGroup group;
  final AppLocalizations l10n;
  final VoidCallback onRemove;
  final VoidCallback onAddOption;
  final ValueChanged<_EditableOption> onRemoveOption;
  final VoidCallback onChanged;

  const _GroupEditor({
    required this.group,
    required this.l10n,
    required this.onRemove,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ProDesignSystem.spacing12),
      padding: const EdgeInsets.all(ProDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusMedium),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: group.nameController,
                  decoration: InputDecoration(
                    labelText: l10n.groupNameLabel,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: ProDesignSystem.spacing8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: Text(l10n.groupTypeSingle),
                selected: !group.multiSelect,
                onSelected: (_) {
                  group.multiSelect = false;
                  onChanged();
                },
              ),
              ChoiceChip(
                label: Text(l10n.groupTypeMultiple),
                selected: group.multiSelect,
                onSelected: (_) {
                  group.multiSelect = true;
                  onChanged();
                },
              ),
              FilterChip(
                label: Text(l10n.groupRequiredLabel),
                selected: group.required,
                onSelected: (v) {
                  group.required = v;
                  onChanged();
                },
              ),
            ],
          ),
          if (group.multiSelect) ...[
            const SizedBox(height: ProDesignSystem.spacing8),
            TextField(
              controller: group.maxSelectionsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.maxSelectionsLabel,
                isDense: true,
              ),
            ),
          ],
          const SizedBox(height: ProDesignSystem.spacing12),
          for (final option in group.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: option.nameController,
                      decoration: InputDecoration(
                        labelText: l10n.optionNameLabel,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: option.priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.optionPriceDeltaLabel,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () => onRemoveOption(option),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: onAddOption,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(l10n.addOption),
          ),
        ],
      ),
    );
  }
}
