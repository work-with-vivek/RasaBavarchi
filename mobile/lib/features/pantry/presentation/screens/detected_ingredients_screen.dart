import 'package:flutter/material.dart';

import 'package:mobile/features/pantry/presentation/screens/confirm_pantry_ingredients_screen.dart';

class DetectedIngredientsScreen extends StatefulWidget {
  const DetectedIngredientsScreen({super.key, required this.ingredients});

  final List<String> ingredients;

  @override
  State<DetectedIngredientsScreen> createState() =>
      _DetectedIngredientsScreenState();
}

class _DetectedIngredientsScreenState extends State<DetectedIngredientsScreen> {
  late final List<String> _ingredients;

  @override
  void initState() {
    super.initState();

    _ingredients = widget.ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _continue() async {
    if (_ingredients.isEmpty) {
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ConfirmPantryIngredientsScreen(ingredients: _ingredients),
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pantry updated successfully.')),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detected Ingredients')),
      body: SafeArea(
        child: _ingredients.isEmpty
            ? const Center(child: Text('No ingredients detected.'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ingredients.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.restaurant),
                            ),
                            title: Text(ingredient),
                            trailing: const Icon(Icons.check_circle_outline),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continue,
                        child: const Text('CONFIRM QUANTITY'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
