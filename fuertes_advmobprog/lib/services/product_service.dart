import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

// Handles the API calls. This is the only class that knows about http and JSON,
// so the screens just ask for a list of products.
class ProductService {
  // GET $host/products
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$host/products'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // ENHANCEMENT 1: search is done by the API instead of filtering in the app.
  Future<List<Product>> searchProducts(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final response = await http.get(
      Uri.parse('$host/products/search?q=$encoded'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search products');
    }
  }
}
