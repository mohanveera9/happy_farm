import 'package:flutter/material.dart';
import 'package:happy_farm/models/product_model.dart';

class FeaturedProductDetails extends StatefulWidget {
  final FeaturedProduct product;

  const FeaturedProductDetails({super.key, required this.product});

  @override
  State<FeaturedProductDetails> createState() => _FeaturedProductDetailsState();
}

class _FeaturedProductDetailsState extends State<FeaturedProductDetails> {
  int selectedPriceIndex = 0;
  int quantity = 1;
  int reviewRating = 1;
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = product.prices[selectedPriceIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image carousel
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: product.images.length,
                itemBuilder: (context, index) => Image.network(
                  product.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),

            // Product details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style:
                          const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                  Row(
                    children: [
                      Text('₹${price.actualPrice.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.green)),
                      const SizedBox(width: 8),
                      Text('₹${price.oldPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                      Text('${price.discount}% OFF',
                          style: const TextStyle(color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${price.quantity} ${price.type}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(price.countInStock > 0 ? 'IN STOCK' : 'OUT OF STOCK',
                      style: TextStyle(
                          color: price.countInStock > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 16),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (quantity > 1) quantity--;
                                });
                              }),
                          Text(quantity.toString(),
                              style: const TextStyle(fontSize: 16)),
                          IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  quantity++;
                                });
                              }),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Add to cart logic
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text("Add To Cart"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description & Additional Info
                  const Divider(),
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text("Description"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(product.description ?? "No description available."),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text("Additional Information"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(product.description ?? "No additional information."),
                      ),
                    ],
                  ),

                  const Divider(),

                  // Review
                  const Text("Add a review", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      hintText: "Write a review",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: index < reviewRating ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            reviewRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        // Submit review logic
                      },
                      child: const Text("Submit Review"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class AllProductDetails extends StatefulWidget {
  final AllProduct product;

  const AllProductDetails({super.key, required this.product});

  @override
  State<AllProductDetails> createState() => _AllProductDetailsState();
}

class _AllProductDetailsState extends State<AllProductDetails> {
  int selectedPriceIndex = 0;
  int quantity = 1;
  int reviewRating = 1;
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = product.prices[selectedPriceIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image carousel
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: product.images.length,
                itemBuilder: (context, index) => Image.network(
                  product.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(product.name,
                      style:
                          const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                  // Price info
                  Row(
                    children: [
                      Text('₹${price.actualPrice.toStringAsFixed(2)}',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.green)),
                      const SizedBox(width: 8),
                      Text('₹${price.oldPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                      Text('${price.discount}% OFF',
                          style: const TextStyle(color: Colors.orange)),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text('${price.quantity} ${price.type}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(price.countInStock > 0 ? 'IN STOCK' : 'OUT OF STOCK',
                      style: TextStyle(
                          color: price.countInStock > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),
                  Text('Category: ${product.catName}'),
                  if (product.subCatName != null)
                    Text('Sub-category: ${product.subCatName}'),

                  const SizedBox(height: 16),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (quantity > 1) quantity--;
                                });
                              }),
                          Text(quantity.toString(),
                              style: const TextStyle(fontSize: 16)),
                          IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  quantity++;
                                });
                              }),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Add to cart logic
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text("Add To Cart"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description & Additional Info
                  const Divider(),
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text("Description"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(product.description.isNotEmpty
                            ? product.description
                            : "No description available."),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text("Additional Information"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Category: ${product.catName}"),
                            if (product.subCatName != null)
                              Text("Sub-category: ${product.subCatName}"),
                            Text("Rating: ${product.rating} / 5"),
                            Text("Featured: ${product.isFeatured ? "Yes" : "No"}"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(),

                  // Review Section
                  const Text("Add a review", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      hintText: "Write a review",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: index < reviewRating ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            reviewRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        // Submit review logic
                      },
                      child: const Text("Submit Review"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

