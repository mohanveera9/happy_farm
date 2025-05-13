import 'package:flutter/material.dart';
import 'package:happy_farm/models/product_model.dart';
import 'package:happy_farm/widgets/product_card.dart';

class FilteredProductsScreen extends StatelessWidget {
  final List<FilterProducts> products;

  const FilteredProductsScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filtered Products"),
      ),
      body: products.isEmpty
          ? const Center(
              child: Text(
                "No products found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two cards per row
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.65, // Adjust based on your card height
                ),
                itemBuilder: (context, index) {
                  return FilteredProductCard(product: products[index]);
                },
              ),
            ),
    );
  }
}
