import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../screens/filter_list/filter_list_screen.dart';
import 'components/categories.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // This will hold a reference to the child widgets' states to access their selected values
  final GlobalKey<CategoriesState> _categoriesKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filters"),
        actions: [
          TextButton(
            onPressed: () {
              // Clear the category filter
              if (_categoriesKey.currentState != null) {
                _categoriesKey.currentState!.resetFilters();
              }
            },
            child: const Text("Clear Data"),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: defaultPadding),
                    Categories(key: _categoriesKey),
                    const SizedBox(height: defaultPadding),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Apply filters
                    applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Selesai",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void applyFilters() {
    // Get selected category
    String? selectedCategory;
    if (_categoriesKey.currentState != null) {
      selectedCategory = _categoriesKey.currentState!.getSelectedCategory();
    }

    // Navigate to the filter list screen with the selected category (without dietary and price range filters)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterListScreen(
          category: selectedCategory,
          dietary: null, // Removed dietary filter
          priceRanges: null, // Removed price range filter
        ),
      ),
    );
  }
}
