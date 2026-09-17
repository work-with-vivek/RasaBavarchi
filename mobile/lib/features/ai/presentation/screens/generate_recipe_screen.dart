import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/ai/data/models/ai_recipe_model.dart';
import 'package:mobile/features/ai/data/models/ai_recipe_order_adapter.dart';
import 'package:mobile/features/ai/data/models/generate_recipe_request.dart';
import 'package:mobile/features/ai/presentation/providers/ai_provider.dart';
import 'package:mobile/features/order_ingredients/presentation/screens/cooking_servings_screen.dart';

class GenerateRecipeScreen extends ConsumerStatefulWidget {
  const GenerateRecipeScreen({super.key});

  @override
  ConsumerState<GenerateRecipeScreen> createState() =>
      _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends ConsumerState<GenerateRecipeScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _cuisineController = TextEditingController();

  String? _selectedDietaryPreference;
  int _servings = 2;
  bool _isGenerating = false;

  @override
  void dispose() {
    _ingredientsController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    if (_isGenerating) {
      return;
    }

    final ingredients = _ingredientsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one ingredient.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final request = GenerateRecipeRequest(
        ingredients: ingredients,
        cuisine: _cuisineController.text.trim().isEmpty
            ? null
            : _cuisineController.text.trim(),
        dietaryPreference: _selectedDietaryPreference,
        servings: _servings,
      );

      final AIRecipeModel recipe = await ref
          .read(aiRepositoryProvider)
          .generateRecipe(request);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _AIRecipeResultScreen(recipe: recipe),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not generate recipe: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Recipe')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a recipe with AI',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell the AI what ingredients you have and '
                  'it will create a recipe based on your preferences.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Ingredients',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _ingredientsController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'e.g. tomato, onion, potato, rice',
              helperText: 'Separate ingredients with commas',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 45),
                child: Icon(Icons.restaurant_menu),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Cuisine',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _cuisineController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'e.g. Indian, Italian, Mexican',
              prefixIcon: const Icon(Icons.public),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Dietary Preference',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _selectedDietaryPreference,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.eco_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            hint: const Text('Select preference'),
            items: const [
              DropdownMenuItem<String>(
                value: 'Vegetarian',
                child: Text('Vegetarian'),
              ),
              DropdownMenuItem<String>(value: 'Vegan', child: Text('Vegan')),
              DropdownMenuItem<String>(
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

          const SizedBox(height: 20),

          Text(
            'Servings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _servings <= 1 ? null : _decrementServings,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    '$_servings '
                    '${_servings == 1 ? 'person' : 'people'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _servings >= 20 ? null : _incrementServings,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateRecipe,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Generating Recipe...' : 'GENERATE RECIPE',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'The AI will create a recipe using '
            'the ingredients you entered.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AIRecipeResultScreen extends StatelessWidget {
  const _AIRecipeResultScreen({required this.recipe});

  final AIRecipeModel recipe;

  Future<void> _orderIngredients(BuildContext context) async {
    final recipeModel = AIRecipeOrderAdapter.toRecipeModel(recipe);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CookingServingsScreen(recipe: recipeModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalTime = recipe.prepTimeMinutes + recipe.cookTimeMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Recipe')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            recipe.recipeName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            recipe.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.category_outlined, label: recipe.category),
              _InfoChip(icon: Icons.public, label: recipe.cuisine),
              _InfoChip(icon: Icons.speed, label: recipe.difficulty),
              _InfoChip(icon: Icons.timer_outlined, label: '$totalTime mins'),
              _InfoChip(
                icon: Icons.people_outline,
                label: '${recipe.servings} servings',
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            'Nutrition',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
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

          Text(
            'Ingredients',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...recipe.ingredients.map((ingredient) {
            final unit = ingredient.unit.trim();

            final quantity = unit.isEmpty
                ? ingredient.quantity
                : '${ingredient.quantity} $unit';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.restaurant_menu, size: 19),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      ingredient.item,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Flexible(
                    child: Text(
                      quantity,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 28),

          Text(
            'Instructions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...recipe.instructions.asMap().entries.map((entry) {
            final stepNumber = entry.key + 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade800),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'This recipe was generated by AI. '
                    'Review the ingredients and instructions '
                    'before cooking.',
                    style: TextStyle(color: Colors.amber.shade900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: () => _orderIngredients(context),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text(
                'GET INGREDIENTS I’M MISSING',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  const _NutritionItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }
}
