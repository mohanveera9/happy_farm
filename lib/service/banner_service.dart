import 'dart:convert';
import 'package:happy_farm/models/banner_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BannerService {
  final String baseUrl = 'https://happyfarm-server.onrender.com/api';

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ------------------- Main Banners -------------------
  Future<List<BannerModel>> fetchMainBanners() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/banners'), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching main banners: $e');
    }
    return [];
  }

  Future<BannerModel?> fetchMainBannerById(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/banners/$id'), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BannerModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching main banner by ID: $e');
    }
    return null;
  }

  // ------------------- Home Side Banners -------------------
  Future<List<BannerModel>> fetchSideBanners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeSideBanners'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching side banners: $e');
    }
    return [];
  }

  Future<BannerModel?> fetchSideBannerById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeSideBanners/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BannerModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching side banner by ID: $e');
    }
    return null;
  }

  // ------------------- Home Bottom Banners -------------------
  Future<List<BannerModel>> fetchBottomBanners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeBottomBanners'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching bottom banners: $e');
    }
    return [];
  }

  Future<BannerModel?> fetchBottomBannerById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/homeBottomBanners/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BannerModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching bottom banner by ID: $e');
    }
    return null;
  }
}
