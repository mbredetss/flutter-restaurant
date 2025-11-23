import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/cart.dart';

class UserService {
  static const String _currentUserKey = 'current_user';
  static UserService? _instance;
  static SharedPreferences? _prefs;
  static bool _initialized = false;

  static UserService get instance {
    _instance ??= UserService._init();
    return _instance!;
  }

  UserService._init() {
    _initializePrefs().then((_) => initializeDefaultAccounts());
  }

  static Future<void> _initializePrefs() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Save a specific user by email
  Future<void> saveUserByEmail(String email, User user) async {
    await _initializePrefs();
    String userKey = 'user_${email.replaceAll('@', '_at_').replaceAll('.', '_dot_')}';
    await _prefs?.setString(userKey, jsonEncode(user.toMap()));
  }

  // Get a specific user by email
  Future<User?> getUserByEmail(String email) async {
    await _initializePrefs();
    String userKey = 'user_${email.replaceAll('@', '_at_').replaceAll('.', '_dot_')}';
    final userData = _prefs?.getString(userKey);
    if (userData != null) {
      final userMap = jsonDecode(userData);
      return User.fromMap(userMap);
    }
    return null;
  }

  // Save current logged in user
  Future<void> saveCurrentUser(User user) async {
    await _initializePrefs();
    await _prefs?.setString(_currentUserKey, jsonEncode(user.toMap()));
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    await _initializePrefs();
    final userData = _prefs?.getString(_currentUserKey);
    if (userData != null) {
      final userMap = jsonDecode(userData);
      return User.fromMap(userMap);
    }
    return null;
  }

  // Update user location for current user
  Future<void> updateUserLocation(String location) async {
    await _initializePrefs();
    final user = await getCurrentUser();
    if (user != null) {
      user.location = location;
      await saveCurrentUser(user);
      // Also update the stored user
      await saveUserByEmail(user.email, user);
    }
  }

  // Check if user exists (for login)
  Future<bool> checkUser(String email, String password) async {
    await _initializePrefs();
    final user = await getUserByEmail(email);
    if (user != null) {
      return user.email == email && user.password == password;
    }
    return false;
  }

  // Register new user
  Future<void> registerUser(String email, String password) async {
    await _initializePrefs();
    final user = User(email: email.trim(), password: password.trim());
    await saveUserByEmail(email, user);
  }

  // Register new user with name
  Future<void> registerUserWithName(String email, String password, String name) async {
    await _initializePrefs();
    final user = User(
      email: email.trim(),
      password: password.trim(),
      name: name,
    );
    await saveUserByEmail(email, user);
  }

  // Log in user and set as current user
  Future<bool> loginUser(String email, String password) async {
    await _initializePrefs();
    final user = await getUserByEmail(email);
    if (user != null && user.email == email && user.password == password) {
      await saveCurrentUser(user);
      return true;
    }
    return false;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await _initializePrefs();
    final user = await getCurrentUser();
    return user != null;
  }

  // Clear user data (logout)
  Future<void> clearUserData() async {
    await _initializePrefs();
    await _prefs?.remove(_currentUserKey);
  }

  // Getter for current user
  User? get currentUser {
    // Note: This will return null if called before initialization
    // In a real app, you should handle this properly
    if (_prefs == null) return null;

    final userData = _prefs?.getString(_currentUserKey);
    if (userData != null) {
      final userMap = jsonDecode(userData);
      return User.fromMap(userMap);
    }
    return null;
  }

  // Check if current user has location set
  Future<bool> hasLocationSet() async {
    await _initializePrefs();
    final user = await getCurrentUser();
    return user != null && user.location.isNotEmpty;
  }

  // Get all drivers
  Future<List<User>> getAllDrivers() async {
    await _initializePrefs();
    List<User> drivers = [];

    // Get all keys
    final keys = _prefs?.getKeys();
    if (keys != null) {
      for (String key in keys) {
        if (key.startsWith('user_')) {
          final userData = _prefs?.getString(key);
          if (userData != null) {
            final userMap = jsonDecode(userData);
            final user = User.fromMap(userMap);
            if (user.role == UserRole.driver) {
              drivers.add(user);
            }
          }
        }
      }
    }

    return drivers;
  }

  // Update user information (for updating saldo or other fields)
  Future<void> updateUser(User user) async {
    await _initializePrefs();
    await saveUserByEmail(user.email, user);

    // If this is the current user, update the current user as well
    final currentUser = await getCurrentUser();
    if (currentUser != null && currentUser.email == user.email) {
      await saveCurrentUser(user);
    }
  }

  // Register new user with a specific role
  Future<void> registerUserWithRole(String email, String password, UserRole role, [double saldo = 0.0, String location = '', String name = '']) async {
    await _initializePrefs();
    final user = User(
      email: email.trim(),
      password: password.trim(),
      name: name,
      role: role,
      saldo: saldo,
      location: location,
    );
    await saveUserByEmail(email, user);
  }

  // Initialize default accounts (admin and drivers)
  Future<void> initializeDefaultAccounts() async {
    await _initializePrefs();

    // Check if admin account already exists
    bool adminExists = await checkUser('admin@admin.com', 'admin123@');
    if (!adminExists) {
      await registerUserWithRole('admin@admin.com', 'admin123@', UserRole.admin);
    }
  }

  // Store an active order for a user
  Future<void> setActiveOrder(String orderId, Map<String, dynamic> orderData) async {
    await _initializePrefs();
    await _prefs?.setString('active_order_$orderId', jsonEncode(orderData));

    // Also associate the order with the driver
    String? driverEmail = orderData['driver']['email'];
    if (driverEmail != null) {
      await addOrderToDriver(driverEmail, orderId);
    }
  }

  // Get the active order for a user
  Future<Map<String, dynamic>?> getActiveOrder(String orderId) async {
    await _initializePrefs();
    final orderData = _prefs?.getString('active_order_$orderId');
    if (orderData != null) {
      return jsonDecode(orderData);
    }
    return null;
  }

  // Clear the active order when completed and move to history
  Future<void> clearActiveOrder(String orderId) async {
    await _initializePrefs();

    // Get the order data to identify the driver and customer
    Map<String, dynamic>? orderData = await getActiveOrder(orderId);
    if (orderData != null) {
      String? driverEmail = orderData['driver']?['email'];
      String? customerEmail = orderData['customer']?['email'];

      // Move the completed order to history storage
      await _prefs?.setString('order_history_$orderId', json.encode(orderData));

      // Remove the order from active orders
      await _prefs?.remove('active_order_$orderId');

      // Remove the order from any driver associations
      await removeOrderFromAllDrivers(orderId);

      // If we know the driver, remove this specific order from their list
      if (driverEmail != null) {
        String key = 'driver_orders_$driverEmail';
        List<String>? driverOrders = await getOrdersForDriver(driverEmail);
        if (driverOrders != null && driverOrders.contains(orderId)) {
          driverOrders.remove(orderId);
          await _prefs?.setStringList(key, driverOrders);
        }
      }

      // Move the order from active orders to history for both customer and driver
      if (customerEmail != null) {
        await moveOrderToHistory(customerEmail, orderId);
      }
      if (driverEmail != null) {
        await moveOrderToHistory(driverEmail, orderId);
      }
    } else {
      // If the order doesn't exist in active orders, just try to remove it
      await _prefs?.remove('active_order_$orderId');
    }
  }

  // Move an order from active to history for a specific user
  Future<void> moveOrderToHistory(String userEmail, String orderId) async {
    await _initializePrefs();

    User? user = await getUserByEmail(userEmail);
    if (user != null) {
      // Remove from active orders if present
      List<String> updatedActiveOrders = List.from(user.activeOrders)..remove(orderId);

      // Add to order history if not already in history
      List<String> updatedOrderHistory = List.from(user.orderHistory);
      if (!updatedOrderHistory.contains(orderId)) {
        updatedOrderHistory.add(orderId);
      }

      user.activeOrders = updatedActiveOrders;
      user.orderHistory = updatedOrderHistory;

      await saveUserByEmail(userEmail, user);
    }
  }

  // Check if a driver already has active orders
  Future<bool> driverHasActiveOrders(String driverEmail) async {
    await _initializePrefs();
    List<String>? orderIds = await getOrdersForDriver(driverEmail);

    if (orderIds != null && orderIds.isNotEmpty) {
      // Check if any of these orders have a status of accepted, preparing, or delivering
      for (String orderId in orderIds) {
        Map<String, dynamic>? orderData = await getActiveOrder(orderId);
        if (orderData != null) {
          String statusStr = orderData['status'] ?? 'pending';
          // Normalize the status string (strip "OrderStatus." prefix if present)
          String normalizedStatus = statusStr.contains('.') ? statusStr.split('.').last.toLowerCase() : statusStr.toLowerCase();
          // If status is accepted, preparing, or delivering, the driver is busy
          if (normalizedStatus == 'accepted' || normalizedStatus == 'preparing' || normalizedStatus == 'delivering') {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Associate an order with a specific driver
  Future<void> addOrderToDriver(String driverEmail, String orderId) async {
    await _initializePrefs();
    String key = 'driver_orders_$driverEmail';
    List<String> existingOrders = await getOrdersForDriver(driverEmail) ?? [];

    // Add the new order if it's not already in the list
    if (!existingOrders.contains(orderId)) {
      existingOrders.add(orderId);
    }

    await _prefs?.setStringList(key, existingOrders);
  }

  // Get all orders assigned to a specific driver
  Future<List<String>?> getOrdersForDriver(String driverEmail) async {
    await _initializePrefs();
    return _prefs?.getStringList('driver_orders_$driverEmail');
  }

  // Remove an order from all drivers' lists
  Future<void> removeOrderFromAllDrivers(String orderId) async {
    await _initializePrefs();
    final keys = _prefs?.getKeys();
    if (keys != null) {
      for (String key in keys) {
        if (key.startsWith('driver_orders_')) {
          List<String>? driverOrders = _prefs?.getStringList(key);
          if (driverOrders != null && driverOrders.contains(orderId)) {
            driverOrders.remove(orderId);
            await _prefs?.setStringList(key, driverOrders);
          }
        }
      }
    }
  }

  // Add an active order to a user's profile
  Future<void> addUserActiveOrder(String userEmail, String orderId) async {
    await _initializePrefs();
    User? user = await getUserByEmail(userEmail);
    if (user != null) {
      // Create a copy of the active orders list and add the new order
      List<String> updatedActiveOrders = List.from(user.activeOrders)..add(orderId);
      user.activeOrders = updatedActiveOrders;
      await saveUserByEmail(userEmail, user);
    }
  }

  // Remove an active order from a user's profile and move to history
  Future<void> completeUserOrder(String userEmail, String orderId) async {
    await _initializePrefs();
    User? user = await getUserByEmail(userEmail);
    if (user != null) {
      // Remove from active orders
      List<String> updatedActiveOrders = List.from(user.activeOrders)..remove(orderId);
      // Add to order history
      List<String> updatedOrderHistory = List.from(user.orderHistory)..add(orderId);

      user.activeOrders = updatedActiveOrders;
      user.orderHistory = updatedOrderHistory;

      await saveUserByEmail(userEmail, user);
    }
  }

  // Cancel an order and make it available to other drivers
  Future<void> cancelOrderForDriver(String driverEmail, String orderId) async {
    await _initializePrefs();

    // Get the order data
    Map<String, dynamic>? orderData = await getActiveOrder(orderId);
    if (orderData != null) {
      // Change the order status to pending to make it available to other drivers
      orderData['status'] = 'pending';

      // Update the order in the database
      await setActiveOrder(orderId, orderData);

      // Remove the order from the current driver's list
      await removeOrderFromDriver(driverEmail, orderId);
    }
  }


  // Remove an order from a specific driver's order list
  Future<void> removeOrderFromDriver(String driverEmail, String orderId) async {
    await _initializePrefs();
    String key = 'driver_orders_$driverEmail';
    List<String>? driverOrders = await getOrdersForDriver(driverEmail);

    if (driverOrders != null && driverOrders.contains(orderId)) {
      driverOrders.remove(orderId);
      await _prefs?.setStringList(key, driverOrders);
    }
  }

  // Retrieve a specific order from history by ID
  Future<Map<String, dynamic>?> getOrderHistoryById(String orderId) async {
    await _initializePrefs();
    String? orderData = _prefs?.getString('order_history_$orderId');
    if (orderData != null) {
      return json.decode(orderData);
    }
    return null;
  }

  // Get a user's active orders
  Future<List<DeliveryOrder>> getUserActiveOrders(User user) async {
    await _initializePrefs();
    List<DeliveryOrder> activeOrders = [];

    for (String orderId in user.activeOrders) {
      Map<String, dynamic>? orderData = await getActiveOrder(orderId);
      if (orderData != null) {
        // Map the order data to a DeliveryOrder
        User customer = User.fromMap(orderData['customer']);
        User driver = User.fromMap(orderData['driver']);

        // Convert cart orders from JSON
        List<OrderItem> orderItems = (orderData['cart_orders'] as List?)
            ?.map((item) => OrderItem.fromJson(item))
            .toList() ?? [];

        Cart cart = Cart();
        for (OrderItem item in orderItems) {
          cart.addOrder(item);
        }

        DeliveryOrder deliveryOrder = DeliveryOrder(
          id: orderId,
          customer: customer,
          driver: driver,
          cart: cart,
          total: orderData['total']?.toDouble() ?? 0.0,
          orderTime: DateTime.fromMillisecondsSinceEpoch(
              orderData['orderTime'] ?? DateTime.now().millisecondsSinceEpoch),
          status: _parseOrderStatus(orderData['status']),
        );

        activeOrders.add(deliveryOrder);
      }
    }

    return activeOrders;
  }

  // Helper method to parse order status from stored string
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


  // Get all users
  Future<List<User>> getAllUsers() async {
    await _initializePrefs();
    List<User> users = [];

    // Get all keys
    final keys = _prefs?.getKeys();
    if (keys != null) {
      for (String key in keys) {
        if (key.startsWith('user_')) {
          final userData = _prefs?.getString(key);
          if (userData != null) {
            final userMap = jsonDecode(userData);
            final user = User.fromMap(userMap);
            users.add(user);
          }
        }
      }
    }

    return users;
  }
}