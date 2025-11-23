import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../components/buttons/primary_button.dart';
import '../../constants.dart';
import '../../models/cart.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import 'components/order_item_card.dart';
import 'components/price_row.dart';
import 'components/total_price.dart';
import '../customer_order_tracking.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = false;
  final deliveryCost = 10.0;

  @override
  Widget build(BuildContext context) {
    final user = UserService.instance.currentUser!;
    final total = Cart().total * 1000 + deliveryCost * 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Orders"),
        actions: [
          FutureBuilder<List<String>?>(
            future: _getActiveOrderIds(),
            builder: (context, snapshot) {
              bool hasActiveOrder = snapshot.hasData && snapshot.data!.isNotEmpty;
              if (hasActiveOrder) {
                // If there's an active order, provide access to tracking
                return IconButton(
                  icon: const Icon(Icons.local_shipping),  // Order tracking icon
                  onPressed: _navigateToActiveOrder,
                );
              } else {
                // If no active orders, show the icon but with limited functionality
                return IconButton(
                  icon: Icon(
                    Icons.local_shipping,
                    color: Colors.grey, // Greyed out when no active orders
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No active orders to track'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                children: [
                  const SizedBox(height: defaultPadding),
                  FutureBuilder<bool>(
                    future: _hasActiveOrder(),
                    builder: (context, snapshot) {
                      bool hasActiveOrder = snapshot.data ?? false;
                      if (hasActiveOrder) {
                        // Show active order details when user has active order
                        return _activeOrderDetails();
                      } else {
                        // Show regular cart items when no active order
                        final cart = Cart();
                        return Column(
                          children: [
                            // List of cart items
                            ...List.generate(
                              cart.orders.length,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: defaultPadding / 2),
                                child: OrderedItemCard(
                                  title: cart.orders[index].item,
                                  description:
                                      "${cart.orders[index].topCookie}, ${cart.orders[index].bottomCookie}",
                                  numOfItem: cart.orders[index].quantity,
                                  price: cart.orders[index].price *
                                      cart.orders[index].quantity,
                                ),
                              ),
                            ),
                            if (cart.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(defaultPadding),
                                child: Text(
                                  "Your cart is empty. Add some items!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            PriceRow(text: "Subtotal", price: cart.total * 1000),
                            const SizedBox(height: defaultPadding / 2),
                            PriceRow(text: "Delivery", price: deliveryCost * 1000),
                            const SizedBox(height: defaultPadding / 2),
                            TotalPrice(price: total),
                            const SizedBox(height: defaultPadding * 2),
                            PrimaryButton(
                              text: cart.isEmpty
                                  ? "No Items to Checkout"
                                  : "Checkout (${total.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')})",
                              press: cart.isEmpty
                                  ? () {}  // Empty function when disabled
                                  : () => _handleCheckout(user, total, cart),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/animations/Order.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.fill,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleCheckout(User user, double total, Cart cart) async {
    // Check if user has sufficient balance
    if (user.saldo < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if cart has any items
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to your cart before checking out'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate 3 seconds processing time
    await Future.delayed(const Duration(seconds: 3));

    // Select a random driver
    final drivers = await UserService.instance.getAllDrivers();
    if (drivers.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No drivers available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final random = Random();

    // Filter drivers to only include those without active orders
    List<User> availableDrivers = [];
    for (User driver in drivers) {
      bool hasActiveOrders = await UserService.instance.driverHasActiveOrders(driver.email);
      if (!hasActiveOrders) {
        availableDrivers.add(driver);
      }
    }

    // If no available drivers, show an error
    if (availableDrivers.isEmpty) {
      setState(() {
        _isLoading = false;
      });

      // Show a more user-friendly message with UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("No Drivers Available"),
            content: const Text(
              "All drivers are currently busy with other orders. "
              "Please try again later or consider ordering at a different time.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog

                  // Navigate back to previous screen or home
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      });
      return;
    }

    final selectedDriver = availableDrivers[random.nextInt(availableDrivers.length)];

    // Deduct total from user's balance
    user.saldo -= total;
    await UserService.instance.updateUser(user);

    // Create a unique order ID
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

    // Create order data to store
    final orderData = {
      'id': orderId,
      'customer': user.toMap(),
      'driver': selectedDriver.toMap(),
      'cart_orders': cart.orders.map((order) => order.toJson()).toList(), // Need to implement toJson in OrderItem
      'restaurantName': cart.restaurantName ?? 'Local Restaurant', // Store restaurant name
      'total': total,
      'orderTime': DateTime.now().millisecondsSinceEpoch,
      'status': OrderStatus.pending.toString().split('.').last, // Store the status
    };

    // Store the active order
    await UserService.instance.setActiveOrder(orderId, orderData);

    // Add the order to the customer's active orders
    await UserService.instance.addUserActiveOrder(user.email, orderId);

    // Clear the cart after successful checkout
    cart.clear();

    // Navigate to customer order tracking screen after processing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerOrderTrackingScreen(
          orderId: orderId, // Pass the order ID
          customer: user,
          driver: selectedDriver,
          cart: cart,
          total: total,
        ),
      ),
    );
  }

  // Get the IDs of all active orders for the current user
  Future<List<String>?> _getActiveOrderIds() async {
    final currentUser = UserService.instance.currentUser!;
    final user = await UserService.instance.getUserByEmail(currentUser.email);
    return user?.activeOrders;
  }

  // Check if the current user has an active order
  Future<bool> _hasActiveOrder() async {
    final currentUser = UserService.instance.currentUser!;
    final user = await UserService.instance.getUserByEmail(currentUser.email);
    return user?.activeOrders.isNotEmpty == true;
  }

  // Navigate to the active order tracking screen
  void _navigateToActiveOrder() async {
    // Get the latest active order
    List<String>? activeOrderIds = await _getActiveOrderIds();
    if (activeOrderIds != null && activeOrderIds.isNotEmpty) {
      String latestOrderId = activeOrderIds.first;
      Map<String, dynamic>? orderData = await UserService.instance.getActiveOrder(latestOrderId);

      if (orderData != null) {
        User customer = User.fromMap(orderData['customer']);
        User driver = User.fromMap(orderData['driver']);
        double total = orderData['total']?.toDouble() ?? 0.0;

        // Convert cart orders from JSON
        List<OrderItem> orderItems = (orderData['cart_orders'] as List)
            .map((item) => OrderItem.fromJson(item))
            .toList();

        // Create a temporary cart with the order items
        Cart orderCart = Cart();
        orderCart.restaurantName = orderData['restaurantName'] ?? 'Local Restaurant';
        for (OrderItem item in orderItems) {
          orderCart.addOrder(item);
        }

        // Navigate to order tracking screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerOrderTrackingScreen(
              orderId: latestOrderId, // Pass the order ID
              customer: customer,
              driver: driver,
              cart: orderCart,
              total: total,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active orders to track'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active orders to track'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Widget to show active order details
  Widget _activeOrderDetails() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getActiveOrderData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.all(defaultPadding),
            child: Column(
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 64,
                  color: Colors.orange,
                ),
                SizedBox(height: defaultPadding),
                Text(
                  "You have an active order!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: defaultPadding / 2),
                Text(
                  "Please wait until your current order is completed before placing a new one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final orderData = snapshot.data!;
        final restaurantName = orderData['restaurantName'] ?? 'Local Restaurant';
        final orderItems = (orderData['cart_orders'] as List?)
            ?.map((item) => OrderItem.fromJson(item))
            .toList() ?? [];

        return Column(
          children: [
            // Restaurant Name
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding / 2,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                restaurantName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Order Items
            ...orderItems.asMap().entries.map((entry) {
              OrderItem item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
                child: OrderedItemCard(
                  title: item.item,
                  description: "${item.topCookie}, ${item.bottomCookie}",
                  numOfItem: item.quantity,
                  price: item.price * item.quantity,
                ),
              );
            }),

            // Pricing Info
            const SizedBox(height: defaultPadding),
            PriceRow(text: "Subtotal", price: orderData['total'] != null ? (orderData['total'] - deliveryCost * 1000) : 0),
            const SizedBox(height: defaultPadding / 2),
            PriceRow(text: "Delivery", price: deliveryCost * 1000),
            const SizedBox(height: defaultPadding / 2),
            TotalPrice(price: orderData['total']?.toDouble() ?? 0),
          ],
        );
      },
    );
  }

  // Get the data of the active order
  Future<Map<String, dynamic>?> _getActiveOrderData() async {
    List<String>? activeOrderIds = await _getActiveOrderIds();
    if (activeOrderIds != null && activeOrderIds.isNotEmpty) {
      String latestOrderId = activeOrderIds.first;
      return await UserService.instance.getActiveOrder(latestOrderId);
    }
    return null;
  }
}
