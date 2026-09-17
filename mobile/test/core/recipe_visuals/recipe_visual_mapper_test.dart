import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/recipe_visuals/recipe_visual_mapper.dart';

void main() {
  group('RecipeVisualMapper', () {
    test('maps pasta recipe to pasta illustration', () {
      final result = RecipeVisualMapper.getVisual(
        recipeName: 'Garlic Butter Pasta',
        category: 'Dinner',
      );

      expect(result, 'assets/images/recipe_visuals/pasta.png');
    });

    test('maps biryani recipe to rice illustration', () {
      final result = RecipeVisualMapper.getVisual(
        recipeName: 'Chicken Biryani',
        category: 'Dinner',
      );

      expect(result, 'assets/images/recipe_visuals/rice.png');
    });

    test('maps tomato soup to soup illustration', () {
      final result = RecipeVisualMapper.getVisual(
        recipeName: 'Creamy Tomato Soup',
        category: 'Lunch',
      );

      expect(result, 'assets/images/recipe_visuals/soup.png');
    });

    test('maps tart recipe to tart illustration', () {
      final result = RecipeVisualMapper.getVisual(
        recipeName: 'Leek & Cheddar Tart',
        category: 'Dinner',
      );

      expect(result, 'assets/images/recipe_visuals/tart.png');
    });

    test('maps smoothie recipe to smoothie illustration', () {
      final result = RecipeVisualMapper.getVisual(
        recipeName: 'Pomegranate Morning Shake',
        category: 'Breakfast',
      );

      expect(result, 'assets/images/recipe_visuals/smoothie.png');
    });

    test('maps dessert recipe to dessert illustration', () {
      final result = RecipeVisualMapper.getVisual(
        recipeName: 'Chocolate Cake',
        category: 'Dessert',
      );

      expect(result, 'assets/images/recipe_visuals/dessert.png');
    });
  });
}
