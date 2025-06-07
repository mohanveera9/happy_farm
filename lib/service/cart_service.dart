import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/models/cart_model.dart';

class CartService {
  static const String baseUrl = 'https://happyfarm-server.onrender.com/api/cart';

  static Future<List<CartItem>> fetchCart(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final Uri url = Uri.parse("$baseUrl?userId=$userId");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load cart data: ${response.statusCode}');
    }
  }

  static Future<bool> deleteCartItem(String cartItemId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/$cartItemId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete cart item: ${response.statusCode}');
    }
  }

  static Future<bool> addToCart({
    required String productId,
    required String priceId,
    required int quantity,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token');

    if (userId == null) return false;

    final body = {
      "productId": productId,
      "priceId": priceId,
      "userId": userId,
      "quantity": quantity,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token ?? "",
      },
      body: json.encode(body),
    );

    return response.statusCode == 201;
  }

  //Get Cart Item by ID
  static Future<CartItem> getCartItemById(String cartItemId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/$cartItemId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );

    final result = json.decode(response.body);

    if (response.statusCode == 200 && result['success'] == true) {
      return CartItem.fromJson(result['data']);
    } else {
      throw Exception(result['message'] ?? 'Failed to fetch cart item');
    }
  }

  //Update Cart Item (Quantity or PriceId)
  static Future<CartItem> updateCartItem({
    required String cartItemId,
    int? quantity,
    String? priceId,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (quantity == null && priceId == null) {
      throw Exception('Either quantity or priceId must be provided');
    }

    final Map<String, dynamic> body = {};
    if (quantity != null) body['quantity'] = quantity;
    if (priceId != null) body['priceId'] = priceId;

    final response = await http.put(
      Uri.parse('$baseUrl/$cartItemId'),
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    final result = json.decode(response.body);

    if (response.statusCode == 200 && result['success'] == true) {
      return CartItem.fromJson(result['data']);
    } else {
      throw Exception(result['message'] ?? 'Failed to update cart item');
    }
  }
}
