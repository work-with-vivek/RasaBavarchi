import 'package:flutter/material.dart';

import 'package:mobile/features/shopping/data/models/shopping_cart_item_model.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({
    super.key,
    required this.items,
    required this.recipeTitle,
    required this.selectedServings,
  });

  final List<ShoppingCartItem> items;
  final String recipeTitle;
  final int selectedServings;

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  late List<ShoppingCartItem> _cartItems;

  @override
  void initState() {
    super.initState();

    _cartItems = List<ShoppingCartItem>.from(widget.items);
  }

  // =========================================================
  // TOTAL PRICE
  // =========================================================

  double get _totalPrice {
    return _cartItems.fold(0.0, (total, item) => total + item.totalPrice);
  }

  // =========================================================
  // FORMAT QUANTITY
  // =========================================================

  String _formatQuantity(double quantity) {
    if (quantity <= 0) {
      return '0';
    }

    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    final value = quantity.toStringAsFixed(2);

    if (value.endsWith('0')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  // =========================================================
  // FORMAT PRICE
  // =========================================================

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(0)}';
  }

  // =========================================================
  // REMOVE ITEM
  // =========================================================

  void _removeItem(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    setState(() {
      _cartItems.removeAt(index);
    });
  }

  // =========================================================
  // CHOOSE PROVIDER
  // =========================================================
  //
  // Intentionally disabled for the current version.
  //
  // Provider selection, delivery address, checkout and order
  // screens remain in the project for future development.
  // =========================================================

  void _chooseProvider() {
    // Intentionally does nothing.
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (_cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping Cart')),
        body: const _EmptyCart(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: Column(
        children: [
          _CartHeader(
            recipeTitle: widget.recipeTitle,
            selectedServings: widget.selectedServings,
            itemCount: _cartItems.length,
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];

                return _CartItemCard(
                  item: item,
                  formatQuantity: _formatQuantity,
                  formatPrice: _formatPrice,
                  onRemove: () {
                    _removeItem(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CheckoutBar(
        totalPrice: _totalPrice,
        formatPrice: _formatPrice,
        onPressed: _chooseProvider,
      ),
    );
  }
}

// =============================================================
// CART HEADER
// =============================================================

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.recipeTitle,
    required this.selectedServings,
    required this.itemCount,
  });

  final String recipeTitle;
  final int selectedServings;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: theme.colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipeTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Ingredients for '
            '$selectedServings '
            '${selectedServings == 1 ? 'person' : 'people'}',
          ),

          const SizedBox(height: 8),

          Text(
            '$itemCount '
            '${itemCount == 1 ? 'item' : 'items'}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// CART ITEM CARD
// =============================================================

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.formatQuantity,
    required this.formatPrice,
    required this.onRemove,
  });

  final ShoppingCartItem item;

  final String Function(double) formatQuantity;

  final String Function(double) formatPrice;

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool hasSpecifiedQuantity = item.ingredient.hasSpecifiedQuantity;

    // ---------------------------------------------------------
    // REQUIRED QUANTITY
    // ---------------------------------------------------------

    final String requiredQuantity = hasSpecifiedQuantity
        ? '${formatQuantity(item.ingredient.missingQuantity)} '
              '${item.ingredient.unit}'
        : 'Quantity not specified';

    // ---------------------------------------------------------
    // PACK SIZE
    // ---------------------------------------------------------

    final String packSize;

    if (item.product.provider == 'Ingredient') {
      packSize = 'Not specified';
    } else {
      packSize =
          '${formatQuantity(item.product.quantity)} '
          '${item.product.unit}';
    }

    // ---------------------------------------------------------
    // TOTAL / GETTING QUANTITY
    // ---------------------------------------------------------

    final String totalQuantity;

    if (!hasSpecifiedQuantity) {
      if (item.product.provider == 'Ingredient') {
        totalQuantity = 'Quantity not specified';
      } else {
        totalQuantity =
            '${item.packCount} '
            '${item.packCount == 1 ? 'pack' : 'packs'}';
      }
    } else {
      totalQuantity =
          '${formatQuantity(item.totalQuantity)} '
          '${item.ingredient.unit}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // =================================================
            // PRODUCT HEADER
            // =================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------
                // PRODUCT ICON
                // -------------------------------------------------

                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.product.provider == 'Ingredient'
                        ? Icons.restaurant_outlined
                        : Icons.local_grocery_store_outlined,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 12),

                // -------------------------------------------------
                // PRODUCT INFO
                // -------------------------------------------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        item.product.brand,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // -------------------------------------------------
                      // PACK INFORMATION
                      // -------------------------------------------------
                      if (item.product.provider != 'Ingredient')
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _InfoChip(label: 'Pack $packSize'),
                            _InfoChip(
                              label:
                                  '${item.packCount} '
                                  '${item.packCount == 1 ? 'pack' : 'packs'}',
                            ),
                          ],
                        )
                      else
                        const _InfoChip(label: 'Ingredient item'),
                    ],
                  ),
                ),

                // -------------------------------------------------
                // DELETE
                // -------------------------------------------------
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =================================================
            // QUANTITY SUMMARY
            // =================================================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // -------------------------------------------------
                  // REQUIRED / GETTING
                  // -------------------------------------------------

                  Row(
                    children: [
                      Expanded(
                        child: _QuantityInfo(
                          label: 'Required',
                          value: requiredQuantity,
                        ),
                      ),

                      Expanded(
                        child: _QuantityInfo(
                          label: 'Getting',
                          value: totalQuantity,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // -------------------------------------------------
                  // PACK SIZE / PACK COUNT
                  // -------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: _QuantityInfo(
                          label: 'Pack size',
                          value: packSize,
                        ),
                      ),

                      Expanded(
                        child: _QuantityInfo(
                          label: 'Packs',
                          value: item.packCount.toString(),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // -------------------------------------------------
                  // TOTAL PRICE
                  // -------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total price',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      Text(
                        formatPrice(item.totalPrice),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
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
// INFO CHIP
// =============================================================

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================
// QUANTITY INFO
// =============================================================

class _QuantityInfo extends StatelessWidget {
  const _QuantityInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),

        const SizedBox(height: 2),

        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// =============================================================
// CHECKOUT BAR
// =============================================================

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.totalPrice,
    required this.formatPrice,
    required this.onPressed,
  });

  final double totalPrice;

  final String Function(double) formatPrice;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // =================================================
            // TOTAL
            // =================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  formatPrice(totalPrice),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =================================================
            // PROVIDER BUTTON
            // =================================================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text(
                  'Choose Delivery Provider',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// EMPTY CART
// =============================================================

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),

            const SizedBox(height: 16),

            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'No ingredients are selected.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
