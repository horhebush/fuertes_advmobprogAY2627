import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

// Handles the API calls and returns typed products to the screens.
class ProductService {
  // Gets every product from the API.
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

  // ENHANCEMENT 1: searches through the API instead of filtering in the app.
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

  // Gets one product by id, for the cart items that only carry an id.
  Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse('$host/products/$id'));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load the product');
    }
  }
}
