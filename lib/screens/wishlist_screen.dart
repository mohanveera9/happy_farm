import 'package:flutter/material.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Map<String, dynamic>> wishlist = [
    {
      'title': 'Organic Apples',
      'price': 19.99,
      'image': 'assets/images/apple.png',
      'rating': 4.8,
      'isFavorite': true,
    },
    {
      'title': 'Fresh Strawberries',
      'price': 24.99,
      'image': 'assets/images/strawberry.png',
      'rating': 4.5,
      'isFavorite': true,
    },
    {
      'title': 'Organic Blueberries',
      'price': 29.99,
      'image': 'assets/images/blueberry.png',
      'rating': 4.7,
      'isFavorite': true,
    },
    {
      'title': 'Fresh Oranges',
      'price': 15.99,
      'image': 'assets/images/orange.png',
      'rating': 4.6,
      'isFavorite': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void removeFromWishlist(int index) {
    setState(() {
      wishlist.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green[800],
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${wishlist.length} items',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: wishlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your wishlist is empty',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you like will appear here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to products screen
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text(
                      'Explore Products',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                // Create staggered animation
                final Animation<double> animation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      (1 / wishlist.length) * index,
                      1.0,
                      curve: Curves.fastOutSlowIn,
                    ),
                  ),
                );
                _controller.forward();
                
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.5, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (direction) {
                        removeFromWishlist(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item['title']} removed from wishlist'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                setState(() {
                                  wishlist.insert(index, item);
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product image
                              Hero(
                                tag: 'wishlist_${item['title']}',
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.eco_outlined,
                                      color: Colors.green[800],
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            removeFromWishlist(index);
                                          },
                                          child: Icon(
                                            Icons.favorite,
                                            color: Colors.red[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${item['price']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Rating
                                    Row(
                                      children: [
                                        ...List.generate(
                                          5,
                                          (i) => Icon(
                                            i < (item['rating'] as double).floor()
                                                ? Icons.star
                                                : i < (item['rating'] as double)
                                                    ? Icons.star_half
                                                    : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item['rating']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Action buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              // View details
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green[800],
                                              side: BorderSide(color: Colors.green[800]!),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text('View Details'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              // Add to cart
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${item['title']} added to cart'),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[800],
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text('Add to Cart'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: wishlist.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Add all to cart
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All items added to cart'),
                  ),
                );
              },
              backgroundColor: Colors.green[800],
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add All to Cart'),
            )
          : null,
    );
  }
}