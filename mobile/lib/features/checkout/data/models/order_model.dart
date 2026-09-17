import 'package:mobile/features/checkout/data/models/delivery_address_model.dart';
import 'package:mobile/features/shopping/data/models/shopping_cart_item_model.dart';
import 'package:mobile/features/shopping/domain/entities/shopping_provider.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.recipeTitle,
    required this.selectedServings,
    required this.items,
    required this.provider,
    required this.address,
    required this.productsTotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String recipeTitle;
  final int selectedServings;
  final List<ShoppingCartItem> items;
  final ShoppingProvider provider;
  final DeliveryAddress address;
  final double productsTotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
}

enum OrderStatus { placed, preparing, outForDelivery, delivered }
