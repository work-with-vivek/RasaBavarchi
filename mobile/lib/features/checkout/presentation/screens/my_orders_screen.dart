import 'package:flutter/material.dart';

import 'package:mobile/features/checkout/data/models/order_model.dart';
import 'package:mobile/features/checkout/data/repositories/order_repository.dart';
import 'package:mobile/features/checkout/presentation/screens/order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<OrderModel> get _orders {
    return OrderRepository.instance.orders;
  }

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:$minute $period';
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

  void _openOrder(OrderModel order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        )
        .then((_) {
          if (mounted) {
            setState(() {});
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = _orders;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? const _EmptyOrders()
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];

                  return _OrderCard(
                    order: order,
                    theme: theme,
                    formatDate: _formatDate,
                    formatTime: _formatTime,
                    formatPrice: _formatPrice,
                    statusText: _statusText,
                    statusIcon: _statusIcon,
                    statusColor: _statusColor,
                    onTap: () => _openOrder(order),
                  );
                },
              ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.theme,
    required this.formatDate,
    required this.formatTime,
    required this.formatPrice,
    required this.statusText,
    required this.statusIcon,
    required this.statusColor,
    required this.onTap,
  });

  final OrderModel order;
  final ThemeData theme;

  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final String Function(double) formatPrice;

  final String Function(OrderStatus) statusText;
  final IconData Function(OrderStatus) statusIcon;
  final Color Function(BuildContext, OrderStatus) statusColor;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.recipeTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Order ${order.id}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon(order.status), color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText(order.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _OrderInfo(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: formatDate(order.createdAt),
                    ),
                  ),
                  Expanded(
                    child: _OrderInfo(
                      icon: Icons.access_time_outlined,
                      label: 'Time',
                      value: formatTime(order.createdAt),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _OrderInfo(
                      icon: Icons.storefront_outlined,
                      label: 'Provider',
                      value: order.provider.name,
                    ),
                  ),
                  Expanded(
                    child: _OrderInfo(
                      icon: Icons.people_alt_outlined,
                      label: 'Servings',
                      value: '${order.selectedServings}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Divider(),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${order.items.length} '
                    '${order.items.length == 1 ? 'ingredient' : 'ingredients'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    formatPrice(order.total),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderInfo extends StatelessWidget {
  const _OrderInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No orders yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your grocery orders will appear here '
              'after you place an order.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
