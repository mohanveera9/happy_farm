import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static String? baseUrl = '${dotenv.env['BASE_URL']}/my-list';

  // Original method - kept for backward compatibility
  static Future<List<Map<String, dynamic>>> fetchWishlist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    final String? token = prefs.getString('token');

    if (userId == null || token == null) {
      throw Exception('User not logged in');
    }

    final response = await http.get(
      Uri.parse('$baseUrl?userId=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      
      // Handle different response formats
      if (result is Map<String, dynamic>) {
        if (result['success'] == true && result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        } else if (result['data'] != null) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      } else if (result is List) {
        return List<Map<String, dynamic>>.from(result);
      }
      
      throw Exception('No data found');
    } else {
      final result = json.decode(response.body);
      throw Exception(result['message'] ?? 'Failed to load wishlist');
    }
  }

  // New method with pagination support
  static Future<Map<String, dynamic>> fetchWishlistWithPagination({
    required int page,
    required int perPage,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    final String? token = prefs.getString('token');

    if (userId == null || token == null) {
      throw Exception('User not logged in');
    }

    final Uri url = Uri.parse('$baseUrl?userId=$userId&page=$page&perPage=$perPage');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Handle the case where API returns direct data array or success format
      if (data is Map<String, dynamic>) {
        // Case 1: API returns with pagination info
        if (data['data'] is List && data['pagination'] != null) {
          final items = List<Map<String, dynamic>>.from(data['data']);
          final pagination = data['pagination'];
          
          return {
            'items': items,
            'currentPage': pagination['currentPage'] ?? 1,
            'totalPages': pagination['totalPages'] ?? 1,
            'totalItems': pagination['totalItems'] ?? 0,
            'hasNextPage': pagination['hasNextPage'] ?? false,
            'hasPrevPage': pagination['hasPrevPage'] ?? false,
            'perPage': pagination['perPage'] ?? perPage,
          };
        }
        // Case 2: API returns success format without pagination
        else if (data['success'] == true && data['data'] is List) {
          final items = List<Map<String, dynamic>>.from(data['data']);
          final totalItems = items.length;
          final totalPages = (totalItems / perPage).ceil();
          
          return {
            'items': items,
            'currentPage': 1,
            'totalPages': totalPages,
            'totalItems': totalItems,
            'hasNextPage': false,
            'hasPrevPage': false,
            'perPage': perPage,
          };
        }
        // Case 3: API returns data array directly
        else if (data['data'] is List) {
          final items = List<Map<String, dynamic>>.from(data['data']);
          final totalItems = items.length;
          final totalPages = (totalItems / perPage).ceil();
          
          return {
            'items': items,
            'currentPage': 1,
            'totalPages': totalPages,
            'totalItems': totalItems,
            'hasNextPage': false,
            'hasPrevPage': false,
            'perPage': perPage,
          };
        }
      }
      // Case 4: API returns array directly
      else if (data is List) {
        final items = List<Map<String, dynamic>>.from(data);
        final totalItems = items.length;
        final totalPages = (totalItems / perPage).ceil();
        
        return {
          'items': items,
          'currentPage': 1,
          'totalPages': totalPages,
          'totalItems': totalItems,
          'hasNextPage': false,
          'hasPrevPage': false,
          'perPage': perPage,
        };
      }
      
      throw Exception('Unexpected response format');
    } else {
      final result = json.decode(response.body);
      throw Exception(result['message'] ?? 'Failed to load wishlist');
    }
  }

  static Future<String> removeFromWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/$productId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      // Success message from backend
      return body['message'] ?? 'Item removed from wishlist.';
    } else {
      // Return backend's error message or fallback
      final errorMessage = body['message'] ?? body['error'] ?? 'Failed to remove item.';
      throw Exception(errorMessage);
    }
  }

  static Future<String> addToMyList(String productId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'productId': productId}),
    );

    final result = json.decode(response.body);
    if (response.statusCode == 201 && result['success'] == true) {
      return result['data']['id']; // return wishlist entry ID
    } else {
      throw Exception(result['message'] ?? 'Failed to add to wishlist');
    }
  }

  static Future<Map<String, dynamic>> getItemById(String itemId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/$itemId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final result = json.decode(response.body);
    if (response.statusCode == 200 && result['success'] == true) {
      return result['data'];
    } else {
      throw Exception(result['message'] ?? 'Failed to fetch item');
    }
  }
}