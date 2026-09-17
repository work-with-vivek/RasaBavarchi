import 'package:flutter/material.dart';

import 'package:mobile/features/recipes/data/models/recipe_model.dart';

class CookingServingsScreen extends StatefulWidget {
  const CookingServingsScreen({super.key, required this.recipe});

  final RecipeModel recipe;

  @override
  State<CookingServingsScreen> createState() => _CookingServingsScreenState();
}

class _CookingServingsScreenState extends State<CookingServingsScreen> {
  late int _servings;

  static const int _minServings = 1;
  static const int _maxServings = 10;

  @override
  void initState() {
    super.initState();

    final recipeServings = widget.recipe.servings;

    _servings = recipeServings.clamp(_minServings, _maxServings);
  }

  void _decreaseServings() {
    if (_servings <= _minServings) {
      return;
    }

    setState(() {
      _servings--;
    });
  }

  void _increaseServings() {
    if (_servings >= _maxServings) {
      return;
    }

    setState(() {
      _servings++;
    });
  }

  void _continue() {
    Navigator.of(context).pop(_servings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Ingredients')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ICON
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 28),

              // TITLE
              Text(
                'How many people are you cooking for?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // RECIPE SERVINGS
              Text(
                '${widget.recipe.title} serves ${widget.recipe.servings}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),

              const Spacer(),

              // SERVINGS SELECTOR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // DECREASE
                    IconButton(
                      onPressed: _servings <= _minServings
                          ? null
                          : _decreaseServings,
                      icon: const Icon(Icons.remove),
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        shape: const CircleBorder(),
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 28),

                    // CURRENT SERVINGS
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_servings',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _servings == 1 ? 'person' : 'people',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 28),

                    // INCREASE
                    IconButton(
                      onPressed: _servings >= _maxServings
                          ? null
                          : _increaseServings,
                      icon: const Icon(Icons.add),
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        shape: const CircleBorder(),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // INFORMATION
              Text(
                "We'll adjust the ingredient quantities for you.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),

              const Spacer(),

              // CONTINUE BUTTON
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
