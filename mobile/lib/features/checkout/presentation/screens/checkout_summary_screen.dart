import 'package:flutter/material.dart';

import 'package:mobile/features/checkout/data/models/delivery_address_model.dart';
import 'package:mobile/features/checkout/data/models/order_model.dart';
import 'package:mobile/features/checkout/data/repositories/order_repository.dart';
import 'package:mobile/features/checkout/presentation/screens/order_success_screen.dart';
import 'package:mobile/features/shopping/data/models/shopping_cart_item_model.dart';
import 'package:mobile/features/shopping/domain/entities/shopping_provider.dart';

class CheckoutSummaryScreen extends StatelessWidget {
  const CheckoutSummaryScreen({
    super.key,
    required this.items,
    required this.recipeTitle,
    required this.selectedServings,
    required this.provider,
    required this.address,
  });

  final List<ShoppingCartItem> items;
  final String recipeTitle;
  final int selectedServings;
  final ShoppingProvider provider;
  final DeliveryAddress address;

  double get productsTotal {
    return items.fold(0.0, (total, item) => total + item.totalPrice);
  }

  double get deliveryFee {
    return provider.deliveryFee;
  }

  double get grandTotal {
    return productsTotal + deliveryFee;
  }

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(0)}';
  }

  String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return 'RB-${timestamp.toString().substring(5)}';
  }

  void _placeOrder(BuildContext context) {
    final order = OrderModel(
      id: _generateOrderId(),
      recipeTitle: recipeTitle,
      selectedServings: selectedServings,
      items: items,
      provider: provider,
      address: address,
      productsTotal: productsTotal,
      deliveryFee: deliveryFee,
      total: grandTotal,
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
    );

    OrderRepository.instance.addOrder(order);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Review Your Order',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your details before placing the order.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Recipe
          _SectionCard(
            title: 'Recipe',
            icon: Icons.restaurant_menu_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipeTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cooking for $selectedServings '
                  '${selectedServings == 1 ? 'person' : 'people'}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Delivery Provider
          _SectionCard(
            title: 'Delivery Provider',
            icon: Icons.local_shipping_outlined,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Delivery in ${provider.deliveryTime}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Text(
                  provider.deliveryFee == 0
                      ? 'FREE'
                      : _formatPrice(provider.deliveryFee),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Delivery Address
          _SectionCard(
            title: 'Delivery Address',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(address.phone),
                const SizedBox(height: 6),
                Text(
                  address.formattedAddress,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Items
          _SectionCard(
            title: 'Items',
            icon: Icons.shopping_bag_outlined,
            child: Column(
              children: [
                for (final item in items)
                  _CheckoutItem(item: item, formatPrice: _formatPrice),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Payment Summary
          _SectionCard(
            title: 'Payment Summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Products',
                  value: _formatPrice(productsTotal),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Delivery',
                  value: deliveryFee == 0 ? 'FREE' : _formatPrice(deliveryFee),
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total',
                  value: _formatPrice(grandTotal),
                  emphasize: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Place Order
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => _placeOrder(context),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'Place Order • ${_formatPrice(grandTotal)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 21),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _CheckoutItem extends StatelessWidget {
  const _CheckoutItem({required this.item, required this.formatPrice});

  final ShoppingCartItem item;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.product.quantity} '
                  '${item.product.unit} × '
                  '${item.packCount} packs',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatPrice(item.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasize ? 17 : 14,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
