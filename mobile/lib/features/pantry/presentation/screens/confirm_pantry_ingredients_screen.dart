import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/pantry/presentation/providers/pantry_management_provider.dart';

class ConfirmPantryIngredientsScreen extends ConsumerStatefulWidget {
  const ConfirmPantryIngredientsScreen({super.key, required this.ingredients});

  final List<String> ingredients;

  @override
  ConsumerState<ConfirmPantryIngredientsScreen> createState() =>
      _ConfirmPantryIngredientsScreenState();
}

class _ConfirmPantryIngredientsScreenState
    extends ConsumerState<ConfirmPantryIngredientsScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, String?> _selectedUnits = {};

  // Stores the actual master-database ingredient selected by the user.
  final Map<String, Map<String, dynamic>> _resolvedIngredients = {};

  bool _isSaving = false;

  static const List<String> _units = [
    'g',
    'kg',
    'ml',
    'L',
    'pc',
    'cup',
    'pinch',
    'tbsp',
    'tsp',
  ];

  @override
  void initState() {
    super.initState();

    for (final ingredient in widget.ingredients) {
      _quantityControllers[ingredient] = TextEditingController(text: '1');

      _selectedUnits[ingredient] = 'pc';
    }
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<Map<String, dynamic>?> _resolveIngredient(
    String ingredientName,
  ) async {
    final dataSource = ref.read(pantryManagementRemoteDataSourceProvider);

    // Use previously selected match if the user has already chosen one.
    final existingSelection = _resolvedIngredients[ingredientName];

    if (existingSelection != null) {
      return existingSelection;
    }

    try {
      final ingredient = await dataSource.getIngredientByName(ingredientName);

      _resolvedIngredients[ingredientName] = ingredient;

      return ingredient;
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        rethrow;
      }

      final matches = await dataSource.searchIngredients(ingredientName);

      if (!mounted) {
        return null;
      }

      final selected = await _showIngredientSelectionDialog(
        ingredientName,
        matches,
      );

      if (selected != null) {
        _resolvedIngredients[ingredientName] = selected;
      }

      return selected;
    }
  }

  Future<Map<String, dynamic>?> _showIngredientSelectionDialog(
    String searchedName,
    List<Map<String, dynamic>> matches,
  ) async {
    if (matches.isEmpty) {
      return null;
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose Ingredient'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We could not find an exact match for:',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  searchedName,
                  style: Theme.of(dialogContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Choose the ingredient that matches what you have:'),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final name = match['name'];

                      if (name is! String || name.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.restaurant),
                        ),
                        title: Text(name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(dialogContext).pop(match);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String? _validateQuantity(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter quantity';
    }

    final quantity = double.tryParse(text);

    if (quantity == null) {
      return 'Enter a valid number';
    }

    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }

    return null;
  }

  Future<void> _saveIngredients() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dataSource = ref.read(pantryManagementRemoteDataSourceProvider);

      final resolvedUnits = <String, Map<String, dynamic>>{};

      // ---------------------------------------------------------
      // Resolve all ingredients and units first.
      // ---------------------------------------------------------
      for (final ingredientName in widget.ingredients) {
        final quantityText = _quantityControllers[ingredientName]!.text.trim();

        final quantity = double.tryParse(quantityText);

        if (quantity == null || quantity <= 0) {
          throw FormatException('Invalid quantity for $ingredientName.');
        }

        final unitSymbol = _selectedUnits[ingredientName];

        if (unitSymbol == null || unitSymbol.isEmpty) {
          throw FormatException('Please select a unit for $ingredientName.');
        }

        final ingredient = await _resolveIngredient(ingredientName);

        if (ingredient == null) {
          throw FormatException(
            'Could not find a matching ingredient for '
            '$ingredientName.',
          );
        }

        final ingredientId = ingredient['id'];

        if (ingredientId is! String || ingredientId.isEmpty) {
          throw FormatException('Invalid ingredient ID for $ingredientName.');
        }

        final unit = await dataSource.getUnitBySymbol(unitSymbol);

        final unitId = unit['id'];

        if (unitId is! String || unitId.isEmpty) {
          throw FormatException('Could not find unit: $unitSymbol.');
        }

        resolvedUnits[ingredientName] = unit;
      }

      // ---------------------------------------------------------
      // Save only after all data is ready.
      // ---------------------------------------------------------
      for (final ingredientName in widget.ingredients) {
        final quantity = double.parse(
          _quantityControllers[ingredientName]!.text.trim(),
        );

        final ingredient = _resolvedIngredients[ingredientName]!;

        final unit = resolvedUnits[ingredientName]!;

        await dataSource.addPantryItem(
          ingredientId: ingredient['id'] as String,
          quantity: quantity,
          unitId: unit['id'] as String,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredients saved to your pantry.')),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save ingredients: $error')),
      );
    }
  }

  Widget _ingredientTitle(BuildContext context, String ingredientName) {
    final selectedIngredient = _resolvedIngredients[ingredientName];

    final selectedName = selectedIngredient?['name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ingredientName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (selectedName is String &&
            selectedName.trim().isNotEmpty &&
            selectedName.trim().toLowerCase() !=
                ingredientName.trim().toLowerCase()) ...[
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Saved as: $selectedName',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Ingredients')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.ingredients.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final ingredient = widget.ingredients[index];

                    final controller = _quantityControllers[ingredient]!;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ingredientTitle(context, ingredient),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: _validateQuantity,
                                    enabled: !_isSaving,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedUnits[ingredient],
                                    decoration: const InputDecoration(
                                      labelText: 'Unit',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _units
                                        .map(
                                          (unit) => DropdownMenuItem(
                                            value: unit,
                                            child: Text(unit),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _isSaving
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedUnits[ingredient] =
                                                  value;
                                            });
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveIngredients,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('SAVE TO PANTRY'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
