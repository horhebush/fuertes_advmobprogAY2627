import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fuertes_advmobprog/models/product.dart';
import 'package:fuertes_advmobprog/providers/theme_provider.dart';

// A sample response copied from the API.
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

void main() {
  test('Product.fromJson reads the response', () {
    final p = Product.fromJson(sampleJson);

    expect(p.title, 'Essence Mascara Lash Princess');
    expect(p.price, 9.99);
    expect(p.stock, 99);
    expect(p.dimensions.width, 15.14);
    expect(p.reviews.first.reviewerName, 'Eleanor Collins');
    // The API sends "weight": 4, so this has to survive an int.
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

  test('ThemeProvider toggles between light and dark', () {
    final provider = ThemeProvider();
    expect(provider.isDark, isFalse);

    provider.toggleTheme();
    expect(provider.isDark, isTrue);
    expect(provider.darkTheme.brightness, Brightness.dark);
  });
}
