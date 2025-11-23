import 'package:flutter/material.dart';
import 'package:venieats/models/user.dart';
import 'package:venieats/services/user_service.dart';

import '../../constants.dart';
import '../../models/cart.dart';
import '../../models/order.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<DeliveryOrder> _orderHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = UserService.instance.currentUser ?? await UserService.instance.getCurrentUser();

      if (currentUser != null) {
        // Get order IDs from the user's order history
        List<String> orderIds = currentUser.orderHistory;
        List<DeliveryOrder> loadedOrders = [];

        // Load each order from history
        for (String orderId in orderIds) {
          // Try to get from order history first
          Map<String, dynamic>? orderData = await UserService.instance.getOrderHistoryById(orderId);

          // If not in history DB, try loading from active orders (shouldn't happen if implementation is correct)
          orderData ??= await UserService.instance.getActiveOrder(orderId);

          if (orderData != null) {
            // Create the user objects from the stored data
            User customer = User.fromMap(orderData['customer'] ?? {});
            User driver = User.fromMap(orderData['driver'] ?? {});

            // Convert cart orders from JSON if they exist
            List<OrderItem> orderItems = (orderData['cart_orders'] as List?)
                ?.map((item) => OrderItem.fromJson(item))
                .toList() ?? [];

            Cart cart = Cart();
            for (OrderItem item in orderItems) {
              cart.addOrder(item);
            }

            // Create DeliveryOrder with the necessary data
            DeliveryOrder deliveryOrder = DeliveryOrder(
              id: orderId,
              customer: customer,
              driver: driver,
              cart: cart,
              total: (orderData['total'] as num?)?.toDouble() ?? 0.0,
              orderTime: DateTime.fromMillisecondsSinceEpoch(
                (orderData['orderTime'] as int?) ?? DateTime.now().millisecondsSinceEpoch
              ),
              status: _parseOrderStatus(orderData['status']),
            );

            loadedOrders.add(deliveryOrder);
          }
        }

        setState(() {
          _orderHistory = loadedOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately in production code
      // print("Error loading order history: $e");  // Removed for production
    }
  }

  // Parse the order status from the stored string
  OrderStatus _parseOrderStatus(dynamic statusData) {
    if (statusData == null) return OrderStatus.completed; // Default to completed for history

    String statusString = statusData.toString();
    if (statusString.contains('.')) {
      statusString = statusString.split('.').last.toLowerCase();
    } else {
      statusString = statusString.toLowerCase();
    }

    try {
      return OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == statusString,
        orElse: () => OrderStatus.completed, // Default to completed
      );
    } catch (e) {
      return OrderStatus.completed; // Default to completed if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
      ),
      body: Column(
        children: [
          if (_isLoading && _orderHistory.isEmpty)
            Expanded(
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_orderHistory.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No order history yet",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadOrderHistory(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Refresh"),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadOrderHistory(),
                child: ListView.separated(
                  itemCount: _orderHistory.length,
                  separatorBuilder: (context, index) => const SizedBox(height: defaultPadding),
                  itemBuilder: (context, index) {
                    final order = _orderHistory[index];

                    // Only show completed orders in the history
                    if (order.status == OrderStatus.completed) {
                      return _buildOrderCard(order);
                    } else {
                      // For orders that are not completed, don't show them in history
                      return Container(); // Return empty container
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order.id.substring(6, 12)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              "Driver: ${order.driver.name.isEmpty ? order.driver.email : order.driver.name}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              "Date: ${_formatDate(order.orderTime)}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              "Items: ${order.cart.orders.length} items",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              "Total: ${order.total.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.grey;
      case OrderStatus.accepted:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.delivering:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.delivering:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}