import 'package:flutter/material.dart';

import '../../components/cards/medium/restaurant_info_medium_card.dart';
import '../../demo_data.dart';
import '../../screens/details/details_screen.dart';

class FilterListScreen extends StatefulWidget {
  final String? category;
  final List<String>? dietary;
  final List<String>? priceRanges;

  const FilterListScreen({
    Key? key,
    this.category,
    this.dietary,
    this.priceRanges,
  }) : super(key: key);

  @override
  State<FilterListScreen> createState() => _FilterListScreenState();
}

class _FilterListScreenState extends State<FilterListScreen> {
  List<Map<String, dynamic>> filteredRestaurants = [];

  @override
  void initState() {
    super.initState();
    filteredRestaurants = filterRestaurants();
  }

  List<Map<String, dynamic>> filterRestaurants() {
    List<Map<String, dynamic>> restaurants = List.from(demoMediumCardData);

    // Apply category filter
    if (widget.category != null && widget.category!.isNotEmpty && widget.category != "All") {
      restaurants = restaurants.where((restaurant) {
        // Check if the restaurant name matches or if any menu item matches
        bool restaurantMatches = restaurant["foodType"].cast<String>().contains(widget.category!);

        if (!restaurantMatches) {
          // Check if any menu items match the category
          List menuItems = restaurant["menuItems"];
          for (var item in menuItems) {
            String? itemFoodType = item["foodType"];
            if (itemFoodType != null && itemFoodType == widget.category) {
              return true;
            }
          }
          return false;
        }
        return true;
      }).toList();
    }

    return restaurants;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filtered Results"),
        automaticallyImplyLeading: true, // Show back button
      ),
      body: SafeArea(
        child: filteredRestaurants.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 100,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "No restaurants match your filters",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Try adjusting your filters",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Back to Filters"),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: filteredRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = filteredRestaurants[index];
                  return RestaurantInfoMediumCard(
                    image: restaurant["image"],
                    name: restaurant["name"],
                    location: restaurant["location"],
                    delivertTime: restaurant["delivertTime"],
                    rating: restaurant["rating"],
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(
                            restaurantData: restaurant,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}