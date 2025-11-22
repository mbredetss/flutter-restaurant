import 'package:flutter/material.dart';

import '../../../components/section_title.dart';
import '../../../constants.dart';
import '../../../demo_data.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => CategoriesState();
}

class CategoriesState extends State<Categories> {
  late List<Map<String, dynamic>> categories;
  int? selectedCategoryIndex;

  @override
  void initState() {
    super.initState();
    // Get unique categories from demo data and create active state
    List<String> uniqueCategories = getUniqueCategories();
    List<Map<String, dynamic>> newCategories = [
      {"title": "All", "isActive": true}, // "All" is selected by default
    ];

    // Add the unique categories
    for (String category in uniqueCategories) {
      newCategories.add({"title": category, "isActive": false});
    }

    categories = newCategories;
  }

  // Method to get the selected category
  String? getSelectedCategory() {
    if (selectedCategoryIndex != null && selectedCategoryIndex! < categories.length) {
      String title = categories[selectedCategoryIndex!]["title"];
      if (title == "All") {
        return null; // "All" means no filter
      }
      return title;
    }
    return null;
  }

  // Method to reset the filters
  void resetFilters() {
    setState(() {
      // Reset all selections
      for (int i = 0; i < categories.length; i++) {
        categories[i]["isActive"] = (i == 0); // Only "All" is active
      }
      selectedCategoryIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Categories",
          press: () {
            // Clear all selections except "All"
            setState(() {
              for (int i = 0; i < categories.length; i++) {
                categories[i]["isActive"] = (i == 0); // Only "All" is active
              }
              selectedCategoryIndex = 0;
            });
          },
          isMainSection: false,
        ),
        const SizedBox(height: defaultPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Wrap(
            spacing: defaultPadding / 2,
            children: List.generate(
              categories.length,
              (index) => ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Deselect all
                    for (int i = 0; i < categories.length; i++) {
                      categories[i]["isActive"] = false;
                    }
                    // Select the clicked one
                    categories[index]["isActive"] = true;
                    selectedCategoryIndex = index;
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(56, 40),
                  backgroundColor: categories[index]["isActive"] ? primaryColor : bodyTextColor,
                ),
                child: Text(categories[index]["title"]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
