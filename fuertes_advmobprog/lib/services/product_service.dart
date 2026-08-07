import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

/// The SERVICE layer.
///
/// This is the only place in the app that knows about HTTP, URLs and JSON. It
/// takes the raw response, checks the status code, and hands back a typed
/// `List<Product>`. Screens depend on this class rather than on `http`, so the
/// networking could be swapped for a cache or a mock without touching any UI.
class ProductService {
  /// Fetches every product from `GET $host/products`.
  ///
  /// Throws an [Exception] on a non-200 response so the FutureBuilder in the UI
  /// can surface the failure through `snapshot.hasError`.
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

  /// ENHANCEMENT 1 (search bar) — server-side search.
  ///
  /// Queries `GET $host/products/search?q=...` so the filtering is done by the
  /// API rather than in the app. The query is passed through
  /// [Uri.encodeQueryComponent] so spaces and symbols cannot break the URL.
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
