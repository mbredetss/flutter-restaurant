import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants.dart';
import '../search/search_screen.dart';
import 'components/featured_items.dart';
import 'components/iteams.dart';
import 'components/restaurrant_info.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.restaurantData});

  final Map<String, dynamic> restaurantData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: SvgPicture.asset("assets/icons/share.svg"),
            onPressed: () {},
          ),
          IconButton(
            icon: SvgPicture.asset("assets/icons/search.svg"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding / 2),
              RestaurantInfo(restaurantName: restaurantData['name'], foodType: restaurantData['foodType']),
              const SizedBox(height: defaultPadding),
              FeaturedItems(featuredItems: restaurantData['featuredItems']),
              Items(menuItems: restaurantData['menuItems']),
            ],
          ),
        ),
      ),
    );
  }
}
