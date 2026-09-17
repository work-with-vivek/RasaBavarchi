import 'package:flutter/material.dart';

import 'package:mobile/features/checkout/data/models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final OrderModel order;

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(0)}';
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant_outlined;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining_outlined;
      case OrderStatus.delivered:
        return Icons.done_all;
    }
  }

  Color _statusColor(BuildContext context, OrderStatus status) {
    final theme = Theme.of(context);

    switch (status) {
      case OrderStatus.placed:
        return theme.colorScheme.primary;
      case OrderStatus.preparing:
        return Colors.orange.shade700;
      case OrderStatus.outForDelivery:
        return Colors.blue.shade700;
      case OrderStatus.delivered:
        return Colors.green.shade700;
    }
  }

  int _statusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.delivered:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, order.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _OrderStatusHeader(
            status: order.status,
            statusText: _statusText(order.status),
            statusIcon: _statusIcon(order.status),
            statusColor: statusColor,
            orderId: order.id,
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: 'Order Status',
            icon: Icons.track_changes_outlined,
            child: _OrderStatusTimeline(
              currentStatusIndex: _statusIndex(order.status),
            ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: 'Recipe',
            icon: Icons.restaurant_menu_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.recipeTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'For ${order.selectedServings} '
                  '${order.selectedServings == 1 ? 'person' : 'people'}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: 'Items',
            icon: Icons.shopping_bag_outlined,
            child: Column(
              children: [
                for (int index = 0; index < order.items.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == order.items.length - 1 ? 0 : 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_grocery_store_outlined,
                            color: theme.colorScheme.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.items[index].product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.items[index].product.quantity} '
                                '${order.items[index].product.unit} × '
                                '${order.items[index].packCount} packs',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatPrice(order.items[index].totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: 'Delivery',
            icon: Icons.local_shipping_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.provider.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimated delivery: '
                            '${order.provider.deliveryTime}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: 'Address',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.address.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(order.address.phone),
                const SizedBox(height: 5),
                Text(order.address.formattedAddress),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: 'Payment Summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Products',
                  value: _formatPrice(order.productsTotal),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Delivery',
                  value: order.deliveryFee == 0
                      ? 'FREE'
                      : _formatPrice(order.deliveryFee),
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total',
                  value: _formatPrice(order.total),
                  emphasize: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OrderStatusHeader extends StatelessWidget {
  const _OrderStatusHeader({
    required this.status,
    required this.statusText,
    required this.statusIcon,
    required this.statusColor,
    required this.orderId,
  });

  final OrderStatus status;
  final String statusText;
  final IconData statusIcon;
  final Color statusColor;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, size: 40, color: statusColor),
            ),
            const SizedBox(height: 14),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Order ID: $orderId',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusTimeline extends StatelessWidget {
  const _OrderStatusTimeline({required this.currentStatusIndex});

  final int currentStatusIndex;

  static const _statuses = [
    (
      title: 'Order Placed',
      subtitle: 'Your order has been received',
      icon: Icons.check_circle_outline,
    ),
    (
      title: 'Preparing',
      subtitle: 'Your ingredients are being prepared',
      icon: Icons.restaurant_outlined,
    ),
    (
      title: 'Out for Delivery',
      subtitle: 'Your order is on the way',
      icon: Icons.delivery_dining_outlined,
    ),
    (
      title: 'Delivered',
      subtitle: 'Order delivered successfully',
      icon: Icons.done_all,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (int index = 0; index < _statuses.length; index++)
          _TimelineItem(
            title: _statuses[index].title,
            subtitle: _statuses[index].subtitle,
            icon: _statuses[index].icon,
            isCompleted: index <= currentStatusIndex,
            isCurrent: index == currentStatusIndex,
            isLast: index == _statuses.length - 1,
            primaryColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.primaryColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.grey.shade400;
    final activeColor = isCompleted ? primaryColor : inactiveColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? primaryColor.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Icon(icon, size: 20, color: activeColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: indexLineColor(context, isCompleted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCompleted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isCompleted
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color indexLineColor(BuildContext context, bool completed) {
    if (completed) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.45);
    }

    return Colors.grey.shade300;
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
