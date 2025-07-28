import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';

class CategoryService {
  static String? baseUrl = '${dotenv.env['BASE_URL']}/category';

  //Get all categories (with hierarchy if applicable)
  static Future<List<CategoryModel>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse(baseUrl!);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': token,
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['categoryList'] is List) {
      return (data['categoryList'] as List)
          .map((item) => CategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  //Get category by ID
  static Future<CategoryModel> getCategoryById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/$id');

    final response = await http.get(
      url,
      headers: {
        'Authorization': token ?? '',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['categoryData'] != null) {
      return CategoryModel.fromJson(data['categoryData']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch category by ID');
    }
  }
}
