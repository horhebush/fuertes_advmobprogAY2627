// Tests for Lab Activity 2 - API.
//
// These cover the parts that can be verified without a live network: the model's
// JSON decoding (including the awkward int-vs-double cases the API returns), the
// theme provider's app state, and the details page rendering from a Product.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fuertes_advmobprog/models/product.dart';
import 'package:fuertes_advmobprog/providers/theme_provider.dart';
import 'package:fuertes_advmobprog/screens/product_details_screen.dart';

/// A trimmed-down copy of a real dummyjson.com product payload.
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
  group('Product.fromJson', () {
    test('decodes every field of a full payload', () {
      final p = Product.fromJson(sampleJson);

      expect(p.id, 1);
      expect(p.title, 'Essence Mascara Lash Princess');
      expect(p.category, 'beauty');
      expect(p.price, 9.99);
      expect(p.rating, 2.56);
      expect(p.stock, 99);
      expect(p.tags, ['beauty', 'mascara']);
      expect(p.brand, 'Essence');
      expect(p.availabilityStatus, 'In Stock');
      expect(p.minimumOrderQuantity, 24);
      expect(p.images, hasLength(1));
      expect(p.dimensions.width, 15.14);
      expect(p.meta.barcode, '9164035109868');
    });

    test('accepts an int where a double is expected', () {
      // The API sends `"weight": 4`, not 4.0 - a straight cast to double throws.
      final p = Product.fromJson(sampleJson);
      expect(p.weight, 4.0);
    });

    test('decodes the nested reviews array', () {
      final p = Product.fromJson(sampleJson);

      expect(p.reviews, hasLength(1));
      expect(p.reviews.first.rating, 3);
      expect(p.reviews.first.reviewerName, 'Eleanor Collins');
      expect(p.reviews.first.comment, 'Would not recommend!');
    });

    test('falls back to safe defaults on an empty payload', () {
      // Guards against a partial or changed response crashing the UI.
      final p = Product.fromJson({});

      expect(p.id, 0);
      expect(p.title, '');
      expect(p.price, 0.0);
      expect(p.tags, isEmpty);
      expect(p.reviews, isEmpty);
      expect(p.dimensions.width, 0.0);
      expect(p.meta.barcode, '');
    });

    test('computes the discounted price', () {
      final p = Product.fromJson(sampleJson);
      // 9.99 less 10.48% = 8.943...
      expect(p.discountedPrice, closeTo(8.94, 0.01));
    });
  });

  group('ThemeProvider', () {
    test('starts in light mode', () {
      expect(ThemeProvider().isDark, isFalse);
    });

    test('toggleTheme flips the mode and notifies listeners', () {
      final provider = ThemeProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleTheme();
      expect(provider.isDark, isTrue);
      expect(notifications, 1);

      provider.toggleTheme();
      expect(provider.isDark, isFalse);
      expect(notifications, 2);
    });

    test('exposes matching light and dark themes', () {
      final provider = ThemeProvider();
      expect(provider.lightTheme.brightness, Brightness.light);
      expect(provider.darkTheme.brightness, Brightness.dark);
    });
  });

  group('ProductDetailsScreen', () {
    testWidgets('renders the product passed to it', (tester) async {
      final product = Product.fromJson(sampleJson);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(412, 715),
          builder: (_, _) => MaterialApp(
            home: ProductDetailsScreen(product: product),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Product Details'), findsOneWidget);
      expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
      // Discounted price is shown, along with the discount badge.
      expect(find.text('\$8.94'), findsOneWidget);
      expect(find.text('10.5% off'), findsOneWidget);
      expect(find.text('In Stock'), findsOneWidget);
      // The single review from the payload made it onto the page.
      expect(find.text('Reviews (1)'), findsOneWidget);
      expect(find.text('Would not recommend!'), findsOneWidget);
      expect(find.text('Eleanor Collins'), findsOneWidget);
    });
  });
}
