import 'package:flutter/material.dart';

import '../../components/buttons/primary_button.dart';
import '../../constants.dart';
import '../../models/cart.dart';
import 'components/order_item_card.dart';
import 'components/price_row.dart';
import 'components/total_price.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Cart();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Orders"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            children: [
              const SizedBox(height: defaultPadding),
              // List of cart items
              ...List.generate(
                cart.orders.length,
                (index) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: defaultPadding / 2),
                  child: OrderedItemCard(
                    title: cart.orders[index].item,
                    description:
                        "${cart.orders[index].topCookie}, ${cart.orders[index].bottomCookie}",
                    numOfItem: cart.orders[index].quantity,
                    price: cart.orders[index].price,
                  ),
                ),
              ),
              PriceRow(text: "Subtotal", price: cart.total),
              const SizedBox(height: defaultPadding / 2),
              const PriceRow(text: "Delivery", price: 0),
              const SizedBox(height: defaultPadding / 2),
              TotalPrice(price: cart.total),
              const SizedBox(height: defaultPadding * 2),
              PrimaryButton(
                text: "Checkout (${formatCurrency(cart.total)})",
                press: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

