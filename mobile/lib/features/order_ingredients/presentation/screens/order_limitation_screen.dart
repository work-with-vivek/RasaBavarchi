import 'dart:math';

import 'package:flutter/material.dart';

import 'package:mobile/features/shopping/data/models/shopping_cart_item_model.dart';

// =============================================================
// ORDER LIMITATION SCREEN
// =============================================================

class OrderLimitationScreen extends StatefulWidget {
  const OrderLimitationScreen({
    super.key,
    required this.items,
    required this.recipeTitle,
    required this.selectedServings,
  });

  final List<ShoppingCartItem> items;
  final String recipeTitle;
  final int selectedServings;

  @override
  State<OrderLimitationScreen> createState() => _OrderLimitationScreenState();
}

// =============================================================
// STATE
// =============================================================

class _OrderLimitationScreenState extends State<OrderLimitationScreen> {
  // ===========================================================
  // RASABAVARCHI THEME
  // ===========================================================

  static const Color _cream = Color(0xFFFDF8ED);
  static const Color _teal = Color(0xFF00695C);
  static const Color _darkTeal = Color(0xFF064E46);
  static const Color _secondaryText = Color(0xFF77736A);
  static const Color _border = Color(0xFFE5D8C8);
  static const Color _lightTeal = Color(0xFFE8F3F1);
  static const Color _lightPeach = Color(0xFFFFD8CC);

  // ===========================================================
  // RANDOM DELIVERY JOKES
  // ===========================================================

  static const List<String> _deliveryJokes = [
    'It’s not food.\nIt’s our delivery system. 😂',

    'We found the ingredient.\nUnfortunately, it needs a ride. 🚚😂',

    'Your recipe is ready.\nOur delivery system is still tying its shoes. 👟😂',

    'The food is prepared.\nThe delivery guy is doing the cardio. 🏃😂',

    'One ingredient away from greatness.\nTime to call the shopping cart! 🛒😂',

    'Your kitchen is ready.\nOur delivery system said, “I’m on my way!” 😎🚚',

    'The recipe asked for one thing.\nWe asked the shopping cart. 😂🛒',

    'Almost cooking time!\nFirst, let’s make the ingredients travel. 🚚🍳',

    'Your pantry did its part.\nNow it’s shopping cart time! 🛒😄',

    'The chef is ready.\nThe ingredients are just taking a little trip. 👨‍🍳🚚',

    'Your recipe is waiting.\nThe ingredients are catching a ride. 🚗🥕😂',

    'The kitchen called.\nIt says we need one more delivery. 📞😂',

    'Cooking is easy.\nGetting ingredients to the kitchen is our job. 😎🛒',

    'The missing ingredient has been located.\nNow we just need to move it! 🚚😂',

    'Your pantry has spoken.\nThe shopping cart has been summoned. 🛒✨',
  ];

  late final String _selectedJoke;

  // ===========================================================
  // INIT
  // ===========================================================

  @override
  void initState() {
    super.initState();

    _selectedJoke = _deliveryJokes[Random().nextInt(_deliveryJokes.length)];
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final ingredientCount = widget.items.length;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopBar(context),

                const SizedBox(height: 4),

                _buildChefIcon(),

                const SizedBox(height: 24),

                _buildTitle(),

                const SizedBox(height: 28),

                _buildMessage(),

                const SizedBox(height: 24),

                _buildCartInfo(ingredientCount),

                const SizedBox(height: 14),

                _buildIngredientCount(ingredientCount),

                const SizedBox(height: 22),

                _buildContinueButton(context),

                const SizedBox(height: 12),

                _buildCancelButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // TOP BAR
  // ===========================================================

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          splashRadius: 22,
          icon: const Icon(Icons.close, size: 27, color: _secondaryText),
        ),
      ),
    );
  }

  // ===========================================================
  // CHEF ICON
  // ===========================================================

  Widget _buildChefIcon() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: _lightPeach,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Center(child: Text('🧑‍🍳', style: TextStyle(fontSize: 48))),
    );
  }

  // ===========================================================
  // TITLE
  // ===========================================================

  Widget _buildTitle() {
    return const Text(
      'One last ingredient is missing...',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _darkTeal,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }

  // ===========================================================
  // RANDOM MESSAGE
  // ===========================================================

  Widget _buildMessage() {
    return Text(
      _selectedJoke,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _secondaryText,
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
    );
  }

  // ===========================================================
  // CART INFO
  // ===========================================================

  Widget _buildCartInfo(int ingredientCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _lightTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: _teal,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                ingredientCount == 1
                    ? 'Your selected ingredient is ready for the shopping cart.'
                    : 'Your selected ingredients are ready for the shopping cart.',
                style: const TextStyle(
                  color: _darkTeal,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // INGREDIENT COUNT
  // ===========================================================

  Widget _buildIngredientCount(int ingredientCount) {
    return Text(
      ingredientCount == 1
          ? '1 ingredient selected'
          : '$ingredientCount ingredients selected',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _secondaryText,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ===========================================================
  // CONTINUE BUTTON
  // ===========================================================

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop(true);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: const Icon(Icons.shopping_cart_outlined, size: 22),
        label: const Text(
          'Continue to Shopping Cart',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ===========================================================
  // CANCEL BUTTON
  // ===========================================================

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop(false);
      },
      style: TextButton.styleFrom(
        foregroundColor: _teal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: const Text(
        'Cancel',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
