import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'featured_item_card.dart';

class FeaturedItems extends StatelessWidget {
  const FeaturedItems({
    super.key,
    required this.featuredItems,
  });

  final List<Map<String, dynamic>> featuredItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Text("Featured Items",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: defaultPadding / 2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(
                featuredItems.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(left: defaultPadding),
                  child: FeaturedItemCard(
                    menuItem: featuredItems[index],
                    press: () {},
                  ),
                ),
              ),
              const SizedBox(width: defaultPadding),
            ],
          ),
        ),
      ],
    );
  }
}
