import 'order.dart';

class Cart {
  static final Cart _instance = Cart._internal();

  factory Cart() {
    return _instance;
  }

  Cart._internal();

  String? restaurantName; // Added restaurant name to cart
  List<OrderItem> orders = [];

  void addOrder(OrderItem order) {
    orders.add(order);
  }

  double get total {
    return orders.fold(0, (sum, order) => sum + (order.price * order.quantity));
  }

  bool get isEmpty {
    return orders.isEmpty;
  }

  void clear() {
    orders.clear();
  }
}
