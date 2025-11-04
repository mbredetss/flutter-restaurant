import 'order.dart';

class Cart {
  static final Cart _instance = Cart._internal();

  factory Cart() {
    return _instance;
  }

  Cart._internal();

  List<Order> orders = [];

  void addOrder(Order order) {
    orders.add(order);
  }

  double get total {
    return orders.fold(0, (sum, order) => sum + (order.price * order.quantity));
  }
}
