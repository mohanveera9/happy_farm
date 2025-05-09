class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isFeatured;
  final double? discountPrice;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isFeatured = false,
    this.discountPrice,
  });

  // Sample data for demonstration purposes
  static List<Product> sampleProducts = [
    Product(
      id: 1,
      name: 'Fresh Organic Dates',
      description: 'Premium quality organic dates from Sabba Farm',
      price: 19.99,
      imageUrl: 'https://sabbafarm.com/wp-content/uploads/2023/03/5-1.jpg',
      category: 'Dates',
      isFeatured: true,
    ),
    Product(
      id: 2,
      name: 'Medjool Dates',
      description: 'Premium Medjool Dates from Sabba Farm',
      price: 24.99,
      imageUrl: 'https://sabbafarm.com/wp-content/uploads/2023/03/4-1.jpg',
      category: 'Dates',
      isFeatured: true,
      discountPrice: 22.99,
    ),
    Product(
      id: 3,
      name: 'Ajwa Dates',
      description: 'Premium Ajwa Dates from Sabba Farm',
      price: 29.99,
      imageUrl: 'https://sabbafarm.com/wp-content/uploads/2023/03/8.jpg',
      category: 'Dates',
      isFeatured: true,
    ),
    Product(
      id: 4,
      name: 'Sukkari Dates',
      description: 'Sweet Sukkari Dates from Sabba Farm',
      price: 17.99,
      imageUrl: 'https://sabbafarm.com/wp-content/uploads/2023/03/3-1.jpg',
      category: 'Dates',
    ),
    Product(
      id: 5,
      name: 'Date Paste',
      description: 'Natural date paste for cooking and baking',
      price: 12.99,
      imageUrl: 'https://sabbafarm.com/wp-content/uploads/2023/03/9.jpg',
      category: 'Date Products',
    ),
    Product(
      id: 6,
      name: 'Date Syrup',
      description: 'Pure natural date syrup',
      price: 14.99,
      imageUrl: 'https://sabbafarm.com/wp-content/uploads/2023/03/10.jpg',
      category: 'Date Products',
    ),
  ];

  // Get featured products
  static List<Product> getFeaturedProducts() {
    return sampleProducts.where((product) => product.isFeatured).toList();
  }

  // Get products by category
  static List<Product> getProductsByCategory(String category) {
    return sampleProducts.where((product) => product.category == category).toList();
  }
}