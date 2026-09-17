import 'package:mobile/features/checkout/data/models/order_model.dart';

class OrderRepository {
  OrderRepository._();

  static final OrderRepository instance = OrderRepository._();

  final List<OrderModel> _orders = [];

  List<OrderModel> get orders {
    return List.unmodifiable(_orders.reversed);
  }

  void addOrder(OrderModel order) {
    _orders.add(order);
  }

  OrderModel? getOrderById(String id) {
    for (final order in _orders) {
      if (order.id == id) {
        return order;
      }
    }

    return null;
  }
}
