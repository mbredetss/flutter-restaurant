import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:venieats/services/user_service.dart';

import '../../constants.dart';
import '../../models/order.dart';
import '../../entry_point.dart';

class OrderCompletionApprovalScreen extends StatefulWidget {
  final DeliveryOrder order;

  const OrderCompletionApprovalScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderCompletionApprovalScreen> createState() => _OrderCompletionApprovalScreenState();
}

class _OrderCompletionApprovalScreenState extends State<OrderCompletionApprovalScreen> {
  bool _showSuccessAnimation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Completion"),
      ),
      body: _showSuccessAnimation
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/Success.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: defaultPadding),
                  const Text(
                    "Order Completed Successfully!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back to the EntryPoint (home screen) after showing success
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const EntryPoint()),
                        (route) => false, // Remove all routes
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Continue"),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your order has been delivered!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order #${widget.order.id.substring(6, 12)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: defaultPadding / 2),
                          Text(
                            "Driver: ${widget.order.driver.email}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: defaultPadding / 2),
                          Text(
                            "Items: ${widget.order.cart.orders.length} items",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: defaultPadding / 2),
                          Text(
                            "Total: ${formatCurrency(widget.order.total)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  const Text(
                    "Is your order complete?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Approve completion - add delivery fee to driver's balance
                            widget.order.driver.saldo += 10000; // Delivery fee is 10,000
                            await UserService.instance.updateUser(widget.order.driver);

                            // Update order status to completed
                            widget.order.status = OrderStatus.completed;

                            // Move the order from active orders to history for both customer and driver
                            await UserService.instance.completeUserOrder(widget.order.customer.email, widget.order.id);
                            await UserService.instance.clearActiveOrder(widget.order.id);

                            // Show success animation
                            setState(() {
                              _showSuccessAnimation = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Approve"),
                        ),
                      ),
                      const SizedBox(width: defaultPadding),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Show dialogue explaining the issue
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Order Issue"),
                                content: const Text(
                                  "Please contact support if there's an issue with your order."
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text("Report Issue"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}