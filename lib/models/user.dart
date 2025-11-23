enum UserRole { customer, driver, admin }

class User {
  final String email;
  final String password;
  String name; // User's name
  String location;
  final UserRole role;
  double saldo;
  List<String> activeOrders; // List of active order IDs for the user
  List<String> orderHistory; // List of completed order IDs for the user

  User({
    required this.email,
    required this.password,
    this.name = '',
    this.location = '',
    this.role = UserRole.customer, // Default to customer
    this.saldo = 0.0,
    this.activeOrders = const [],
    this.orderHistory = const [],
  });

  // Convert User instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'location': location,
      'role': role.toString(),
      'saldo': saldo,
      'activeOrders': activeOrders,
      'orderHistory': orderHistory,
    };
  }

  // Create User instance from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => UserRole.customer,
      ),
      saldo: map['saldo']?.toDouble() ?? 0.0,
      activeOrders: List<String>.from(map['activeOrders'] ?? []),
      orderHistory: List<String>.from(map['orderHistory'] ?? []),
    );
  }
}