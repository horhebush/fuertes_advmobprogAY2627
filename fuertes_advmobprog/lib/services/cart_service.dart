import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

// Handles the cart API calls and returns typed carts to the screens.
class CartService {
  // Gets every cart from the API.
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // ENHANCEMENT 3: gets the cart of one user instead of all of them.
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      // A user with no cart yet returns an empty list, not an error.
      if (cartsJson.isEmpty) return null;
      return Cart.fromJson(cartsJson.first);
    } else {
      throw Exception('Failed to load the cart');
    }
  }

  // ENHANCEMENT 3: sends a product and its quantity to the cart endpoint.
  Future<Cart> addToCart(int userId, int productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add to cart');
    }
  }
}
