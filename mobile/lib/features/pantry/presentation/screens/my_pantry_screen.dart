import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';
import 'package:mobile/features/pantry/presentation/providers/pantry_management_provider.dart';
import 'package:mobile/features/pantry/presentation/providers/pantry_provider.dart';

class MyPantryScreen extends ConsumerWidget {
  const MyPantryScreen({super.key});

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(pantryItemsProvider);
    await ref.read(pantryItemsProvider.future);
  }

  void _openAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _PantryItemDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryAsync = ref.watch(pantryItemsProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkTeal),
        ),
        title: const Text(
          'My Pantry',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded, color: _teal, size: 25),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context),
        backgroundColor: _yellow,
        foregroundColor: _darkTeal,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Ingredient',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: pantryAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _teal)),
        error: (error, stackTrace) {
          return _ErrorState(
            error: error,
            onRetry: () {
              ref.invalidate(pantryItemsProvider);
            },
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return _EmptyPantryState(onAdd: () => _openAddDialog(context));
          }

          return RefreshIndicator(
            color: _teal,
            backgroundColor: Colors.white,
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
              children: [
                _PantrySummaryCard(count: items.length),
                const SizedBox(height: 18),
                ...items.map((item) => _PantryItemCard(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// PANTRY SUMMARY
// =============================================================

class _PantrySummaryCard extends StatelessWidget {
  const _PantrySummaryCard({required this.count});

  final int count;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2E6E1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.kitchen_outlined, color: _teal, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'ingredient' : 'ingredients'}',
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'in your pantry',
                  style: TextStyle(color: _secondaryText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PANTRY ITEM CARD
// =============================================================

class _PantryItemCard extends ConsumerWidget {
  const _PantryItemCard({required this.item});

  final PantryItemModel item;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFCF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete ingredient?',
            style: TextStyle(color: _darkTeal, fontWeight: FontWeight.w700),
          ),
          content: Text(
            '${item.ingredient.name} will be removed from your pantry.',
            style: const TextStyle(color: _secondaryText, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: _teal, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref
          .read(pantryManagementRepositoryProvider)
          .deletePantryItem(item.id);

      ref.invalidate(pantryItemsProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingredient removed from pantry.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete ingredient: ${_cleanError(error)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _edit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _PantryItemDialog(existingItem: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F1EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                color: _teal,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ingredient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _darkTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatQuantity(item.quantity)} ${item.unit.symbol}',
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.expiresAt != null) ...[
                    const SizedBox(height: 6),
                    _ExpiryBadge(date: item.expiresAt!),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ingredient options',
              icon: const Icon(Icons.more_vert_rounded, color: _darkTeal),
              onSelected: (value) {
                if (value == 'edit') {
                  _edit(context);
                } else if (value == 'delete') {
                  _delete(context, ref);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: _teal),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// EXPIRY BADGE
// =============================================================

class _ExpiryBadge extends StatelessWidget {
  const _ExpiryBadge({required this.date});

  final DateTime date;

  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.event_outlined, size: 14, color: _secondaryText),
        const SizedBox(width: 5),
        Text(
          'Expires ${_formatDate(date)}',
          style: const TextStyle(color: _secondaryText, fontSize: 12),
        ),
      ],
    );
  }
}

// =============================================================
// PANTRY ITEM DIALOG
// =============================================================

class _PantryItemDialog extends ConsumerStatefulWidget {
  const _PantryItemDialog({this.existingItem});

  final PantryItemModel? existingItem;

  @override
  ConsumerState<_PantryItemDialog> createState() => _PantryItemDialogState();
}

class _PantryItemDialogState extends ConsumerState<_PantryItemDialog> {
  late final TextEditingController _quantityController;

  DateTime? _expiresAt;
  Map<String, dynamic>? _selectedIngredient;
  Map<String, dynamic>? _selectedUnit;
  bool _isSaving = false;

  bool get _isEditing => widget.existingItem != null;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;

    _quantityController = TextEditingController(
      text: item == null ? '' : _formatQuantity(item.quantity),
    );

    _expiresAt = item?.expiresAt;

    if (item != null) {
      _selectedUnit = {
        'id': item.unit.id,
        'name': item.unit.name,
        'symbol': item.unit.symbol,
      };
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectIngredient() async {
    if (_isEditing) {
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF7),
      builder: (_) => const _IngredientSearchSheet(),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedIngredient = selected;
    });
  }

  Future<void> _selectUnit() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF7),
      builder: (_) => const _UnitSearchSheet(),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedUnit = selected;
    });
  }

  Future<void> _save() async {
    final quantityText = _quantityController.text.trim();
    final quantity = double.tryParse(quantityText);

    if (!_isEditing && _selectedIngredient == null) {
      _showError('Select an ingredient.');
      return;
    }

    if (quantity == null || quantity <= 0) {
      _showError('Enter a valid quantity.');
      return;
    }

    if (_selectedUnit == null) {
      _showError('Select a unit.');
      return;
    }

    final ingredientId = _selectedIngredient?['id'];
    final unitId = _selectedUnit?['id'];

    if (!_isEditing && (ingredientId is! String || ingredientId.isEmpty)) {
      _showError('Invalid ingredient selected.');
      return;
    }

    if (unitId is! String || unitId.isEmpty) {
      _showError('Invalid unit selected.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(pantryManagementRepositoryProvider);

      if (_isEditing) {
        await repository.updatePantryItem(
          itemId: widget.existingItem!.id,
          quantity: quantity,
          unitId: unitId,
          expiresAt: _expiresAt,
        );
      } else {
        await repository.addPantryItem(
          ingredientId: ingredientId as String,
          quantity: quantity,
          unitId: unitId,
          expiresAt: _expiresAt,
        );
      }

      ref.invalidate(pantryItemsProvider);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Pantry item updated.' : 'Ingredient added to pantry.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Unable to save pantry item: ${_cleanError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _teal,
              onPrimary: Colors.white,
              surface: Color(0xFFFFFCF7),
              onSurface: _darkTeal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _expiresAt = selected;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFCF7),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _isEditing ? 'Edit Pantry Item' : 'Add Ingredient',
              style: const TextStyle(
                color: _darkTeal,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: _secondaryText),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SelectorField(
              label: 'Ingredient',
              value: _isEditing
                  ? widget.existingItem!.ingredient.name
                  : _selectedIngredient?['name'] as String? ?? '',
              hint: 'Search ingredient...',
              icon: Icons.restaurant_outlined,
              enabled: !_isEditing,
              onTap: _selectIngredient,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g. 2',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: 14),
            _SelectorField(
              label: 'Unit',
              value: _selectedUnit?['name'] as String? ?? '',
              trailingValue: _selectedUnit?['symbol'] as String? ?? '',
              hint: 'Search unit...',
              icon: Icons.straighten_outlined,
              onTap: _selectUnit,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F1EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_outlined, color: _teal, size: 21),
              ),
              title: Text(
                _expiresAt == null
                    ? 'No expiry date'
                    : 'Expires ${_formatDate(_expiresAt!)}',
                style: const TextStyle(
                  color: _darkTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Optional',
                style: TextStyle(color: _secondaryText, fontSize: 12),
              ),
              trailing: _expiresAt == null
                  ? TextButton(
                      onPressed: _selectExpiryDate,
                      child: const Text(
                        'Set',
                        style: TextStyle(
                          color: _teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Change expiry',
                      onPressed: _selectExpiryDate,
                      icon: const Icon(Icons.edit_outlined, color: _teal),
                    ),
            ),
            if (_expiresAt != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _expiresAt = null;
                    });
                  },
                  child: const Text(
                    'Remove expiry',
                    style: TextStyle(color: _secondaryText),
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: _secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

// =============================================================
// SELECTOR FIELD
// =============================================================

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.trailingValue,
    this.enabled = true,
  });

  final String label;
  final String value;
  final String hint;
  final String? trailingValue;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: enabled ? _teal : _secondaryText),
          suffixIcon: enabled
              ? const Icon(Icons.keyboard_arrow_down_rounded, color: _teal)
              : null,
          enabled: enabled,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hint,
                style: TextStyle(
                  color: hasValue ? _darkTeal : _secondaryText,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (trailingValue != null && trailingValue!.isNotEmpty)
              Text(
                trailingValue!,
                style: const TextStyle(
                  color: _secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// INGREDIENT SEARCH SHEET
// =============================================================

class _IngredientSearchSheet extends ConsumerStatefulWidget {
  const _IngredientSearchSheet();

  @override
  ConsumerState<_IngredientSearchSheet> createState() =>
      _IngredientSearchSheetState();
}

class _IngredientSearchSheetState
    extends ConsumerState<_IngredientSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  Future<List<Map<String, dynamic>>>? _searchFuture;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    final query = value.trim();

    setState(() {
      if (query.isEmpty) {
        _searchFuture = null;
      } else {
        _searchFuture = ref
            .read(pantryManagementRepositoryProvider)
            .searchIngredients(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, bottom + 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Search Ingredient',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Type ingredient name...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _teal),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        )
                      : null,
                ),
                onChanged: _search,
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Start typing to search ingredients.',
          style: TextStyle(color: _secondaryText),
        ),
      );
    }

    final future = _searchFuture;

    if (future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Unable to search ingredients.\n\n'
                '${_cleanError(snapshot.error!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _secondaryText),
              ),
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return const Center(
            child: Text(
              'No ingredients found.',
              style: TextStyle(color: _secondaryText),
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final ingredient = results[index];

            final name = ingredient['name'];
            final id = ingredient['id'];

            if (name is! String || id is! String) {
              return const SizedBox.shrink();
            }

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F1EE),
                child: Icon(Icons.restaurant_outlined, color: _teal),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: _darkTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: _secondaryText,
              ),
              onTap: () {
                Navigator.of(context).pop(ingredient);
              },
            );
          },
        );
      },
    );
  }
}

// =============================================================
// UNIT SEARCH SHEET
// =============================================================

class _UnitSearchSheet extends ConsumerStatefulWidget {
  const _UnitSearchSheet();

  @override
  ConsumerState<_UnitSearchSheet> createState() => _UnitSearchSheetState();
}

class _UnitSearchSheetState extends ConsumerState<_UnitSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _filteredUnits = [];

  bool _loading = true;
  String? _error;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await ref
          .read(pantryManagementRepositoryProvider)
          .getUnits();

      if (!mounted) {
        return;
      }

      setState(() {
        _units = units;
        _filteredUnits = units;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _cleanError(error);
      });
    }
  }

  void _filterUnits(String value) {
    final query = value.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredUnits = _units;
        return;
      }

      _filteredUnits = _units.where((unit) {
        final name = '${unit['name'] ?? ''}'.toLowerCase();
        final symbol = '${unit['symbol'] ?? ''}'.toLowerCase();

        return name.contains(query) || symbol.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, bottom + 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Unit',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search unit...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _teal),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterUnits('');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        )
                      : null,
                ),
                onChanged: _filterUnits,
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildUnitResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Unable to load units.\n\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _secondaryText),
          ),
        ),
      );
    }

    if (_filteredUnits.isEmpty) {
      return const Center(
        child: Text('No units found.', style: TextStyle(color: _secondaryText)),
      );
    }

    return ListView.separated(
      itemCount: _filteredUnits.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final unit = _filteredUnits[index];

        final name = unit['name'];
        final symbol = unit['symbol'];
        final id = unit['id'];

        if (name is! String || symbol is! String || id is! String) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE3F1EE),
            child: Icon(Icons.straighten_outlined, color: _teal),
          ),
          title: Text(
            name,
            style: const TextStyle(
              color: _darkTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(symbol, style: const TextStyle(color: _secondaryText)),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: _secondaryText,
          ),
          onTap: () {
            Navigator.of(context).pop(unit);
          },
        );
      },
    );
  }
}

// =============================================================
// EMPTY STATE
// =============================================================

class _EmptyPantryState extends StatelessWidget {
  const _EmptyPantryState({required this.onAdd});

  final VoidCallback onAdd;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _yellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F1EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.kitchen_outlined, size: 48, color: _teal),
            ),
            const SizedBox(height: 22),
            const Text(
              'Your pantry is empty',
              style: TextStyle(
                color: _darkTeal,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 9),
            const Text(
              'Add ingredients manually or use Scan Pantry '
              'to detect ingredients with AI.',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 14,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _darkTeal,
                minimumSize: const Size(170, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Ingredient',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// ERROR STATE
// =============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9E3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: _teal,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Could not load your pantry',
              style: TextStyle(
                color: _darkTeal,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _secondaryText, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(130, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// HELPERS
// =============================================================

String _formatQuantity(double quantity) {
  if (quantity == quantity.roundToDouble()) {
    return quantity.toInt().toString();
  }

  return quantity
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _cleanError(Object error) {
  final message = error.toString();

  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }

  return message;
}
