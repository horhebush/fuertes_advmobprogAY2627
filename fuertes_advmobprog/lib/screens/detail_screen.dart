import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product.dart';

// services
import '../services/cart_service.dart';
import '../services/product_service.dart';

// widgets
import '../widgets/custom_text.dart';

import '../constants.dart';

// The product details page. Takes a product from the grid, or an id from the
// cart, which is all a cart line item carries.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, this.product, this.productId})
    : assert(
        product != null || productId != null,
        'Pass either a product or a productId',
      );

  final Product? product;
  final int? productId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ProductService _productService = ProductService();

  final CartService _cartService = CartService();

  final PageController _imageController = PageController();

  int _imageIndex = 0;

  bool _adding = false;

  Future<Product>? _productFuture;

  @override
  void initState() {
    super.initState();
    // Only the cart path needs a request; the grid already has the product.
    if (widget.product == null) {
      _productFuture = _productService.getProductById(widget.productId!);
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  // Runs the request again.
  void _retry() {
    setState(() {
      _productFuture = _productService.getProductById(widget.productId!);
    });
  }

  // ENHANCEMENT 3: sends this product to the cart endpoint.
  Future<void> _addToCart(Product product) async {
    setState(() => _adding = true);
    try {
      final cart = await _cartService.addToCart(defaultUserId, product.id, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: '${product.title} added to cart. '
                'Cart total \$${cart.discountedTotal.toStringAsFixed(2)}.',
            fontSize: 12.sp,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: CustomText(text: '$e', fontSize: 12.sp)),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    if (product != null) return _buildDetails(product);

    // ENHANCEMENT 1: the cart opens this same screen by id.
    return FutureBuilder<Product>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: CustomText(
                text: 'Product Details',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: CustomText(
                text: 'Product Details',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            body: Center(
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
            ),
          );
        }

        return _buildDetails(snapshot.data!);
      },
    );
  }

  // The page itself, once the product is available from either path.
  Widget _buildDetails(Product product) {
    final scheme = Theme.of(context).colorScheme;

    final images = product.images.isNotEmpty
        ? product.images
        : [product.thumbnail];

    final hasDiscount = product.discountPercentage > 0;
    final inStock = product.stock > 0;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Product Details',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24.h),
        children: [
          SizedBox(
            height: 260.h,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _imageController,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Image.network(
                      images[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/placeholder.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 10.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        final active = i == _imageIndex;
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          width: active ? 9.w : 6.w,
                          height: active ? 9.w : 6.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? scheme.primary
                                : scheme.onSurfaceVariant.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: product.title,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: [
                    if (product.brand.isNotEmpty) product.brand,
                    product.category,
                  ].join('  •  '),
                  fontSize: 12.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: 12.h),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      text: '\$${product.discountedPrice.toStringAsFixed(2)}',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                    if (hasDiscount) ...[
                      SizedBox(width: 8.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 3.h),
                        child: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.sp,
                            color: scheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: CustomText(
                          text:
                              '${product.discountPercentage.toStringAsFixed(1)}% off',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12.h),

                Row(
                  children: [
                    _StarRating(rating: product.rating),
                    SizedBox(width: 6.w),
                    CustomText(
                      text: product.rating.toStringAsFixed(2),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    const Spacer(),
                    Icon(
                      inStock ? Icons.check_circle : Icons.remove_circle,
                      size: 14.sp,
                      color: inStock ? Colors.green : scheme.error,
                    ),
                    SizedBox(width: 4.w),
                    CustomText(
                      text: product.availabilityStatus.isEmpty
                          ? (inStock ? 'In Stock' : 'Out of Stock')
                          : product.availabilityStatus,
                      fontSize: 12.sp,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                _SectionTitle(title: 'Description'),
                SizedBox(height: 6.h),
                CustomText(
                  text: product.description,
                  fontSize: 13.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: 20.h),

                _SectionTitle(title: 'Specifications'),
                SizedBox(height: 6.h),
                _SpecRow(label: 'SKU', value: product.sku),
                _SpecRow(label: 'Stock', value: '${product.stock} units'),
                _SpecRow(label: 'Weight', value: '${product.weight}'),
                _SpecRow(
                  label: 'Dimensions',
                  value: '${product.dimensions.width} x '
                      '${product.dimensions.height} x '
                      '${product.dimensions.depth}',
                ),
                _SpecRow(label: 'Warranty', value: product.warrantyInformation),
                _SpecRow(label: 'Shipping', value: product.shippingInformation),
                _SpecRow(label: 'Returns', value: product.returnPolicy),
                _SpecRow(
                  label: 'Min. order',
                  value: '${product.minimumOrderQuantity}',
                ),

                if (product.tags.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  _SectionTitle(title: 'Tags'),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: product.tags
                        .map(
                          (t) => Chip(
                            label: CustomText(text: t, fontSize: 11.sp),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],

                SizedBox(height: 20.h),
                _SectionTitle(title: 'Reviews (${product.reviews.length})'),
                SizedBox(height: 8.h),
                if (product.reviews.isEmpty)
                  CustomText(
                    text: 'No reviews yet.',
                    fontSize: 12.sp,
                    color: scheme.onSurfaceVariant,
                  )
                else
                  ...product.reviews.map(
                    (r) => Card(
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _StarRating(rating: r.rating.toDouble()),
                                const Spacer(),
                                CustomText(
                                  text: r.date.length >= 10
                                      ? r.date.substring(0, 10)
                                      : r.date,
                                  fontSize: 10.sp,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            CustomText(
                              text: r.comment,
                              fontSize: 12.sp,
                            ),
                            SizedBox(height: 4.h),
                            CustomText(
                              text: r.reviewerName,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // ENHANCEMENT 3: adds this product to the cart of the current user.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: FilledButton.icon(
            onPressed: _adding ? null : () => _addToCart(product),
            icon: _adding
                ? SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.add_shopping_cart, size: 18.sp),
            label: CustomText(
              text: _adding ? 'Adding...' : 'Add to Cart',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(46.h),
            ),
          ),
        ),
      ),
    );
  }
}

// Bold heading between sections.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text: title,
      fontSize: 15.sp,
      fontWeight: FontWeight.bold,
    );
  }
}

// A label and value row in the specifications list.
class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92.w,
            child: CustomText(
              text: label,
              fontSize: 12.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
          // Expanded so long values wrap instead of overflowing the row.
          Expanded(
            child: CustomText(
              text: value,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Star rating out of five.
class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i;
        return Icon(
          filled
              ? Icons.star
              : half
                  ? Icons.star_half
                  : Icons.star_border,
          size: 14.sp,
          color: Colors.amber,
        );
      }),
    );
  }
}
