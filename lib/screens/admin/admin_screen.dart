import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../../components/buttons/primary_button.dart';
import '../../constants.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _saldoController = TextEditingController(text: '0');

  // For balance top-up
  final _topUpEmailController = TextEditingController();
  final _topUpAmountController = TextEditingController();
  final _userSearchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Register Driver"),
              Tab(text: "Top-up Balance"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDriverRegistrationForm(),
            _buildBalanceTopUpForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverRegistrationForm() {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Register New Driver",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: kDefaultOutlineInputBorder,
                contentPadding: kTextFieldPadding,
              ),
              validator: emailValidator,
            ),
            const SizedBox(height: defaultPadding / 2),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Password",
                border: kDefaultOutlineInputBorder,
                contentPadding: kTextFieldPadding,
              ),
              obscureText: true,
              validator: passwordValidator,
            ),
            const SizedBox(height: defaultPadding / 2),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: kDefaultOutlineInputBorder,
                contentPadding: kTextFieldPadding,
              ),
              validator: RequiredValidator(errorText: 'Name is required'),
            ),
            const SizedBox(height: defaultPadding / 2),
            TextFormField(
              controller: _saldoController,
              decoration: const InputDecoration(
                labelText: "Initial Balance",
                border: kDefaultOutlineInputBorder,
                contentPadding: kTextFieldPadding,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: defaultPadding),
            PrimaryButton(
              text: "Register Driver",
              press: _registerDriver,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceTopUpForm() {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top-up User Balance",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _userSearchController,
            decoration: InputDecoration(
              labelText: "Search User by Email",
              border: kDefaultOutlineInputBorder,
              contentPadding: kTextFieldPadding,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchUser,
              ),
            ),
            onFieldSubmitted: (_) => _searchUser(),
          ),
          const SizedBox(height: defaultPadding / 2),
          TextFormField(
            controller: _topUpAmountController,
            decoration: const InputDecoration(
              labelText: "Amount to Add",
              border: kDefaultOutlineInputBorder,
              contentPadding: kTextFieldPadding,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: defaultPadding),
          PrimaryButton(
            text: "Add Balance",
            press: _addBalance,
          ),
        ],
      ),
    );
  }

  void _registerDriver() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create a new user with driver role
        User newDriver = User(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: UserRole.driver,
          saldo: double.tryParse(_saldoController.text) ?? 0.0,
        );

        // Check if user already exists
        if (await UserService.instance.checkUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        )) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("A user with this email already exists"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Register the new driver
        await UserService.instance.registerUserWithRole(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          UserRole.driver,
          double.tryParse(_saldoController.text) ?? 0.0,
          '', // No location required for drivers, set to empty string
          _nameController.text.trim(), // Pass the name
        );

        // Clear the form
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        _saldoController.text = '0';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Driver registered successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error registering driver: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _searchUser() async {
    if (_userSearchController.text.isEmpty) {
      _topUpAmountController.text = '';
      return;
    }

    User? foundUser = await UserService.instance.getUserByEmail(_userSearchController.text.trim());
    if (foundUser != null) {
      // User found, allow top-up
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User found: ${foundUser.email}"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not found"),
          backgroundColor: Colors.red,
        ),
      );
      _topUpAmountController.text = '';
    }
  }

  void _addBalance() async {
    if (_userSearchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a user email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? amount = double.tryParse(_topUpAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid amount"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    User? user = await UserService.instance.getUserByEmail(_userSearchController.text.trim());
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add the balance
    user.saldo += amount;
    await UserService.instance.updateUser(user);

    // Clear the fields
    _topUpAmountController.clear();
    _userSearchController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added Rp. ${formatCurrency(amount)} to ${user.email}'s balance"),
        backgroundColor: Colors.green,
      ),
    );
  }

  String formatCurrency(double amount) {
    return "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _saldoController.dispose();
    _topUpEmailController.dispose();
    _topUpAmountController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }
}