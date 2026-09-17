import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/recipes/data/models/recipe_model.dart';
import '../../../../features/recipes/presentation/providers/recipe_notifier.dart';
import '../../data/models/meal_create_request.dart';
import '../providers/meal_plan_provider.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key, required this.mealPlanId});

  final String mealPlanId;

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  RecipeModel? _selectedRecipe;

  DateTime _selectedDate = DateTime.now();

  String _selectedMealType = 'Breakfast';

  bool _isAdding = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) {
        return;
      }

      ref.read(recipeNotifierProvider.notifier).loadRecipes();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================
  // SEARCH RECIPES
  // ===========================================================

  Future<void> _searchRecipes(String value) async {
    await ref.read(recipeNotifierProvider.notifier).searchRecipes(value);
  }

  // ===========================================================
  // SELECT DATE
  // ===========================================================

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  // ===========================================================
  // FORMAT DATE
  // ===========================================================

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} '
        '${date.year}';
  }

  // ===========================================================
  // ADD MEAL
  // ===========================================================

  Future<void> _addMeal() async {
    if (_isAdding) {
      return;
    }

    if (_selectedRecipe == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a recipe.')));
      return;
    }

    setState(() {
      _isAdding = true;
    });

    final notes = _notesController.text.trim();

    try {
      final addMeal = ref.read(addMealProvider);

      await addMeal(
        widget.mealPlanId,
        MealCreateRequest(
          recipeId: _selectedRecipe!.id,
          mealDate: _selectedDate,
          mealType: _selectedMealType,
          notes: notes.isEmpty ? null : notes,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Meal added successfully.')));

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add meal: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final recipesState = ref.watch(recipeNotifierProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Meal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // =================================================
            // HEADER
            // =================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_task,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Add a meal to your plan',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // RECIPE SECTION
            // =================================================
            const Text(
              'Select Recipe',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _searchController,
              enabled: !_isAdding,
              textInputAction: TextInputAction.search,
              onChanged: _searchRecipes,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _isAdding
                            ? null
                            : () {
                                _searchController.clear();

                                setState(() {});

                                _searchRecipes('');
                              },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // SELECTED RECIPE
            // =================================================
            if (_selectedRecipe != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedRecipe!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _isAdding
                          ? null
                          : () {
                              setState(() {
                                _selectedRecipe = null;
                              });
                            },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

            // =================================================
            // RECIPE LIST
            // =================================================
            recipesState.when(
              loading: () {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              error: (error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Could not load recipes: '
                    '$error',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                );
              },
              data: (recipes) {
                if (recipes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.search_off, size: 42),
                        SizedBox(height: 10),
                        Text('No recipes found.', textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final visibleRecipes = recipes.take(20).toList();

                return Column(
                  children: visibleRecipes.map((recipe) {
                    final isSelected = _selectedRecipe?.id == recipe.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        enabled: !_isAdding,
                        leading: CircleAvatar(
                          child: Text(
                            recipe.title.isEmpty
                                ? '?'
                                : recipe.title.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(
                          recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${recipe.prepTime + recipe.cookTime} mins '
                          '• ${recipe.difficulty.name}',
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          setState(() {
                            _selectedRecipe = recipe;
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // =================================================
            // DATE
            // =================================================
            const Text(
              'Meal Date',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: _isAdding ? null : _selectDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // MEAL TYPE
            // =================================================
            const Text(
              'Meal Type',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _selectedMealType,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.restaurant_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                DropdownMenuItem(value: 'Snack', child: Text('Snack')),
              ],
              onChanged: _isAdding
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedMealType = value;
                      });
                    },
            ),

            const SizedBox(height: 20),

            // =================================================
            // NOTES
            // =================================================
            const Text(
              'Notes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _notesController,
              enabled: !_isAdding,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Optional notes for this meal...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 45),
                  child: Icon(Icons.notes_outlined),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // ADD BUTTON
            // =================================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isAdding ? null : _addMeal,
                icon: _isAdding
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.add_task),
                label: Text(
                  _isAdding ? 'Adding Meal...' : 'ADD MEAL',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // INFO
            // =================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select a recipe, date, and '
                      'meal type before adding it '
                      'to your meal plan.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
