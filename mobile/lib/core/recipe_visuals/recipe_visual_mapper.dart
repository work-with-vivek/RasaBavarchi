class RecipeVisualMapper {
  RecipeVisualMapper._();

  static const String _basePath = 'assets/images/recipe_visuals';

  // =============================================================
  // RECIPE VISUAL MAPPER
  // =============================================================
  //
  // Priority:
  //
  // 1. Specific dish type from recipe name
  // 2. Protein / savory recipe
  // 3. Category fallback
  // 4. Generic savory fallback
  //
  // foodType is intentionally NOT used.
  //
  // VEGAN / VEGETARIAN / NON_VEGETARIAN describes dietary
  // classification, not the visual appearance of a dish.
  // =============================================================

  static String getVisual({
    String? recipeName,
    String? category,
    String? foodType,
  }) {
    final name = _normalize(recipeName);
    final categoryName = _normalize(category);

    // ===========================================================
    // 1. TART / QUICHE
    // ===========================================================

    if (_containsAny(name, ['tart', 'tarts', 'quiche', 'quiches', 'galette'])) {
      return '$_basePath/tart.png';
    }

    // ===========================================================
    // 2. PIZZA
    // ===========================================================

    if (_containsAny(name, [
      'pizza',
      'pizzas',
      'margherita',
      'pepperoni pizza',
    ])) {
      return '$_basePath/pizza.png';
    }

    // ===========================================================
    // 3. PASTA / NOODLES
    // ===========================================================

    if (_containsAny(name, [
      'pasta',
      'spaghetti',
      'macaroni',
      'lasagna',
      'lasagne',
      'linguine',
      'penne',
      'fettuccine',
      'tagliatelle',
      'ravioli',
      'tortellini',
      'noodle',
      'noodles',
      'ramen',
      'udon',
      'soba',
      'vermicelli',
      'chow mein',
      'pad thai',
    ])) {
      return '$_basePath/pasta.png';
    }

    // ===========================================================
    // 4. SANDWICH / BURGER / WRAP
    // ===========================================================

    if (_containsAny(name, [
      'sandwich',
      'sandwiches',
      'burger',
      'burgers',
      'hamburger',
      'wrap',
      'wraps',
      'burrito',
      'burritos',
      'panini',
      'toastie',
      'club sandwich',
      'hot dog',
      'hotdog',
    ])) {
      return '$_basePath/sandwich.png';
    }

    // ===========================================================
    // 5. SALAD
    // ===========================================================

    if (_containsAny(name, [
      'salad',
      'salads',
      'coleslaw',
      'slaw',
      'green salad',
      'mixed greens',
      'caesar salad',
      'caesar',
      'fruit salad',
    ])) {
      return '$_basePath/salad.png';
    }

    // ===========================================================
    // 6. SOUP
    // ===========================================================

    if (_containsAny(name, [
      'soup',
      'soups',
      'broth',
      'chowder',
      'bisque',
      'gazpacho',
      'consomme',
      'consommé',
      'stew soup',
    ])) {
      return '$_basePath/soup.png';
    }

    // ===========================================================
    // 7. RICE / BIRYANI / RISOTTO
    //
    // Specific rice dishes must beat protein keywords.
    //
    // chicken biryani -> rice
    // chicken fried rice -> rice
    // mutton pulao -> rice
    // ===========================================================

    if (_containsAny(name, [
      'rice',
      'biryani',
      'biriyani',
      'fried rice',
      'pulao',
      'pilaf',
      'risotto',
      'jambalaya',
      'rice bowl',
    ])) {
      if (_containsAny(name, ['rice pudding'])) {
        return '$_basePath/dessert.png';
      }

      if (_containsAny(name, ['rice cake'])) {
        return '$_basePath/dessert.png';
      }

      return '$_basePath/rice.png';
    }

    // ===========================================================
    // 8. CURRY / MASALA / GRAVY / DAL
    // ===========================================================

    if (_containsAny(name, [
      'curry',
      'curries',
      'masala',
      'korma',
      'gravy',
      'stew',
      'stews',
      'vindaloo',
      'tikka masala',
      'butter chicken',
      'palak',
      'dal',
      'daal',
      'dhal',
      'chana masala',
      'rajma',
      'paneer curry',
      'paneer masala',
    ])) {
      return '$_basePath/curry.png';
    }

    // ===========================================================
    // 9. DESSERT
    // ===========================================================

    if (_containsAny(name, [
      'cake',
      'cakes',
      'brownie',
      'brownies',
      'cookie',
      'cookies',
      'dessert',
      'desserts',
      'pudding',
      'puddings',
      'pie',
      'pies',
      'pastry',
      'pastries',
      'muffin',
      'muffins',
      'cupcake',
      'cupcakes',
      'donut',
      'donuts',
      'doughnut',
      'doughnuts',
      'ice cream',
      'icecream',
      'gelato',
      'sorbet',
      'cheesecake',
      'chocolate cake',
      'chocolate brownie',
      'sweet',
      'sweets',
      'truffle',
      'truffles',
      'fudge',
      'macaron',
      'macarons',
      'halwa',
      'kheer',
      'gulab jamun',
      'rasgulla',
      'barfi',
    ])) {
      return '$_basePath/dessert.png';
    }

    // ===========================================================
    // 10. DRINK / SMOOTHIE
    // ===========================================================

    if (_containsAny(name, [
      'smoothie',
      'smoothies',
      'milkshake',
      'milkshakes',
      'shake',
      'shakes',
      'juice',
      'juices',
      'drink',
      'drinks',
      'beverage',
      'beverages',
      'cocktail',
      'cocktails',
      'mocktail',
      'mocktails',
      'lassi',
      'lemonade',
      'tea',
      'coffee',
      'latte',
      'cappuccino',
      'espresso',
    ])) {
      return '$_basePath/smoothie.png';
    }

    // ===========================================================
    // 11. BREAKFAST
    // ===========================================================
    //
    // IMPORTANT:
    // This rule is AFTER the major savory dish rules.
    //
    // Never match "egg" by itself.
    //
    // eggplant must NOT become breakfast.
    // ===========================================================

    if (_containsAny(name, [
      'pancake',
      'pancakes',
      'waffle',
      'waffles',
      'omelette',
      'omelettes',
      'omelet',
      'omelets',
      'french toast',
      'scrambled egg',
      'scrambled eggs',
      'fried egg',
      'fried eggs',
      'boiled egg',
      'boiled eggs',
      'poached egg',
      'poached eggs',
      'egg breakfast',
      'egg sandwich',
      'egg toast',
      'hash brown',
      'hash browns',
      'breakfast toast',
      'breakfast bowl',
      'breakfast',
    ])) {
      return '$_basePath/breakfast.png';
    }

    // ===========================================================
    // 12. PROTEIN / MEAT / SEAFOOD
    //
    // This is intentionally AFTER specific dish types such as
    // pasta, rice, salad, soup, curry, etc.
    //
    // Therefore:
    //
    // chicken pasta  -> pasta
    // chicken salad  -> salad
    // chicken soup   -> soup
    // chicken biryani -> rice
    // chicken curry  -> curry
    // chicken        -> curry
    //
    // There is currently no dedicated meat illustration.
    // curry.png is therefore the savory protein fallback.
    // ===========================================================

    if (_containsAny(name, [
      'chicken',
      'chickens',
      'beef',
      'steak',
      'steaks',
      'lamb',
      'mutton',
      'pork',
      'pork chop',
      'pork chops',
      'turkey',
      'duck',
      'goat',
      'fish',
      'salmon',
      'tuna',
      'cod',
      'tilapia',
      'prawn',
      'prawns',
      'shrimp',
      'shrimps',
      'seafood',
      'crab',
      'crabs',
      'lobster',
      'lobsters',
      'squid',
      'octopus',
    ])) {
      return '$_basePath/curry.png';
    }

    // ===========================================================
    // 13. BREAKFAST CATEGORY FALLBACK
    // ===========================================================

    if (_containsAny(categoryName, ['breakfast', 'brunch'])) {
      return '$_basePath/breakfast.png';
    }

    // ===========================================================
    // 14. DESSERT CATEGORY FALLBACK
    // ===========================================================

    if (_containsAny(categoryName, ['dessert', 'sweet'])) {
      return '$_basePath/dessert.png';
    }

    // ===========================================================
    // 15. DRINK CATEGORY FALLBACK
    // ===========================================================

    if (_containsAny(categoryName, [
      'drink',
      'drinks',
      'beverage',
      'beverages',
      'cocktail',
    ])) {
      return '$_basePath/smoothie.png';
    }

    // ===========================================================
    // 16. GENERIC FALLBACK
    // ===========================================================

    return '$_basePath/curry.png';
  }

  // =============================================================
  // NORMALIZE
  // =============================================================

  static String _normalize(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // =============================================================
  // KEYWORD SEARCH
  // =============================================================

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final normalizedKeyword = _normalize(keyword);

      if (_containsWholePhrase(text, normalizedKeyword)) {
        return true;
      }
    }

    return false;
  }

  // =============================================================
  // WHOLE WORD / WHOLE PHRASE MATCH
  // =============================================================

  static bool _containsWholePhrase(String text, String phrase) {
    final escaped = RegExp.escape(phrase);

    final pattern = RegExp(r'(?<![a-z0-9])' + escaped + r'(?![a-z0-9])');

    return pattern.hasMatch(text);
  }
}
