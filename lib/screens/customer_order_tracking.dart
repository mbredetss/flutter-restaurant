import 'dart:async';
import 'package:flutter/material.dart';
import 'package:venieats/models/order.dart';

import '../constants.dart';
import '../entry_point.dart';
import '../models/cart.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'order_completion_approval.dart';

class CustomerOrderTrackingScreen extends StatefulWidget {
  final String? orderId; // Added this field
  final User customer;
  final User driver;
  final Cart cart;
  final double total;

  const CustomerOrderTrackingScreen({
    super.key,
    this.orderId, // Added this param
    required this.customer,
    required this.driver,
    required this.cart,
    required this.total,
  });

  @override
  State<CustomerOrderTrackingScreen> createState() =>
      _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState
    extends State<CustomerOrderTrackingScreen> {
  late DeliveryOrder _order;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Use the actual order ID if provided, otherwise generate a new one
    String orderId =
        widget.orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}';

    // Create a new order instance with the correct ID
    _order = DeliveryOrder(
      id: orderId,
      customer: widget.customer,
      driver: widget.driver,
      cart: widget.cart,
      total: widget.total,
      orderTime: DateTime.now(),
    );

    // Start timer to periodically check for status updates
    _timer = Timer.periodic(const Duration(seconds: 2), _updateOrderStatus);
  }

  // Update order status from persistent storage
  Future<void> _updateOrderStatus(Timer timer) async {
    if (_isLoading) return; // Skip update if already loading

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? orderData =
          await UserService.instance.getActiveOrder(_order.id);
      if (orderData != null) {
        OrderStatus newStatus = _parseOrderStatus(orderData['status']);

        setState(() {
          _order.status = newStatus;
        });
      }
    } catch (e) {
      // Handle error appropriately
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Parse the order status from the stored string
  OrderStatus _parseOrderStatus(dynamic statusData) {
    if (statusData == null) return OrderStatus.pending;

    String statusString = statusData.toString();
    if (statusString.contains('.')) {
      statusString = statusString.split('.').last;
    }

    try {
      return OrderStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            statusString.toLowerCase(),
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      return OrderStatus.pending;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current user is the owner of the order
    final currentUser = UserService.instance.currentUser!;
    if (_order.customer.email != currentUser.email) {
      // If not the order owner, show access denied message
      return Scaffold(
        appBar: AppBar(
          title: const Text("Order Tracking"),
        ),
        body: const Center(
          child: Text(
            "You don't have permission to view this order",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return; // If the screen was already popped, do nothing
        }
        // Instead of going back to the previous screen, go to the EntryPoint to avoid going back to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const EntryPoint()),
          (route) => false, // Remove all routes
        );
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text("Order Tracking"),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Track Your Order",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: defaultPadding),
                    _buildOrderSummaryCard(),
                    const SizedBox(height: defaultPadding),
                    _buildDriverInfoCard(),
                    const SizedBox(height: defaultPadding),
                    _buildStatusProgressIndicator(),
                    const SizedBox(height: defaultPadding),
                    if (_order.status == OrderStatus.completed)
                      _buildApproveButton()
                    else if (_order.status == OrderStatus.cancelled)
                      _buildCancelledCard(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${_order.id.substring(6, 12)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: defaultPadding / 2),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.restaurant,
                    label: "Items",
                    value: "${_order.cart.orders.length} items",
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    label: "Time",
                    value: "${_order.orderTime.hour.toString().padLeft(2, '0')}:${_order.orderTime.minute.toString().padLeft(2, '0')}",
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoItem(
              icon: Icons.attach_money,
              label: "Total",
              value: formatCurrency(_order.total),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              color: bodyTextColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Driver Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: defaultPadding),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _order.driver.name.isEmpty ? _order.driver.email : _order.driver.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _order.driver.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Implement call functionality
                    },
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgressIndicator() {
    if (_order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Order has been cancelled by the driver",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Status",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: defaultPadding),
            _buildVisualStatusIndicator(),
            const SizedBox(height: defaultPadding),
            Column(
              children: [
                _buildStatusItem(
                  "Order Placed",
                  _order.status.index >= OrderStatus.pending.index,
                  _order.orderTime,
                ),
                _buildStatusItem(
                  "Order Accepted",
                  _order.status.index >= OrderStatus.accepted.index,
                  _order.status.index >= OrderStatus.accepted.index
                      ? _order.orderTime.add(const Duration(minutes: 2))
                      : null,
                ),
                _buildStatusItem(
                  "Preparing",
                  _order.status.index >= OrderStatus.preparing.index,
                  _order.status.index >= OrderStatus.preparing.index
                      ? _order.orderTime.add(const Duration(minutes: 5))
                      : null,
                ),
                _buildStatusItem(
                  "On the way",
                  _order.status.index >= OrderStatus.delivering.index,
                  _order.status.index >= OrderStatus.delivering.index
                      ? _order.orderTime.add(const Duration(minutes: 10))
                      : null,
                ),
                _buildStatusItem(
                  "Delivered",
                  _order.status.index >= OrderStatus.completed.index,
                  _order.status.index >= OrderStatus.completed.index
                      ? _order.orderTime.add(const Duration(minutes: 15))
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualStatusIndicator() {
    return Column(
      children: [
        // Progress line and status indicators
        Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusCircle(OrderStatus.pending),
              _buildProgressLine(1),
              _buildStatusCircle(OrderStatus.accepted),
              _buildProgressLine(2),
              _buildStatusCircle(OrderStatus.preparing),
              _buildProgressLine(3),
              _buildStatusCircle(OrderStatus.delivering),
              _buildProgressLine(4),
              _buildStatusCircle(OrderStatus.completed),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        // Status labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusLabel("Placed"),
            _buildStatusLabel("Accepted"),
            _buildStatusLabel("Preparing"),
            _buildStatusLabel("Pickup"),
            _buildStatusLabel("Delivered"),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCircle(OrderStatus status) {
    bool isCompleted = _order.status.index >= status.index;
    bool isCurrent = _order.status == status;

    Color circleColor = isCurrent ? accentColor : (isCompleted ? primaryColor : Colors.grey.shade300);
    Color iconColor = isCompleted ? Colors.white : (isCurrent ? Colors.white : Colors.transparent);

    IconData icon = status == OrderStatus.completed
        ? Icons.check
        : (status == OrderStatus.delivering
            ? Icons.local_shipping
            : Icons.circle);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? accentColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: iconColor,
      ),
    );
  }

  Widget _buildProgressLine(int index) {
    bool isCompleted = _order.status.index >= index;
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isCompleted ? primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStatusLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: bodyTextColor,
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isCompleted, DateTime? time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? primaryColor : Colors.grey.shade300,
            ),
            child: const Icon(
              Icons.check,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                if (time != null)
                  Text(
                    "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: bodyTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApproveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () async {
          // Navigate to approval screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderCompletionApprovalScreen(
                      order: _order),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Approve Delivery",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cancel,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: defaultPadding),
          const Text(
            "Order Cancelled",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            "Unfortunately, your order has been cancelled by the driver.\nWe're searching for an alternative driver...",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: bodyTextColor,
            ),
          ),
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: () {
              // Navigate back to the main screen to place a new order
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const EntryPoint(),
                ),
                (route) => route.isFirst,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Place New Order"),
          ),
        ],
      ),
    );
  }
}
