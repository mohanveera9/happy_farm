import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  final String? baseUrl = '${dotenv.env['BASE_URL']}/products';

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("token:$token");
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Updated ProductService methods
  Future<Map<String, dynamic>> getProductsWithPagination(
      {int page = 1, int perPage = 10}) async {
    final uri = Uri.parse('$baseUrl?page=$page&perPage=$perPage');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      final List<dynamic>? productsJson = jsonResponse['data'];

      // Get pagination info from the correct object
      final Map<String, dynamic>? paginationInfo = jsonResponse['pagination'];

      final int totalProducts = paginationInfo?['totalItems'] ?? 0;
      final int totalPages = paginationInfo?['totalPages'] ?? 0;
      final int currentPage = paginationInfo?['currentPage'] ?? page;
      final bool hasNextPage = paginationInfo?['hasNextPage'] ?? false;
      final bool hasPrevPage = paginationInfo?['hasPrevPage'] ?? false;
      final int perPageCount = paginationInfo?['perPage'] ?? perPage;

      if (productsJson == null) {
        return {
          'products': <AllProduct>[],
          'totalProducts': totalProducts,
          'totalPages': totalPages,
          'currentPage': currentPage,
          'hasNextPage': hasNextPage,
          'hasPrevPage': hasPrevPage,
          'perPage': perPageCount,
        };
      }

      final List<AllProduct> products =
          productsJson.map((item) => AllProduct.fromJson(item)).toList();

      return {
        'products': products,
        'totalProducts': totalProducts,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'hasNextPage': hasNextPage,
        'hasPrevPage': hasPrevPage,
        'perPage': perPageCount,
      };
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Keep the original method for backward compatibility
  Future<List<AllProduct>> getProducts({int page = 1, int perPage = 10}) async {
    final result =
        await getProductsWithPagination(page: page, perPage: perPage);
    return result['products'];
  }

  // Updated getFeaturedProducts with pagination support
  Future<Map<String, dynamic>> getFeaturedProductsWithPagination(
      {int page = 1, int perPage = 2}) async {
    final uri = Uri.parse('$baseUrl/featured?page=$page&perPage=${3}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      final List<dynamic>? productsJson = jsonResponse['data'];

      // Get pagination info from the correct object
      final Map<String, dynamic>? paginationInfo = jsonResponse['pagination'];

      final int totalProducts = paginationInfo?['totalItems'] ?? 0;
      final int totalPages = paginationInfo?['totalPages'] ?? 0;
      final int currentPage = paginationInfo?['currentPage'] ?? page;
      final bool hasNextPage = paginationInfo?['hasNextPage'] ?? false;
      final bool hasPrevPage = paginationInfo?['hasPrevPage'] ?? false;
      final int perPageCount = paginationInfo?['perPage'] ?? perPage;

      if (productsJson == null) {
        return {
          'products': <FeaturedProduct>[],
          'totalProducts': totalProducts,
          'totalPages': totalPages,
          'currentPage': currentPage,
          'hasNextPage': hasNextPage,
          'hasPrevPage': hasPrevPage,
          'perPage': perPageCount,
        };
      }

      final List<FeaturedProduct> products =
          productsJson.map((item) => FeaturedProduct.fromJson(item)).toList();

      return {
        'products': products,
        'totalProducts': totalProducts,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'hasNextPage': hasNextPage,
        'hasPrevPage': hasPrevPage,
        'perPage': perPageCount,
      };
    } else {
      throw Exception('Failed to load featured products');
    }
  }

  // Keep the original method for backward compatibility
  Future<List<FeaturedProduct>> getFeaturedProducts() async {
    final result = await getFeaturedProductsWithPagination();
    return result['products'];
  }

  Future<List<FilterProducts>> getProductsByCatName(String catName) async {
    final uri = Uri.parse('$baseUrl/catName?catName=$catName');
    print("catname:$catName");
    final response = await http.get(
      uri,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> productsJson = jsonResponse['products'];

      return productsJson.map((item) => FilterProducts.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<FilterProducts>> getProductsByCatId(String catId,
      {int page = 1, int perPage = 10}) async {
    final uri = Uri.parse('$baseUrl/catId/$catId?page=$page&perPage=$perPage');
    final response = await http.get(
      uri,
    );
    return json.decode(response.body);
  }

  Future<List<FilterProducts>> getProductsBySubCatId(String subCatId,
      {int page = 1, int perPage = 10}) async {
    final uri = Uri.parse(
        '$baseUrl/subCatId?subCatId=$subCatId&page=$page&perPage=$perPage');
    final response = await http.get(
      uri,
    );
    return json.decode(response.body);
  }

  Future<List<FilterProducts>> filterByPrice({
    required int? minPrice,
    required int? maxPrice,
    String? catId,
    String? subCatId,
  }) async {
    final queryParams = {
      'minPrice': minPrice.toString(),
      'maxPrice': maxPrice.toString(),
      if (catId != null) 'catId': catId,
      if (subCatId != null) 'subCatId': subCatId,
    };
    final uri = Uri.parse('$baseUrl/filterByPrice')
        .replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> productsJson = jsonResponse['products'];

      return productsJson.map((item) => FilterProducts.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<FilterProducts>> getProductsByRating({
    required int? rating,
    String? catId,
    String? subCatId,
  }) async {
    final queryParams = {
      'rating': rating.toString(),
      if (catId != null) 'catId': catId,
      if (subCatId != null) 'subCatId': subCatId,
    };
    final uri =
        Uri.parse('$baseUrl/rating').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> productsJson = jsonResponse['products'];

      return productsJson.map((item) => FilterProducts.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Map<String, dynamic>> getProductCount() async {
    final uri = Uri.parse('$baseUrl/get/count');
    final response = await http.get(
      uri,
    );
    return json.decode(response.body);
  }

  Future<AllProduct> getProductById(String productId) async {
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/$productId');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return AllProduct.fromJson(data);
    } else {
      throw Exception('Failed to load product');
    }
  }
}