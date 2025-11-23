import 'package:flutter/material.dart';
import 'package:venieats/models/user.dart';
import 'package:venieats/services/user_service.dart';
import '../../constants.dart';
import '../../models/cart.dart';
import '../../entry_point.dart';
import '../../models/order.dart';

class DriverOrderScreen extends StatefulWidget {
  final User? customer;
  final User? driver;
  final Cart? cart;
  final double? total;

  const DriverOrderScreen({
    super.key,
    this.customer,
    this.driver,
    this.cart,
    this.total,
  });

  @override
  State<DriverOrderScreen> createState() => _DriverOrderScreenState();
}

class _DriverOrderScreenState extends State<DriverOrderScreen> {
  int _currentIndex = 0;
  List<DeliveryOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentDriverOrders();
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
        (e) => e.toString().split('.').last.toLowerCase() == statusString.toLowerCase(),
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      return OrderStatus.pending;
    }
  }

  // Load orders assigned to the current driver
  Future<void> _loadCurrentDriverOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current driver's email
      final currentUser = UserService.instance.currentUser!;
      if (currentUser.role != UserRole.driver) {
        // If user is not a driver, don't try to load orders
        return;
      }

      // Get all order IDs assigned to this driver
      List<String>? orderIds = await UserService.instance.getOrdersForDriver(currentUser.email);

      if (orderIds != null && orderIds.isNotEmpty) {
        List<DeliveryOrder> loadedOrders = [];

        for (String orderId in orderIds) {
          Map<String, dynamic>? orderData = await UserService.instance.getActiveOrder(orderId);

          if (orderData != null) {
            // Map the order data to a DeliveryOrder
            User customer = User.fromMap(orderData['customer']);
            User driver = User.fromMap(orderData['driver']);

            // Convert cart orders from JSON
            List<OrderItem> orderItems = (orderData['cart_orders'] as List?)
                ?.map((item) => OrderItem.fromJson(item))
                .toList() ?? [];

            Cart cart = Cart();
            cart.restaurantName = orderData['restaurantName'] ?? 'Local Restaurant';
            for (OrderItem item in orderItems) {
              cart.addOrder(item);
            }

            DeliveryOrder deliveryOrder = DeliveryOrder(
              id: orderId,
              customer: customer,
              driver: driver,
              cart: cart,
              total: orderData['total']?.toDouble() ?? 0.0,
              orderTime: DateTime.fromMillisecondsSinceEpoch(orderData['orderTime'] ?? DateTime.now().millisecondsSinceEpoch),
              status: _parseOrderStatus(orderData['status']),
            );

            loadedOrders.add(deliveryOrder);
          }
        }

        // Update the orders list
        setState(() {
          _orders = loadedOrders;
          _isLoading = false;
        });
      } else {
        // No orders found for this driver
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // In production, you might want to log this error differently
      // debugPrint("Error loading driver orders: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current user is a driver
    final currentUser = UserService.instance.currentUser!;
    if (currentUser.role != UserRole.driver) {
      // If not a driver, show a message and redirect to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EntryPoint()),
        );
      });
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("Only drivers can access this screen")),
      );
    }

    // Show loading indicator while orders are being loaded
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Driver Dashboard"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> screens = [
      _DeliveryListTab(orders: _orders, onUpdate: _updateOrder),
      _DriverOrdersTab(orders: _orders, onUpdate: _updateOrder),
      const _ProfileTab(), // Added Profile tab
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? "Pending Acceptance" :
          _currentIndex == 1 ? "My Orders" : "Profile",
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'My Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _updateOrder(DeliveryOrder order, OrderStatus newStatus) async {
    setState(() {
      order.status = newStatus;
    });

    // Update the stored order data to reflect the new status
    Map<String, dynamic>? orderData = await UserService.instance.getActiveOrder(order.id);
    if (orderData != null) {
      orderData['status'] = newStatus.toString().split('.').last;
      // Preserve restaurant name to prevent losing it during status updates
      orderData['restaurantName'] = order.cart.restaurantName ?? 'Local Restaurant';
      await UserService.instance.setActiveOrder(order.id, orderData);
    }

    if (newStatus == OrderStatus.completed) {
      // When driver marks as completed, update the order status
      // Payment only happens after customer confirms delivery
      Map<String, dynamic>? orderData = await UserService.instance.getActiveOrder(order.id);
      if (orderData != null) {
        orderData['status'] = newStatus.toString().split('.').last;
        // Preserve restaurant name to prevent losing it during status updates
        orderData['restaurantName'] = order.cart.restaurantName ?? 'Local Restaurant';
        await UserService.instance.setActiveOrder(order.id, orderData);
      }

      // Show a snackbar to inform driver that they need to wait for customer confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order marked as delivered. Waiting for customer confirmation."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (newStatus == OrderStatus.cancelled) {
      // If driver cancelled/skipped the order, remove it from their active orders
      // and make it available to other drivers
      await UserService.instance.cancelOrderForDriver(order.driver.email, order.id);

      // Show a message to the driver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order skipped. Making it available to other drivers..."),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Refresh the order list for the driver
      _loadCurrentDriverOrders();
    }
  }
}

// Tab for showing orders that need acceptance
class _DeliveryListTab extends StatelessWidget {
  final List<DeliveryOrder> orders;
  final Function(DeliveryOrder, OrderStatus) onUpdate;

  const _DeliveryListTab({
    required this.orders,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Show orders that are pending and assigned to the current driver (need to be accepted)
    final currentUserEmail = UserService.instance.currentUser!.email;
    final pendingOrders = orders.where((order) =>
        order.status == OrderStatus.pending && order.driver.email == currentUserEmail).toList();

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Acceptance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: pendingOrders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders pending acceptance',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: pendingOrders.length,
                    itemBuilder: (context, index) {
                      final order = pendingOrders[index];
                      return _OrderCard(
                        order: order,
                        showAccept: true,
                        onUpdate: onUpdate,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Tab for showing current and past driver's orders
class _DriverOrdersTab extends StatelessWidget {
  final List<DeliveryOrder> orders;
  final Function(DeliveryOrder, OrderStatus) onUpdate;

  const _DriverOrdersTab({
    required this.orders,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Show only orders assigned to this driver
    final driverOrders = orders.where((order) =>
        order.driver.email == UserService.instance.currentUser!.email).toList();

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: driverOrders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders assigned',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: driverOrders.length,
                    itemBuilder: (context, index) {
                      final order = driverOrders[index];
                      return _OrderCard(
                        order: order,
                        showAccept: false,
                        onUpdate: onUpdate,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Card widget to display order information
class _OrderCard extends StatefulWidget {
  final DeliveryOrder order;
  final bool showAccept;
  final Function(DeliveryOrder, OrderStatus) onUpdate;

  const _OrderCard({
    required this.order,
    required this.showAccept,
    required this.onUpdate,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(widget.order.status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${widget.order.id.substring(6, 12)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(widget.order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Customer Information
            _buildInfoSection(
              icon: Icons.person,
              title: "Customer",
              content: widget.order.customer.name.isEmpty
                  ? widget.order.customer.email
                  : widget.order.customer.name,
            ),
            const SizedBox(height: defaultPadding / 2),

            // Address Information
            _buildInfoSection(
              icon: Icons.location_on,
              title: "Delivery Address",
              content: widget.order.customer.location.isEmpty
                  ? 'Address not set'
                  : widget.order.customer.location,
            ),
            const SizedBox(height: defaultPadding),

            // Restaurant Information
            _buildRestaurantSection(),
            const SizedBox(height: defaultPadding),

            // Food Items
            _buildFoodItemsSection(),
            const SizedBox(height: defaultPadding),

            // Total Price
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatCurrency(widget.order.total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Action Buttons
            if (widget.showAccept && widget.order.status == OrderStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onUpdate(widget.order, OrderStatus.accepted);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        // Skip button functionality - mark order as rejected/cancelled
                        // This makes the order available to other drivers again
                        widget.onUpdate(widget.order, OrderStatus.cancelled);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else if (!widget.showAccept)
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // Helper method to build info sections
  Widget _buildInfoSection({required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build restaurant section
  Widget _buildRestaurantSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Restaurant",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.order.cart.restaurantName ?? "Local Restaurant",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build food items section
  Widget _buildFoodItemsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fastfood, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Food Items",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.order.cart.orders.asMap().entries.map((entry) {
            var item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.topCookie.isNotEmpty || item.bottomCookie.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "(${item.topCookie}, ${item.bottomCookie})",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    formatCurrency(item.price * item.quantity),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper method to build action buttons based on status
  Widget _buildActionButtons() {
    if (widget.order.status == OrderStatus.accepted) {
      return ElevatedButton(
        onPressed: () {
          widget.onUpdate(widget.order, OrderStatus.preparing);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Start Preparing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    } else if (widget.order.status == OrderStatus.preparing) {
      return ElevatedButton(
        onPressed: () {
          widget.onUpdate(widget.order, OrderStatus.delivering);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Start Delivering',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    } else if (widget.order.status == OrderStatus.delivering) {
      return ElevatedButton(
        onPressed: () {
          // When driver marks as delivered, update the status
          // Customer will need to confirm before payment is processed
          widget.onUpdate(widget.order, OrderStatus.completed);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Mark as Delivered',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      // For completed or cancelled orders, no action button needed
      return Container();
    }
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
        return Colors.red;  // Red for cancelled orders
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
        return 'Delivering';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Tab for profile information
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final currentUser = UserService.instance.currentUser!;

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Profile Information",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: defaultPadding),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Name", currentUser.name.isEmpty ? "Not set" : currentUser.name),
                  const Divider(height: defaultPadding * 2),
                  _buildInfoRow("Email", currentUser.email),
                  const Divider(height: defaultPadding * 2),
                  _buildInfoRow("Role", _formatRole(currentUser.role)),
                  const Divider(height: defaultPadding * 2),
                  _buildInfoRow("Location", currentUser.location.isEmpty ? "Not set" : currentUser.location),
                  const Divider(height: defaultPadding * 2),
                  _buildInfoRow("Balance", formatCurrency(currentUser.saldo)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: bodyTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatCurrency(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
  }

  String _formatRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.driver:
        return 'Driver';
      case UserRole.admin:
        return 'Admin';
    }
  }
}