import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/order_ingredients/presentation/screens/order_limitation_screen.dart';
import 'package:mobile/features/pantry/data/models/pantry_comparison_model.dart';
import 'package:mobile/features/shopping/data/models/grocery_product_model.dart';
import 'package:mobile/features/shopping/data/models/shopping_cart_item_model.dart';
import 'package:mobile/features/shopping/presentation/providers/shopping_provider.dart';

// ============================================================
// RASABAVARCHI THEME
// ============================================================

const Color _cream = Color(0xFFFDF8ED);
const Color _teal = Color(0xFF00695C);
const Color _darkTeal = Color(0xFF064E46);
const Color _brown = Color(0xFF9C513A);
const Color _lightTeal = Color(0xFFE8F3F1);
const Color _lightPeach = Color(0xFFFFD8CC);
const Color _lightGreen = Color(0xFFE8F5E9);
const Color _text = Color(0xFF252525);
const Color _secondaryText = Color(0xFF77736A);
const Color _border = Color(0xFFE5D8C8);

class ProductMatchingScreen extends ConsumerStatefulWidget {
  const ProductMatchingScreen({
    super.key,
    required this.missingItems,
    required this.selectedServings,
    required this.recipeTitle,
  });

  final List<PantryComparisonItem> missingItems;
  final int selectedServings;
  final String recipeTitle;

  @override
  ConsumerState<ProductMatchingScreen> createState() =>
      _ProductMatchingScreenState();
}

class _ProductMatchingScreenState extends ConsumerState<ProductMatchingScreen> {
  final Map<String, GroceryProductModel> _selectedProducts = {};

  // ============================================================
  // NORMALIZE NAME
  // ============================================================

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ============================================================
  // PRODUCT MATCHING
  // ============================================================

  bool _isValidProductMatch(
    String ingredientName,
    GroceryProductModel product,
    PantryComparisonItem ingredient,
  ) {
    final ingredientNameNormalized = _normalizeName(ingredientName);

    final productIngredientNormalized = _normalizeName(product.ingredientName);

    if (ingredientNameNormalized != productIngredientNormalized) {
      return false;
    }

    // If recipe quantity is not specified,
    // do not require unit matching.
    if (!ingredient.hasSpecifiedQuantity) {
      return true;
    }

    final productUnit = _normalizeUnit(product.unit);
    final recipeUnit = _normalizeUnit(ingredient.unit);

    if (productUnit == recipeUnit) {
      return true;
    }

    final converted = _convertQuantity(1.0, productUnit, recipeUnit);

    return converted != null;
  }

  // ============================================================
  // FALLBACK PRODUCT
  // ============================================================

  GroceryProductModel _createFallbackProduct(PantryComparisonItem ingredient) {
    return GroceryProductModel(
      id: '${ingredient.recipeIngredient.id}-ingredient',
      name: ingredient.recipeIngredient.name,
      brand: 'Ingredient',
      ingredientName: ingredient.recipeIngredient.name,
      quantity: ingredient.hasSpecifiedQuantity
          ? ingredient.missingQuantity
          : 0.0,
      unit: ingredient.hasSpecifiedQuantity ? ingredient.unit : 'unknown',
      price: 0,
      provider: 'Ingredient',
      imageUrl: null,
    );
  }

  // ============================================================
  // ADD TO CART / SELECT PRODUCT
  // ============================================================

  void _addToCart(
    PantryComparisonItem ingredient,
    GroceryProductModel product,
  ) {
    setState(() {
      _selectedProducts[ingredient.recipeIngredient.id] = product;
    });
  }

  // ============================================================
  // REMOVE
  // ============================================================

  void _removeFromCart(PantryComparisonItem ingredient) {
    setState(() {
      _selectedProducts.remove(ingredient.recipeIngredient.id);
    });
  }

  // ============================================================
  // FORMAT QUANTITY
  // ============================================================

  String _formatQuantity(double quantity) {
    if (quantity <= 0) {
      return '0';
    }

    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(1);
  }

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(0)}';
  }

  // ============================================================
  // NORMALIZE UNIT
  // ============================================================

  String _normalizeUnit(String unit) {
    final normalized = unit.trim().toLowerCase();

    switch (normalized) {
      case 'gram':
      case 'grams':
      case 'g':
        return 'g';

      case 'kilogram':
      case 'kilograms':
      case 'kg':
        return 'kg';

      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
      case 'ml':
        return 'ml';

      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
      case 'l':
        return 'l';

      case 'piece':
      case 'pieces':
      case 'pc':
        return 'pc';

      case 'cup':
      case 'cups':
        return 'cup';

      case 'pinch':
      case 'pinches':
        return 'pinch';

      case 'tablespoon':
      case 'tablespoons':
      case 'tbsp':
        return 'tbsp';

      case 'teaspoon':
      case 'teaspoons':
      case 'tsp':
        return 'tsp';

      case 'unk':
      case 'unknown':
        return 'unk';

      default:
        return normalized;
    }
  }

  // ============================================================
  // CONVERT QUANTITY
  // ============================================================

  double? _convertQuantity(double quantity, String fromUnit, String toUnit) {
    final from = _normalizeUnit(fromUnit);
    final to = _normalizeUnit(toUnit);

    if (from == to) {
      return quantity;
    }

    // Weight
    if (from == 'g' && to == 'kg') {
      return quantity / 1000.0;
    }

    if (from == 'kg' && to == 'g') {
      return quantity * 1000.0;
    }

    // Volume
    if (from == 'ml' && to == 'l') {
      return quantity / 1000.0;
    }

    if (from == 'l' && to == 'ml') {
      return quantity * 1000.0;
    }

    // Do not perform unsafe density-dependent conversions.
    return null;
  }

  // ============================================================
  // PACK COUNT
  // ============================================================

  int _calculatePackCount(
    PantryComparisonItem ingredient,
    GroceryProductModel product,
  ) {
    if (product.provider == 'Ingredient') {
      return 1;
    }

    if (!ingredient.hasSpecifiedQuantity) {
      return 1;
    }

    if (product.quantity <= 0) {
      return 1;
    }

    final requiredUnit = _normalizeUnit(ingredient.unit);

    final productUnit = _normalizeUnit(product.unit);

    final quantityInRequiredUnit = _convertQuantity(
      product.quantity,
      productUnit,
      requiredUnit,
    );

    if (quantityInRequiredUnit == null || quantityInRequiredUnit <= 0) {
      return 1;
    }

    final packCount = (ingredient.missingQuantity / quantityInRequiredUnit)
        .ceil();

    return packCount.clamp(1, 999);
  }

  // ============================================================
  // TOTAL QUANTITY
  // ============================================================

  double _calculateTotalQuantity(
    PantryComparisonItem ingredient,
    GroceryProductModel product,
    int packCount,
  ) {
    if (!ingredient.hasSpecifiedQuantity) {
      return 0.0;
    }

    if (product.provider == 'Ingredient') {
      return ingredient.missingQuantity;
    }

    final totalProductQuantity = product.quantity * packCount;

    return _convertQuantity(
          totalProductQuantity,
          product.unit,
          ingredient.unit,
        ) ??
        totalProductQuantity;
  }

  // ============================================================
  // TOTAL PRICE
  // ============================================================

  double get _totalPrice {
    double total = 0;

    for (final entry in _selectedProducts.entries) {
      final ingredient = widget.missingItems.firstWhere(
        (item) => item.recipeIngredient.id == entry.key,
      );

      final product = entry.value;

      final packCount = _calculatePackCount(ingredient, product);

      total += product.price * packCount;
    }

    return total;
  }

  // ============================================================
  // ORDER INGREDIENTS
  // ============================================================

  void _orderIngredients() {
    if (_selectedProducts.isEmpty) {
      return;
    }

    final cartItems = <ShoppingCartItem>[];

    for (final ingredient in widget.missingItems) {
      final product = _selectedProducts[ingredient.recipeIngredient.id];

      if (product == null) {
        continue;
      }

      final packCount = _calculatePackCount(ingredient, product);

      final totalQuantity = _calculateTotalQuantity(
        ingredient,
        product,
        packCount,
      );

      final totalPrice = product.price * packCount;

      cartItems.add(
        ShoppingCartItem(
          ingredient: ingredient,
          product: product,
          packCount: packCount,
          totalQuantity: totalQuantity,
          totalPrice: totalPrice,
        ),
      );
    }

    if (cartItems.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: OrderLimitationScreen(
            items: cartItems,
            recipeTitle: widget.recipeTitle,
            selectedServings: widget.selectedServings,
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedProducts.length;

    final totalIngredients = widget.missingItems.length;

    return Scaffold(
      backgroundColor: _cream,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back, color: _teal, size: 28),
        ),
        title: const Text(
          'Add Ingredients',
          style: TextStyle(
            color: _text,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: Column(
        children: [
          // ========================================================
          // RECIPE HEADER
          // ========================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 15, 22, 18),
            decoration: const BoxDecoration(color: _lightPeach),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipeTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Cooking for '
                  '${widget.selectedServings} '
                  '${widget.selectedServings == 1 ? 'person' : 'people'}',
                  style: const TextStyle(color: _text, fontSize: 16),
                ),

                const SizedBox(height: 7),

                Text(
                  '$totalIngredients '
                  '${totalIngredients == 1 ? 'ingredient' : 'ingredients'} '
                  'needed',
                  style: const TextStyle(
                    color: _brown,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ========================================================
          // INGREDIENT LIST
          // ========================================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              itemCount: widget.missingItems.length,
              itemBuilder: (context, index) {
                final ingredient = widget.missingItems[index];

                final selectedProduct =
                    _selectedProducts[ingredient.recipeIngredient.id];

                return _IngredientProductSection(
                  ingredient: ingredient,
                  selectedProduct: selectedProduct,
                  isValidProductMatch: _isValidProductMatch,
                  createFallbackProduct: _createFallbackProduct,
                  onAdd: (product) {
                    _addToCart(ingredient, product);
                  },
                  onRemove: () {
                    _removeFromCart(ingredient);
                  },
                  formatQuantity: _formatQuantity,
                  formatPrice: _formatPrice,
                );
              },
            ),
          ),
        ],
      ),

      // ==========================================================
      // BOTTOM ORDER BAR
      // ==========================================================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Added',
                      style: TextStyle(color: _secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$selectedCount / '
                      '$totalIngredients',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 21,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_selectedProducts.isNotEmpty && _totalPrice > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatPrice(_totalPrice),
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 16),

              SizedBox(
                width: 175,
                height: 58,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0 ? _orderIngredients : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 21),
                  label: const Text(
                    'ORDER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

// ============================================================================
// INGREDIENT PRODUCT SECTION
// ============================================================================

class _IngredientProductSection extends ConsumerWidget {
  const _IngredientProductSection({
    required this.ingredient,
    required this.selectedProduct,
    required this.isValidProductMatch,
    required this.createFallbackProduct,
    required this.onAdd,
    required this.onRemove,
    required this.formatQuantity,
    required this.formatPrice,
  });

  final PantryComparisonItem ingredient;
  final GroceryProductModel? selectedProduct;

  final bool Function(
    String ingredientName,
    GroceryProductModel product,
    PantryComparisonItem ingredient,
  )
  isValidProductMatch;

  final GroceryProductModel Function(PantryComparisonItem ingredient)
  createFallbackProduct;

  final ValueChanged<GroceryProductModel> onAdd;
  final VoidCallback onRemove;

  final String Function(double quantity) formatQuantity;

  final String Function(double price) formatPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientName = ingredient.recipeIngredient.name;

    final productsState = ref.watch(groceryProductsProvider(ingredientName));

    final quantitySpecified = ingredient.hasSpecifiedQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // INGREDIENT HEADER
          // ========================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredientName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkTeal,
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      quantitySpecified
                          ? 'Need '
                                '${formatQuantity(ingredient.missingQuantity)} '
                                '${ingredient.unit}'
                          : 'Quantity not specified',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              if (selectedProduct != null)
                IconButton(
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(
                    Icons.close,
                    color: _secondaryText,
                    size: 24,
                  ),
                  tooltip: 'Remove',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ========================================================
          // SELECTED PRODUCT
          // ========================================================
          if (selectedProduct != null)
            selectedProduct!.provider == 'Ingredient'
                ? _AddedIngredientCard(
                    ingredient: ingredient,
                    formatQuantity: formatQuantity,
                  )
                : _SelectedProductCard(
                    product: selectedProduct!,
                    formatPrice: formatPrice,
                  )
          else
            productsState.when(
              // ====================================================
              // LOADING
              // ====================================================

              loading: () {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25),
                  child: Center(child: CircularProgressIndicator(color: _teal)),
                );
              },

              // ====================================================
              // ERROR
              // ====================================================
              error: (error, stackTrace) {
                return _NoProductCard(
                  ingredient: ingredient,
                  createFallbackProduct: createFallbackProduct,
                  onAdd: onAdd,
                );
              },

              // ====================================================
              // PRODUCTS
              // ====================================================
              data: (products) {
                final validProducts = products
                    .where(
                      (product) => isValidProductMatch(
                        ingredientName,
                        product,
                        ingredient,
                      ),
                    )
                    .toList();

                if (validProducts.isEmpty) {
                  return _NoProductCard(
                    ingredient: ingredient,
                    createFallbackProduct: createFallbackProduct,
                    onAdd: onAdd,
                  );
                }

                return Column(
                  children: validProducts.map((product) {
                    return _ProductCard(
                      product: product,
                      formatPrice: formatPrice,
                      onAdd: () {
                        onAdd(product);
                      },
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// NO PRODUCT CARD
// ============================================================================

class _NoProductCard extends StatelessWidget {
  const _NoProductCard({
    required this.ingredient,
    required this.createFallbackProduct,
    required this.onAdd,
  });

  final PantryComparisonItem ingredient;

  final GroceryProductModel Function(PantryComparisonItem ingredient)
  createFallbackProduct;

  final ValueChanged<GroceryProductModel> onAdd;

  @override
  Widget build(BuildContext context) {
    final quantitySpecified = ingredient.hasSpecifiedQuantity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No matching product found.',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            quantitySpecified
                ? 'You can still add this ingredient '
                      'to your cart.'
                : 'The recipe does not specify a '
                      'quantity. You can still add '
                      'this ingredient to your cart.',
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 14,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                final fallbackProduct = createFallbackProduct(ingredient);

                onAdd(fallbackProduct);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _brown,
                side: const BorderSide(color: _brown),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
              label: const Text(
                'Add to cart',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PRODUCT CARD
// ============================================================================

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.formatPrice,
    required this.onAdd,
  });

  final GroceryProductModel product;

  final String Function(double price) formatPrice;

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // ========================================================
          // ICON
          // ========================================================

          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: _lightTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_grocery_store_outlined,
              color: _teal,
              size: 29,
            ),
          ),

          const SizedBox(width: 12),

          // ========================================================
          // PRODUCT INFO
          // ========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, fontSize: 13),
                ),

                const SizedBox(height: 3),

                Text(
                  '${product.quantity} '
                  '${product.unit}',
                  style: const TextStyle(color: _secondaryText, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  formatPrice(product.price),
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ========================================================
          // ADD BUTTON
          // ========================================================
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ADDED INGREDIENT CARD
// ============================================================================

class _AddedIngredientCard extends StatelessWidget {
  const _AddedIngredientCard({
    required this.ingredient,
    required this.formatQuantity,
  });

  final PantryComparisonItem ingredient;

  final String Function(double quantity) formatQuantity;

  @override
  Widget build(BuildContext context) {
    final quantitySpecified = ingredient.hasSpecifiedQuantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF388E3C),
              size: 31,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.recipeIngredient.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  quantitySpecified
                      ? '${formatQuantity(ingredient.missingQuantity)} '
                            '${ingredient.unit}'
                      : 'Quantity not specified',
                  style: const TextStyle(color: _secondaryText, fontSize: 14),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Added to cart',
                  style: TextStyle(
                    color: Color(0xFF388E3C),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Icon(Icons.check_circle, color: Color(0xFF388E3C), size: 25),
        ],
      ),
    );
  }
}

// ============================================================================
// SELECTED PRODUCT CARD
// ============================================================================

class _SelectedProductCard extends StatelessWidget {
  const _SelectedProductCard({
    required this.product,
    required this.formatPrice,
  });

  final GroceryProductModel product;

  final String Function(double price) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF388E3C),
              size: 31,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${product.brand} • '
                  '${product.quantity} '
                  '${product.unit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  formatPrice(product.price),
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Added to cart',
                  style: TextStyle(
                    color: Color(0xFF388E3C),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Icon(Icons.check_circle, color: Color(0xFF388E3C), size: 25),
        ],
      ),
    );
  }
}
