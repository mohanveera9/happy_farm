class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isFeatured;
  final double? discountPrice;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isFeatured = false,
    this.discountPrice,
    required this.rating,
  });

  // Sample data for demonstration purposes
  static List<Product> sampleProducts = [
    Product(
      id: 1,
      name: 'Neem Pesticide',
      description: 'Organic neem-based pesticide for insect control',
      price: 15.99,
      imageUrl: 'https://example.com/images/neem_pesticide.jpg',
      category: 'Pesticides',
      isFeatured: true,
      rating: 4.3
    ),
    Product(
      id: 2,
      name: 'Tractor Attachment Kit',
      description: 'Multi-use attachment kit for small tractors',
      price: 199.99,
      imageUrl: 'https://example.com/images/tractor_kit.jpg',
      category: 'Machinery',
      rating: 4.2
    ),
    Product(
      id: 3,
      name: 'Urea Fertilizer',
      description: 'High quality urea fertilizer for fast growth',
      price: 10.49,
      imageUrl: 'https://example.com/images/urea.jpg',
      category: 'Fertilizers',
      discountPrice: 8.99,
      isFeatured: true,
      rating: 4.2
    ),
    Product(
      id: 4,
      name: 'Hybrid Paddy Seeds',
      description: 'High yield hybrid rice seeds',
      price: 6.49,
      imageUrl: 'https://example.com/images/rice_seeds.jpg',
      category: 'Seeds',
      rating: 2.3
    ),
  ];

  // Get featured products
  static List<Product> getFeaturedProducts() {
    return sampleProducts.where((product) => product.isFeatured).toList();
  }

  // Get products by category
  static List<Product> getProductsByCategory(String category) {
    return sampleProducts
        .where((product) => product.category == category)
        .toList();
  }
}
