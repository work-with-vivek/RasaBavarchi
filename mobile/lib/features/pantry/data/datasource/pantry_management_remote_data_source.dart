import 'package:dio/dio.dart';

import 'package:mobile/features/pantry/data/models/pantry_item_model.dart';

class PantryManagementRemoteDataSource {
  const PantryManagementRemoteDataSource(this._dio);

  final Dio _dio;

  // =========================================================
  // INGREDIENT LOOKUP
  // =========================================================

  Future<Map<String, dynamic>> getIngredientByName(String name) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw const FormatException('Ingredient name cannot be empty.');
    }

    try {
      final response = await _dio.get(
        '/ingredients/by-name',
        queryParameters: {'name': normalizedName},
      );

      if (response.data is! Map<String, dynamic>) {
        throw const FormatException('Invalid ingredient response.');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        rethrow;
      }
    }

    // Fallback to ingredient search.
    final matches = await searchIngredients(normalizedName);

    final normalizedSearchName = _normalizeIngredientName(normalizedName);

    for (final ingredient in matches) {
      final id = ingredient['id'];
      final ingredientName = ingredient['name'];

      if (id is! String || id.isEmpty) {
        continue;
      }

      if (ingredientName is! String || ingredientName.trim().isEmpty) {
        continue;
      }

      final candidateName = _normalizeIngredientName(ingredientName);

      if (candidateName == normalizedSearchName) {
        return ingredient;
      }
    }

    throw DioException(
      requestOptions: RequestOptions(path: '/ingredients/by-name'),
      response: Response(
        requestOptions: RequestOptions(path: '/ingredients/by-name'),
        statusCode: 404,
        data: {'detail': 'Ingredient not found: $normalizedName'},
      ),
      message: 'Ingredient not found: $normalizedName',
    );
  }

  // =========================================================
  // INGREDIENT SEARCH
  // =========================================================

  Future<List<Map<String, dynamic>>> searchIngredients(String name) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      return [];
    }

    final response = await _dio.get(
      '/ingredients/search',
      queryParameters: {'name': normalizedName, 'limit': 10},
    );

    if (response.data is! List) {
      throw const FormatException('Invalid ingredient search response.');
    }

    return (response.data as List).whereType<Map<String, dynamic>>().toList();
  }
  // =========================================================
  // GET ALL UNITS
  // =========================================================

  Future<List<Map<String, dynamic>>> getUnits() async {
    final response = await _dio.get('/units');

    if (response.data is! List) {
      throw const FormatException('Invalid units response.');
    }

    return (response.data as List).whereType<Map<String, dynamic>>().toList();
  }

  // =========================================================
  // UNIT LOOKUP
  // =========================================================

  Future<Map<String, dynamic>> getUnitBySymbol(String symbol) async {
    final normalizedSymbol = symbol.trim().toLowerCase();

    if (normalizedSymbol.isEmpty) {
      throw const FormatException('Unit symbol cannot be empty.');
    }

    // ---------------------------------------------------------
    // 1. Try exact symbol.
    // ---------------------------------------------------------

    try {
      final response = await _dio.get(
        '/units/by-symbol',
        queryParameters: {'symbol': normalizedSymbol},
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw const FormatException('Invalid unit response.');
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        rethrow;
      }
    }

    // ---------------------------------------------------------
    // 2. Try known aliases.
    // ---------------------------------------------------------

    final aliases = <String>[];

    switch (normalizedSymbol) {
      // Pieces
      case 'pc':
        aliases.addAll(['piece', 'pieces']);
        break;

      case 'piece':
        aliases.addAll(['pc', 'pieces']);
        break;

      case 'pieces':
        aliases.addAll(['pc', 'piece']);
        break;

      // Weight
      case 'g':
        aliases.addAll(['gram', 'grams']);
        break;

      case 'gram':
        aliases.addAll(['g', 'grams']);
        break;

      case 'grams':
        aliases.addAll(['g', 'gram']);
        break;

      case 'kg':
        aliases.addAll(['kilogram', 'kilograms']);
        break;

      case 'kilogram':
        aliases.addAll(['kg', 'kilograms']);
        break;

      case 'kilograms':
        aliases.addAll(['kg', 'kilogram']);
        break;

      // Volume
      case 'ml':
        aliases.addAll([
          'milliliter',
          'milliliters',
          'millilitre',
          'millilitres',
        ]);
        break;

      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
        aliases.addAll(['ml']);
        break;

      case 'l':
        aliases.addAll(['liter', 'liters', 'litre', 'litres']);
        break;

      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        aliases.addAll(['l']);
        break;

      // Cooking measurements
      case 'tbsp':
        aliases.addAll(['tablespoon', 'tablespoons']);
        break;

      case 'tablespoon':
      case 'tablespoons':
        aliases.addAll(['tbsp']);
        break;

      case 'tsp':
        aliases.addAll(['teaspoon', 'teaspoons']);
        break;

      case 'teaspoon':
      case 'teaspoons':
        aliases.addAll(['tsp']);
        break;

      case 'cup':
        aliases.add('cups');
        break;

      case 'cups':
        aliases.add('cup');
        break;

      case 'pinch':
        aliases.add('pinches');
        break;

      case 'pinches':
        aliases.add('pinch');
        break;
    }

    // ---------------------------------------------------------
    // 3. Try aliases one by one.
    // ---------------------------------------------------------

    for (final alias in aliases) {
      if (alias.isEmpty || alias == normalizedSymbol) {
        continue;
      }

      try {
        final response = await _dio.get(
          '/units/by-symbol',
          queryParameters: {'symbol': alias},
        );

        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      } on DioException catch (error) {
        if (error.response?.statusCode != 404) {
          rethrow;
        }
      }
    }

    // ---------------------------------------------------------
    // 4. Nothing matched.
    // ---------------------------------------------------------

    throw DioException(
      requestOptions: RequestOptions(path: '/units/by-symbol'),
      response: Response(
        requestOptions: RequestOptions(path: '/units/by-symbol'),
        statusCode: 404,
        data: {'detail': 'Unit not found: $normalizedSymbol'},
      ),
      message: 'Unit not found: $normalizedSymbol',
    );
  }

  // =========================================================
  // ADD PANTRY ITEM
  // =========================================================

  Future<PantryItemModel> addPantryItem({
    required String ingredientId,
    required double quantity,
    required String unitId,
    DateTime? expiresAt,
  }) async {
    final response = await _dio.post(
      '/pantry/items',
      data: {
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit_id': unitId,
        'expires_at': expiresAt?.toIso8601String(),
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid pantry item response.');
    }

    return PantryItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // UPDATE PANTRY ITEM
  // =========================================================

  Future<PantryItemModel> updatePantryItem({
    required String itemId,
    required double quantity,
    required String unitId,
    DateTime? expiresAt,
  }) async {
    final response = await _dio.put(
      '/pantry/items/$itemId',
      data: {
        'quantity': quantity,
        'unit_id': unitId,
        'expires_at': expiresAt?.toIso8601String(),
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Invalid updated pantry item response.');
    }

    return PantryItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  // =========================================================
  // DELETE PANTRY ITEM
  // =========================================================

  Future<void> deletePantryItem(String itemId) async {
    await _dio.delete('/pantry/items/$itemId');
  }

  // =========================================================
  // INGREDIENT NAME NORMALIZATION
  // =========================================================

  String _normalizeIngredientName(String name) {
    final words = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(_normalizeWord)
        .toList();

    return words.join(' ');
  }

  // =========================================================
  // WORD NORMALIZATION
  // =========================================================

  String _normalizeWord(String word) {
    // berries -> berry
    if (word.length > 3 && word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }

    // tomatoes -> tomato
    // potatoes -> potato
    if (word.length > 3 && word.endsWith('oes')) {
      return word.substring(0, word.length - 2);
    }

    // onions -> onion
    // carrots -> carrot
    if (word.length > 3 && word.endsWith('s')) {
      return word.substring(0, word.length - 1);
    }

    return word;
  }
}
