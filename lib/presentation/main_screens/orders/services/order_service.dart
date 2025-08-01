import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static String? baseUrl = '${dotenv.env['BASE_URL']}';

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': '$token',
    };
  }

  Future<Map<String, dynamic>?> createOrder({
    required String name,
    required String phoneNumber,
    required String email,
    required String address,
    required String pincode,
  }) async {
    final headers = await _getAuthHeaders();
    final body = jsonEncode({
      'shippingDetails': {
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
        'pincode': pincode,
        'email': email,
      }
    });

    final response = await http.post(
      Uri.parse('$baseUrl/payment/create-order'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      print('Failed to create order: ${response.body}');
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    final headers = await _getAuthHeaders();
    final body = jsonEncode({
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'paymentHistoryId': orderId,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/payment/verify-order'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['success'] == true;
    } else {
      return false;
    }
  }

  // Enhanced fetch all orders with pagination support
  Future<Map<String, dynamic>?> fetchAllOrdersWithPagination({
    int page = 1,
    int perPage = 4,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final uri = Uri.parse('$baseUrl/orders').replace(
        queryParameters: {
          'page': page.toString(),
          'perPage': perPage.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);
      print('Orders ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if the response has the expected structure
        if (data != null && data['success'] == true && data['orders'] != null) {
          final orders = data['orders'] as List;

          // Since your API doesn't seem to return pagination info,
          // we'll calculate it based on the response
          final totalOrders = orders.length;
          final hasNextPage =
              orders.length == perPage; // Assume more if we got full page

          return {
            'orders': orders,
            'pagination': {
              'totalPages':
                  data['totalPages'] ?? (hasNextPage ? page + 1 : page),
              'totalOrders': data['totalOrders'] ?? totalOrders,
              'hasNextPage': data['hasMore'] ?? hasNextPage,
              'currentPage': data['currentPage'] ?? page,
            },
          };
        } else {
          print('Invalid response structure: ${data}');
          return null;
        }
      } else {
        print('Failed to fetch orders: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching paginated orders: $e');
      return null;
    }
  }

  // Keep the original method for backward compatibility
  Future<List<dynamic>?> fetchAllOrders() async {
    try {
      final result = await fetchAllOrdersWithPagination(page: 1, perPage: 100);
      return result?['orders'];
    } catch (e) {
      print('Error fetching all orders: $e');
      return null;
    }
  }

  // Fetch orders with status filter and pagination
  Future<Map<String, dynamic>?> fetchOrdersByStatus({
    required String status,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final uri = Uri.parse('$baseUrl/orders').replace(
        queryParameters: {
          'page': page.toString(),
          'perPage': perPage.toString(),
          'status': status,
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'orders': data['data']['orders'],
          'pagination': data['data']['pagination'],
        };
      } else {
        print('Failed to fetch orders by status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching orders by status: $e');
      return null;
    }
  }

  // Fetch a specific order by ID
  Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']; // Single order object
      } else {
        print('Failed to fetch order by ID: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching order by ID: $e');
      return null;
    }
  }

  // Cancel order
  Future<Map<String, dynamic>?> cancelOrder(String orderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/user/cancel/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'order': data['data']['order'],
          'refund': data['data']['refund'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'],
        };
      }
    } catch (e) {
      print('Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again later.',
      };
    }
  }

  // Get refund details with pagination
  Future<Map<String, dynamic>?> getRefundDetails({
    String? status,
    String? orderId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (orderId != null) 'orderId': orderId,
      };

      final uri = Uri.parse('$baseUrl/orders/refunds')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to fetch refund details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching refund details: $e');
      return null;
    }
  }

  // Search orders with pagination
  Future<Map<String, dynamic>?> searchOrders({
    required String query,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final uri = Uri.parse('$baseUrl/orders/search').replace(
        queryParameters: {
          'q': query,
          'page': page.toString(),
          'perPage': perPage.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'orders': data['data']['orders'],
          'pagination': data['data']['pagination'],
        };
      } else {
        print('Failed to search orders: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error searching orders: $e');
      return null;
    }
  }
}
