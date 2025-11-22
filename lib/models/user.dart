class User {
  final String email;
  final String password;
  String location;

  User({
    required this.email,
    required this.password,
    this.location = '',
  });

  // Convert User instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'location': location,
    };
  }

  // Create User instance from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      location: map['location'] ?? '',
    );
  }
}