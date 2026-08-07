import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product.dart';

// widgets
import '../widgets/custom_text.dart';

/// ENHANCEMENT 2 - the product details page.
///
/// Opened by tapping a card on the Shop tab. The [Product] is passed straight
/// in through the constructor, so this screen renders from data the app already
/// has and never issues a second network request.
///
/// Stateful only because the image carousel tracks which page is showing -
/// ephemeral state that belongs to this screen alone.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  /// The product to display, handed over by the grid.
  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  /// Drives the image carousel.
  final PageController _imageController = PageController();

  /// Index of the visible image, used to highlight the matching dot.
  int _imageIndex = 0;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final scheme = Theme.of(context).colorScheme;

    // Fall back to the thumbnail when the API returns no gallery images, so the
    // carousel always has at least one page.
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
          // -------------------------------------------------------------------
          // Image carousel
          // -------------------------------------------------------------------
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
                // Dot indicators, drawn only when there is more than one image.
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
                // ---------------------------------------------------------------
                // Title, brand and category
                // ---------------------------------------------------------------
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

                // ---------------------------------------------------------------
                // Pricing - shows the struck-through original when discounted
                // ---------------------------------------------------------------
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

                // ---------------------------------------------------------------
                // Rating and availability
                // ---------------------------------------------------------------
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

                // ---------------------------------------------------------------
                // Description
                // ---------------------------------------------------------------
                _SectionTitle(title: 'Description'),
                SizedBox(height: 6.h),
                CustomText(
                  text: product.description,
                  fontSize: 13.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: 20.h),

                // ---------------------------------------------------------------
                // Specifications pulled from the nested model objects
                // ---------------------------------------------------------------
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

                // ---------------------------------------------------------------
                // Tags
                // ---------------------------------------------------------------
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

                // ---------------------------------------------------------------
                // Reviews from the nested reviews array
                // ---------------------------------------------------------------
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
                  // Not a ListView: this is already inside a scrolling ListView,
                  // so the reviews are simply mapped into the column.
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
                                  // Trim the ISO timestamp down to the date.
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
    );
  }
}

/// A bold heading used to separate sections of the details page.
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

/// A label/value pair in the specifications list.
///
/// Renders nothing when [value] is empty, so absent API fields do not leave
/// blank rows behind.
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

/// Five stars, filled / half / empty according to [rating] out of 5.
class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        // Compare against i to decide full, half or empty for this position.
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
