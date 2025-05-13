class FeaturedProduct {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final String category;
  final String subCategory;
  final int rating;
  final bool isFeatured;
  final DateTime dateCreated;
  final List<ProductPrice> prices;

  FeaturedProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.category,
    required this.subCategory,
    required this.rating,
    required this.isFeatured,
    required this.dateCreated,
    required this.prices,
  });

  factory FeaturedProduct.fromJson(Map<String, dynamic> json) {
    return FeaturedProduct(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      images: List<String>.from(json['images']),
      category: json['catName'] ?? '',
      subCategory: json['subCatName'] ?? '',
      rating: json['rating'],
      isFeatured: json['isFeatured'],
      dateCreated: DateTime.parse(json['dateCreated']),
      prices: (json['prices'] as List)
          .map((priceJson) => ProductPrice.fromJson(priceJson))
          .toList(),
    );
  }
}

class ProductPrice {
  final int quantity;
  final double actualPrice;
  final double oldPrice;
  final int discount;
  final String type;
  final int countInStock;

  ProductPrice({
    required this.quantity,
    required this.actualPrice,
    required this.oldPrice,
    required this.discount,
    required this.type,
    required this.countInStock,
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json) {
    return ProductPrice(
      quantity: json['quantity'],
      actualPrice: (json['actualPrice'] as num).toDouble(),
      oldPrice: (json['oldPrice'] as num).toDouble(),
      discount: json['discount'],
      type: json['type'],
      countInStock: json['countInStock'],
    );
  }
}

class AllProduct {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final List<Price> prices;
  final String catName;
  final String? subCatName;
  final int rating;
  final bool isFeatured;

  AllProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.prices,
    required this.catName,
    this.subCatName,
    required this.rating,
    required this.isFeatured,
  });

  factory AllProduct.fromJson(Map<String, dynamic> json) {
    return AllProduct(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      prices: (json['prices'] as List)
          .map((priceJson) => Price.fromJson(priceJson))
          .toList(),
      catName: json['catName'] ?? 'Unknown',
      subCatName: json['subCatName'] == '' ? null : json['subCatName'],
      rating: json['rating'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}

class Price {
  final int quantity;
  final double actualPrice;
  final double oldPrice;
  final int discount;
  final String type;
  final int countInStock;

  Price({
    required this.quantity,
    required this.actualPrice,
    required this.oldPrice,
    required this.discount,
    required this.type,
    required this.countInStock,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      quantity: json['quantity'],
      actualPrice: json['actualPrice'].toDouble(),
      oldPrice: json['oldPrice'].toDouble(),
      discount: json['discount'],
      type: json['type'],
      countInStock: json['countInStock'],
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      imageUrl: (json['images'] as List).isNotEmpty ? json['images'][0] : '',
      color: json['color'] ?? '#ffffff',
    );
  }
}

class FilterProducts {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final List<FilterProductPrice> prices;
  final String catName;
  final String? subCatName;
  final int rating;
  final bool isFeatured;
  final DateTime? dateCreated;

  FilterProducts({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.prices,
    required this.catName,
    this.subCatName,
    required this.rating,
    required this.isFeatured,
    this.dateCreated,
  });

  factory FilterProducts.fromJson(Map<String, dynamic> json) {
    return FilterProducts(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      prices: (json['prices'] as List)
          .map((priceJson) => FilterProductPrice.fromJson(priceJson))
          .toList(),
      catName: json['catName'] ?? '',
      subCatName: (json['subCatName'] == null || json['subCatName'] == '')
          ? null
          : json['subCatName'],
      rating: json['rating'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      dateCreated: json['dateCreated'] != null
          ? DateTime.tryParse(json['dateCreated'])
          : null,
    );
  }
}

class FilterProductPrice {
  final int quantity;
  final double actualPrice;
  final double oldPrice;
  final int discount;
  final String type;
  final int countInStock;

  FilterProductPrice({
    required this.quantity,
    required this.actualPrice,
    required this.oldPrice,
    required this.discount,
    required this.type,
    required this.countInStock,
  });

  factory FilterProductPrice.fromJson(Map<String, dynamic> json) {
    return FilterProductPrice(
      quantity: json['quantity'],
      actualPrice: (json['actualPrice'] as num).toDouble(),
      oldPrice: (json['oldPrice'] as num).toDouble(),
      discount: json['discount'],
      type: json['type'],
      countInStock: json['countInStock'],
    );
  }
}

