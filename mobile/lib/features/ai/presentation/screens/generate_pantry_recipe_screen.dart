import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/widgets/food_watermark_background.dart';
import 'package:mobile/features/ai/data/models/ai_recipe_model.dart';
import 'package:mobile/features/ai/data/models/generate_pantry_recipe_request.dart';
import 'package:mobile/features/ai/presentation/providers/ai_provider.dart';
import 'package:mobile/features/pantry/presentation/providers/pantry_provider.dart';

class GeneratePantryRecipeScreen extends ConsumerStatefulWidget {
  const GeneratePantryRecipeScreen({super.key});

  @override
  ConsumerState<GeneratePantryRecipeScreen> createState() =>
      _GeneratePantryRecipeScreenState();
}

class _GeneratePantryRecipeScreenState
    extends ConsumerState<GeneratePantryRecipeScreen> {
  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  final TextEditingController _cuisineController = TextEditingController();

  String? _selectedDietaryPreference;

  int _servings = 2;

  bool _isGenerating = false;

  @override
  void dispose() {
    _cuisineController.dispose();
    super.dispose();
  }

  // =============================================================
  // CREATE RECIPE
  // =============================================================

  Future<void> _createRecipe() async {
    if (_isGenerating) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final pantryItems = await ref.read(pantryItemsProvider.future);

      if (!mounted) {
        return;
      }

      if (pantryItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your pantry is empty. Add ingredients first.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      final request = GeneratePantryRecipeRequest(
        pantryItemIds: pantryItems.map((item) => item.id).toList(),
        cuisine: _cuisineController.text.trim().isEmpty
            ? null
            : _cuisineController.text.trim(),
        dietaryPreference: _selectedDietaryPreference,
        servings: _servings,
      );

      final AIRecipeModel recipe = await ref
          .read(aiRepositoryProvider)
          .generateRecipeFromPantry(request);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _RasaBavarchiRecipeResultScreen(recipe: recipe),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create your recipe: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // =============================================================
  // SERVINGS
  // =============================================================

  void _incrementServings() {
    if (_servings >= 20) {
      return;
    }

    setState(() {
      _servings++;
    });
  }

  void _decrementServings() {
    if (_servings <= 1) {
      return;
    }

    setState(() {
      _servings--;
    });
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final pantryState = ref.watch(pantryItemsProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkTeal),
        ),
        title: const Text(
          'Recipe From Pantry',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FoodWatermarkBackground(
        child: pantryState.when(
          loading: () {
            return const Center(child: CircularProgressIndicator(color: _teal));
          },
          error: (error, stackTrace) {
            return _buildErrorState(error);
          },
          data: (pantryItems) {
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // =================================================
                // HEADER
                // =================================================

                _buildHeaderCard(),

                const SizedBox(height: 24),

                // =================================================
                // PANTRY
                // =================================================
                const Text(
                  'Your Pantry',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${pantryItems.length} '
                  '${pantryItems.length == 1 ? 'ingredient' : 'ingredients'} '
                  'available',
                  style: const TextStyle(color: _secondaryText, fontSize: 14),
                ),

                const SizedBox(height: 7),

                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // CUISINE
                // =================================================
                const Text(
                  'Cuisine',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                _buildCuisineField(),

                const SizedBox(height: 20),

                // =================================================
                // DIETARY PREFERENCE
                // =================================================
                const Text(
                  'Dietary Preference',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                _buildDietaryField(),

                const SizedBox(height: 20),

                // =================================================
                // SERVINGS
                // =================================================
                const Text(
                  'Servings',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                _buildServingsSelector(),

                const SizedBox(height: 26),

                // =================================================
                // CREATE BUTTON
                // =================================================
                _buildCreateButton(pantryIsEmpty: pantryItems.isEmpty),

                const SizedBox(height: 11),

                Text(
                  _isGenerating
                      ? 'RasaBavarchi is preparing your recipe...'
                      : 'RasaBavarchi will use your saved pantry ingredients.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =============================================================
  // HEADER CARD
  // =============================================================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 21),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2EF).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0E5DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _teal,
              size: 30,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Cook with what you already have',
            style: TextStyle(
              color: _darkTeal,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'RasaBavarchi will look at your pantry '
            'ingredients and create a recipe that fits '
            'your preferences.',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // CUISINE FIELD
  // =============================================================

  Widget _buildCuisineField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _cuisineController,
        textInputAction: TextInputAction.next,
        style: const TextStyle(color: _darkTeal, fontSize: 15),
        decoration: const InputDecoration(
          hintText: 'e.g. Indian, Italian, Mexican',
          hintStyle: TextStyle(color: _secondaryText, fontSize: 15),
          prefixIcon: Icon(Icons.public_rounded, color: _teal),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        ),
      ),
    );
  }

  // =============================================================
  // DIETARY FIELD
  // =============================================================

  Widget _buildDietaryField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedDietaryPreference,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.eco_outlined, color: _teal),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _teal),
        hint: const Text(
          'Select preference',
          style: TextStyle(color: _secondaryText, fontSize: 15),
        ),
        items: const [
          DropdownMenuItem(value: 'Vegetarian', child: Text('Vegetarian')),
          DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
          DropdownMenuItem(
            value: 'Non-Vegetarian',
            child: Text('Non-Vegetarian'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedDietaryPreference = value;
          });
        },
      ),
    );
  }

  // =============================================================
  // SERVINGS SELECTOR
  // =============================================================

  Widget _buildServingsSelector() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _ServingButton(
            icon: Icons.remove_rounded,
            enabled: _servings > 1,
            onTap: _decrementServings,
          ),
          Expanded(
            child: Text(
              '$_servings '
              '${_servings == 1 ? 'person' : 'people'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkTeal,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ServingButton(
            icon: Icons.add_rounded,
            enabled: _servings < 20,
            onTap: _incrementServings,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // CREATE BUTTON
  // =============================================================

  Widget _buildCreateButton({required bool pantryIsEmpty}) {
    final disabled = pantryIsEmpty || _isGenerating;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : _createRecipe,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _darkTeal,
          disabledBackgroundColor: const Color(0xFFE2DED6),
          disabledForegroundColor: const Color(0xFF99948C),
          elevation: disabled ? 0 : 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _isGenerating
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(_darkTeal),
                ),
              )
            : const Icon(Icons.auto_awesome_rounded, size: 21),
        label: Text(
          _isGenerating ? 'CREATING RECIPE...' : 'CREATE RECIPE',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // ERROR STATE
  // =============================================================

  Widget _buildErrorState(Object error) {
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
                color: _teal,
                size: 40,
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
              onPressed: () {
                ref.invalidate(pantryItemsProvider);
              },
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
// SERVING BUTTON
// =============================================================

class _ServingButton extends StatelessWidget {
  const _ServingButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  static const Color _teal = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDF8ED),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? _teal : const Color(0xFFB8B3AA),
            size: 23,
          ),
        ),
      ),
    );
  }
}

// =============================================================
// RASABAVARCHI RECIPE RESULT
// =============================================================

class _RasaBavarchiRecipeResultScreen extends StatelessWidget {
  const _RasaBavarchiRecipeResultScreen({required this.recipe});

  final AIRecipeModel recipe;

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);

  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);

  @override
  Widget build(BuildContext context) {
    final totalTime = recipe.prepTimeMinutes + recipe.cookTimeMinutes;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkTeal),
        ),
        title: const Text(
          'RasaBavarchi Recipe',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FoodWatermarkBackground(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ===================================================
            // RECIPE TITLE
            // ===================================================

            Text(
              recipe.recipeName,
              style: const TextStyle(
                color: _darkTeal,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              recipe.description,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            // ===================================================
            // RECIPE INFO
            // ===================================================
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: recipe.category,
                ),
                _InfoChip(icon: Icons.public_rounded, label: recipe.cuisine),
                _InfoChip(icon: Icons.speed_rounded, label: recipe.difficulty),
                _InfoChip(icon: Icons.timer_outlined, label: '$totalTime mins'),
                _InfoChip(
                  icon: Icons.people_outline_rounded,
                  label: '${recipe.servings} servings',
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ===================================================
            // NUTRITION
            // ===================================================
            const _SectionHeading(title: 'Nutrition'),

            const SizedBox(height: 11),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NutritionItem(
                      value: '${recipe.nutrition.calories}',
                      label: 'Calories',
                    ),
                  ),
                  Expanded(
                    child: _NutritionItem(
                      value: recipe.nutrition.proteinG.toStringAsFixed(1),
                      label: 'Protein',
                    ),
                  ),
                  Expanded(
                    child: _NutritionItem(
                      value: recipe.nutrition.carbsG.toStringAsFixed(1),
                      label: 'Carbs',
                    ),
                  ),
                  Expanded(
                    child: _NutritionItem(
                      value: recipe.nutrition.fatG.toStringAsFixed(1),
                      label: 'Fat',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ===================================================
            // INGREDIENTS
            // ===================================================
            const _SectionHeading(title: 'Ingredients'),

            const SizedBox(height: 11),

            ...recipe.ingredients.map((ingredient) {
              final quantity = ingredient.unit.trim().isEmpty
                  ? ingredient.quantity
                  : '${ingredient.quantity} '
                        '${ingredient.unit}';

              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F1EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
                        color: _teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        ingredient.item,
                        style: const TextStyle(
                          color: _darkTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      quantity,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _darkTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 19),

            // ===================================================
            // INSTRUCTIONS
            // ===================================================
            const _SectionHeading(title: 'Instructions'),

            const SizedBox(height: 12),

            ...recipe.instructions.asMap().entries.map((entry) {
              final stepNumber = entry.key + 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: _teal,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Color(0xFF3F403C),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // ===================================================
            // RASABAVARCHI NOTICE
            // ===================================================
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7DF),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFF0DE9B)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF927100),
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This recipe was created by '
                      'RasaBavarchi using your pantry '
                      'ingredients. Review the ingredients '
                      'and instructions before cooking.',
                      style: TextStyle(
                        color: Color(0xFF735D12),
                        fontSize: 13,
                        height: 1.45,
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

// =============================================================
// SECTION HEADING
// =============================================================

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  static const Color _darkTeal = Color(0xFF064E46);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _darkTeal,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// =============================================================
// INFO CHIP
// =============================================================

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0E5DF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 1),
          Icon(icon, size: 15, color: _teal),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _darkTeal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// NUTRITION ITEM
// =============================================================

class _NutritionItem extends StatelessWidget {
  const _NutritionItem({required this.value, required this.label});

  final String value;
  final String label;

  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _darkTeal,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _secondaryText, fontSize: 11),
        ),
      ],
    );
  }
}
