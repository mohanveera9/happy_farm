import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  final String? baseUrl = '${dotenv.env['BASE_URL']}/products';

  // Smart headers method - only adds Authorization if token exists
  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("token:$token");

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // Only add Authorization header if token is not null and not empty
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print("Added Authorization header");
    } else {
      print("No token found, making request without authorization");
    }

    return headers;
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
    try {
      // Build query parameters
      final queryParams = <String, String>{};

      if (rating != null) {
        queryParams['rating'] = rating.toString();
      }
      if (catId != null) {
        queryParams['catId'] = catId;
      }
      if (subCatId != null) {
        queryParams['subCatId'] = subCatId;
      }

      final uri =
          Uri.parse('$baseUrl/rating').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Check if the expected structure exists
        if (!jsonResponse.containsKey('data')) {
          throw Exception('Invalid response structure: missing data field');
        }

        final List<dynamic> productsJson = jsonResponse['data'];

        // Convert to FilterProducts objects
        return productsJson
            .map((item) => FilterProducts.fromJson(item))
            .toList();
      } else if (response.statusCode == 404) {
        throw Exception('No products found with the specified rating');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request parameters');
      } else {
        throw Exception(
            'Failed to load products: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      // Log the error for debugging
      print('Error in getProductsByRating: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProductCount() async {
    final uri = Uri.parse('$baseUrl/get/count');
    final response = await http.get(
      uri,
    );
    return json.decode(response.body);
  }

  // SIMPLIFIED: Smart getProductById method - no duplicate functions needed
  Future<AllProduct> getProductById(String productId) async {
    try {
      final headers = await getHeaders(); // This already handles null token
      final uri = Uri.parse('$baseUrl/$productId');
      print("Fetching product from: $uri");

      final response = await http.get(uri, headers: headers);
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        Map<String, dynamic> productData;

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            productData = responseData['data'];
          } else if (responseData.containsKey('product')) {
            productData = responseData['product'];
          } else {
            productData = responseData;
          }
        } else {
          throw Exception(
              'Invalid response format: expected Map but got ${responseData.runtimeType}');
        }

        if (productData.isEmpty) {
          throw Exception('Product data is null or empty');
        }

        return AllProduct.fromJson(productData);
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else if (response.statusCode == 400 &&
          response.body.contains('Invalid token')) {
        // Handle invalid token by retrying without authorization
        print("Invalid token detected, retrying without authorization");
        return await _getProductByIdWithoutAuth(productId);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        String errorMessage =
            'Failed to load product. Server returned ${response.statusCode}: ${response.reasonPhrase}';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          // If error body is not JSON, use default message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in getProductById: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Network error: ${e.toString()}');
      }
    }
  }

  // Fallback method for when token is invalid
  Future<AllProduct> _getProductByIdWithoutAuth(String productId) async {
    try {
      final uri = Uri.parse('$baseUrl/$productId');
      print("Retrying without auth: $uri");

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      print("Retry response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        Map<String, dynamic> productData;

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            productData = responseData['data'];
          } else if (responseData.containsKey('product')) {
            productData = responseData['product'];
          } else {
            productData = responseData;
          }
        } else {
          throw Exception(
              'Invalid response format: expected Map but got ${responseData.runtimeType}');
        }

        return AllProduct.fromJson(productData);
      } else {
        throw Exception('Failed to load product even without authentication');
      }
    } catch (e) {
      print('Error in _getProductByIdWithoutAuth: $e');
      rethrow;
    }
  }
}
