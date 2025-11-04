import 'package:flutter/material.dart';
import '../../../components/cards/iteam_card.dart';
import '../../../constants.dart';
import '../../addToOrder/add_to_order_screen.dart';

class Items extends StatefulWidget {
  const Items({super.key, required this.menuItems});

  final List<Map<String, dynamic>> menuItems;

  @override
  State<Items> createState() => _ItemsState();
}

class _ItemsState extends State<Items> {

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTabController(
          length: demoTabs.length,
          child: TabBar(
            isScrollable: true,
            unselectedLabelColor: titleColor,
            labelStyle: Theme.of(context).textTheme.titleLarge,
            onTap: (value) {
              // you will get selected tab index
            },
            tabs: demoTabs,
          ),
        ),
        // SizedBox(height: defaultPadding),
        ...List.generate(
          widget.menuItems.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: ItemCard(
              title: widget.menuItems[index]["title"],
              description: widget.menuItems[index]["description"],
              image: widget.menuItems[index]["image"],
              foodType: widget.menuItems[index]['foodType'],
              price: widget.menuItems[index]["price"],
              priceRange: widget.menuItems[index]["priceRange"],
              press: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddToOrderScrreen(menuItem: widget.menuItems[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
final List<Tab> demoTabs = <Tab>[
  const Tab(
    child: Text('Most Populars'),
  ),
  const Tab(
    child: Text('Beef & Lamb'),
  ),
  const Tab(
    child: Text('Seafood'),
  ),
  const Tab(
    child: Text('Appetizers'),
  ),
  const Tab(
    child: Text('Dim Sum'),
  ),
];
