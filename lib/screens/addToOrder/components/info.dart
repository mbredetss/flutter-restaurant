import 'package:flutter/material.dart';

import '../../../constants.dart';

class Info extends StatelessWidget {
  const Info({
    super.key,
    required this.menuItem,
  });

  final Map<String, dynamic> menuItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.33,
          child: Image.asset(
            menuItem['image'], // Use menuItem image
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: defaultPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(menuItem['name'] ?? menuItem['title'], // Use menuItem name or title
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              // Featured items don't have a description, so we can remove this or provide a default
              // Text(
              //   menuItem['description'], // Use menuItem description
              //   style: Theme.of(context).textTheme.bodyMedium,
              // ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
