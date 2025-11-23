import 'cart.dart';
import 'user.dart';

class OrderItem {
  final String item;
  final String topCookie;
  final String bottomCookie;
  final int quantity;
  final double price;

  OrderItem({
    required this.item,
    required this.topCookie,
    required this.bottomCookie,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'topCookie': topCookie,
      'bottomCookie': bottomCookie,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      item: json['item'] ?? '',
      topCookie: json['topCookie'] ?? '',
      bottomCookie: json['bottomCookie'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price']?.toDouble() ?? 0.0,
    );
  }
}

// Create a model for order delivery status
enum OrderStatus { pending, accepted, preparing, delivering, completed, cancelled }

// Create a model for delivery order
class DeliveryOrder {
  final String id;
  final User customer;
  final User driver;
  final Cart cart;
  final double total;
  OrderStatus status;
  DateTime orderTime;

  DeliveryOrder({
    required this.id,
    required this.customer,
    required this.driver,
    required this.cart,
    required this.total,
    this.status = OrderStatus.pending,
    required this.orderTime,
  });
}
