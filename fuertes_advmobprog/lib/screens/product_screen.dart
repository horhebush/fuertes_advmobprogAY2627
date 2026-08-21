import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product.dart';

// services
import '../services/product_service.dart';

// widgets
import '../widgets/custom_text.dart';

// screens
import 'detail_screen.dart';

// The Shop tab. Shows the products coming from the API in a grid.
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _service = ProductService();

  final TextEditingController _searchController = TextEditingController();

  late Future<List<Product>> _productsFuture;

  Timer? _debounce;

  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    // Initial load: the full catalogue.
    _productsFuture = _service.getAllProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ENHANCEMENT 1: runs the search after the user stops typing.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final trimmed = query.trim();
      if (!mounted) return;
      setState(() {
        _activeQuery = trimmed;
        _productsFuture = trimmed.isEmpty
            ? _service.getAllProducts()
            : _service.searchProducts(trimmed);
      });
    });
  }

  // Clears the search box and shows the full list again.
  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _activeQuery = '';
      _productsFuture = _service.getAllProducts();
    });
  }

  // Runs the request again.
  void _retry() {
    setState(() {
      _productsFuture = _activeQuery.isEmpty
          ? _service.getAllProducts()
          : _service.searchProducts(_activeQuery);
    });
  }

  // ENHANCEMENT 2: opens the details page for the tapped product.
  void _openDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENHANCEMENT 1: search bar above the product list.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search products',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                prefixIcon: Icon(Icons.search, size: 20.sp),
                // The clear button only exists while there is text to clear.
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, size: 20.sp),
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                      ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, size: 48.sp),
                          SizedBox(height: 12.h),
                          CustomText(
                            text: 'Error: ${snapshot.error}',
                            fontSize: 13.sp,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: _activeQuery.isEmpty
                          ? 'No products found.'
                          : 'No products match "$_activeQuery".',
                      fontSize: 14.sp,
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  itemCount: products.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => _openDetails(product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// One product tile in the grid.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;

  // Called when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/images/placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: CustomText(
                          text: '-${product.discountPercentage.toStringAsFixed(0)}%',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: scheme.onError,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      const Spacer(),
                      Icon(Icons.star, size: 12.sp, color: Colors.amber),
                      SizedBox(width: 2.w),
                      CustomText(
                        text: product.rating.toStringAsFixed(1),
                        fontSize: 11.sp,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
