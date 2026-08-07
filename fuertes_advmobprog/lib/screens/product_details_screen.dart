import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product.dart';

// widgets
import '../widgets/custom_text.dart';

// ENHANCEMENT 2: the product details page, opened by tapping a card. The
// product comes in through the constructor so no second API call is needed.
// Stateful only because the image carousel tracks the current page.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  // The product to show.
  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // Controls the image carousel.
  final PageController _imageController = PageController();

  // Which image is showing, used to highlight the matching dot.
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

    // Use the thumbnail if there are no gallery images.
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
                // Dots, only when there is more than one image.
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

                // Price, with the original struck through when discounted.
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

                // Specifications, taken from the nested model objects.
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
                  // Already inside a ListView, so just map the reviews in.
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
                                  // Keep just the date part of the timestamp.
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

// A label and value row in the specifications list. Shows nothing when the
// value is empty so missing API fields do not leave blank rows.
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

// Five stars, filled, half or empty based on the rating.
class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        // Decide if this star is full, half or empty.
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
