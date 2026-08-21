import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuertes_advmobprog/models/cart.dart';
import 'package:fuertes_advmobprog/models/product.dart';
import 'package:fuertes_advmobprog/providers/theme_provider.dart';

// A sample response from the API.
final sampleJson = {
  'id': 1,
  'title': 'Essence Mascara Lash Princess',
  'description': 'A popular mascara known for its volumizing effect.',
  'category': 'beauty',
  'price': 9.99,
  'discountPercentage': 10.48,
  'rating': 2.56,
  'stock': 99,
  'tags': ['beauty', 'mascara'],
  'brand': 'Essence',
  'sku': 'BEA-ESS-ESS-001',
  'weight': 4,
  'dimensions': {'width': 15.14, 'height': 13.08, 'depth': 22.99},
  'warrantyInformation': '1 week warranty',
  'shippingInformation': 'Ships in 3-5 business days',
  'availabilityStatus': 'In Stock',
  'reviews': [
    {
      'rating': 3,
      'comment': 'Would not recommend!',
      'date': '2025-04-30T09:41:02.053Z',
      'reviewerName': 'Eleanor Collins',
      'reviewerEmail': 'eleanor.collins@x.dummyjson.com',
    },
  ],
  'returnPolicy': '30 days return policy',
  'minimumOrderQuantity': 24,
  'meta': {
    'createdAt': '2025-04-30T09:41:02.053Z',
    'updatedAt': '2025-04-30T09:41:02.053Z',
    'barcode': '9164035109868',
    'qrCode': 'https://cdn.dummyjson.com/public/qr-code.png',
  },
  'images': ['https://cdn.dummyjson.com/product-images/1/1.webp'],
  'thumbnail': 'https://cdn.dummyjson.com/product-images/1/thumbnail.webp',
};

// A sample cart response from the API.
final sampleCartJson = {
  'id': 5,
  'products': [
    {
      'id': 161,
      'title': 'Samsung Galaxy Tab White',
      'price': 349.99,
      'quantity': 4,
      'total': 1399.96,
      'discountPercentage': 18.2,
      'discountedTotal': 1145.17,
      'thumbnail': 'https://cdn.dummyjson.com/product-images/161/thumbnail.webp',
    },
  ],
  'total': 1467.88,
  'discountedTotal': 1205.8,
  'userId': 5,
  'totalProducts': 3,
  'totalQuantity': 12,
};

void main() {
  test('Product.fromJson reads the response', () {
    final p = Product.fromJson(sampleJson);

    expect(p.title, 'Essence Mascara Lash Princess');
    expect(p.price, 9.99);
    expect(p.stock, 99);
    expect(p.dimensions.width, 15.14);
    expect(p.reviews.first.reviewerName, 'Eleanor Collins');
    expect(p.weight, 4.0);
  });

  test('Product.fromJson uses defaults when fields are missing', () {
    final p = Product.fromJson({});

    expect(p.id, 0);
    expect(p.title, '');
    expect(p.price, 0.0);
    expect(p.reviews, isEmpty);
  });

  test('discountedPrice takes the discount off the price', () {
    final p = Product.fromJson(sampleJson);
    expect(p.discountedPrice, closeTo(8.94, 0.01));
  });

  test('Cart.fromJson reads the response', () {
    final c = Cart.fromJson(sampleCartJson);

    expect(c.id, 5);
    expect(c.userId, 5);
    expect(c.total, 1467.88);
    expect(c.discountedTotal, 1205.8);
    expect(c.totalQuantity, 12);
    expect(c.products, hasLength(1));
    expect(c.products.first.title, 'Samsung Galaxy Tab White');
  });

  test('Cart.fromJson uses defaults when fields are missing', () {
    final c = Cart.fromJson({});

    expect(c.id, 0);
    expect(c.userId, 0);
    expect(c.total, 0.0);
    expect(c.products, isEmpty);
  });

  test('CartProduct.fromJson reads the line item', () {
    final line = CartProduct.fromJson(
      (sampleCartJson['products'] as List).first as Map<String, dynamic>,
    );

    expect(line.id, 161);
    expect(line.quantity, 4);
    expect(line.price, 349.99);
    expect(line.discountedTotal, 1145.17);
  });

  test('Cart.toJson round trips', () {
    final c = Cart.fromJson(sampleCartJson);
    final again = Cart.fromJson(c.toJson());

    expect(again.id, c.id);
    expect(again.discountedTotal, c.discountedTotal);
    expect(again.products.first.title, c.products.first.title);
  });

  test('ThemeProvider toggles between light and dark', () {
    final provider = ThemeProvider();
    expect(provider.isDark, isFalse);

    provider.toggleTheme();
    expect(provider.isDark, isTrue);
    expect(provider.darkTheme.brightness, Brightness.dark);
  });
}
