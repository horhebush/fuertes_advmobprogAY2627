import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/cart.dart';

// services
import '../services/cart_service.dart';

// widgets
import '../widgets/custom_text.dart';

// screens
import 'detail_screen.dart';

import '../constants.dart';

// ENHANCEMENT 1: the Cart tab. Shows the cart of one user from the API.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.userId = defaultUserId});

  final int userId;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _service = CartService();

  late Future<Cart?> _cartFuture;

  // The rows once loaded, so the steppers can change them without refetching.
  List<_CartLine> _lines = [];

  int _loadedCartId = 0;

  @override
  void initState() {
    super.initState();
    // ENHANCEMENT 3: one user's cart, not every cart in the API.
    _cartFuture = _service.getCartByUserId(widget.userId);
  }

  // Runs the request again.
  void _retry() {
    setState(() {
      _loadedCartId = 0;
      _lines = [];
      _cartFuture = _service.getCartByUserId(widget.userId);
    });
  }

  // Copies the fetched items into editable rows, once per response.
  void _seedLines(Cart cart) {
    if (_loadedCartId == cart.id) return;
    _loadedCartId = cart.id;
    _lines = cart.products.map(_CartLine.new).toList();
  }

  // Raises or lowers a row, removing it when it reaches zero.
  void _changeQuantity(_CartLine line, int delta) {
    setState(() {
      final next = line.quantity + delta;
      if (next <= 0) {
        _lines.remove(line);
      } else {
        line.quantity = next;
      }
    });
  }

  // ENHANCEMENT 1: cart rows open the same detail screen the grid uses.
  void _openDetails(_CartLine line) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(productId: line.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Cart?>(
        future: _cartFuture,
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

          final cart = snapshot.data;

          if (cart == null) {
            return _EmptyCart(
              message: 'User #${widget.userId} has no cart yet.',
            );
          }

          _seedLines(cart);

          if (_lines.isEmpty) {
            return const _EmptyCart(message: 'Your cart is empty.');
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    return _CartRow(
                      line: line,
                      onTap: () => _openDetails(line),
                      onIncrement: () => _changeQuantity(line, 1),
                      onDecrement: () => _changeQuantity(line, -1),
                    );
                  },
                ),
              ),
              _CartSummary(lines: _lines),
            ],
          );
        },
      ),
    );
  }
}

// One editable row, so the steppers do not have to rebuild the model.
class _CartLine {
  _CartLine(this.product) : quantity = product.quantity;

  final CartProduct product;

  int quantity;

  int get id => product.id;

  // The API sends a total for the original quantity, so work back to one unit.
  double get discountedUnitPrice => product.quantity == 0
      ? product.price
      : product.discountedTotal / product.quantity;

  double get total => discountedUnitPrice * quantity;
}

// A cart line item with its thumbnail, price and quantity stepper.
class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.line,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final _CartLine line;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = line.product;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 10.h),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            children: [
              SizedBox(
                width: 64.w,
                height: 64.w,
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: product.title,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '\$${product.price.toStringAsFixed(2)}',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text:
                          '${product.discountPercentage.toStringAsFixed(0)}% off'
                          '  •  \$${line.total.toStringAsFixed(2)} total',
                      fontSize: 10.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _StepperButton(icon: Icons.add, onPressed: onIncrement),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: '${line.quantity}',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 4.h),
                  _StepperButton(icon: Icons.remove, onPressed: onDecrement),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A small square + or - button on a cart row.
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(icon, size: 16.sp, color: scheme.onSecondaryContainer),
      ),
    );
  }
}

// The totals and the order button under the cart list.
class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.lines});

  final List<_CartLine> lines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final subtotal = lines.fold<double>(0, (sum, line) => sum + line.total);
    final items = lines.fold<int>(0, (sum, line) => sum + line.quantity);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal ($items items)',
            value: '\$${subtotal.toStringAsFixed(2)}',
          ),
          SizedBox(height: 4.h),
          _SummaryRow(
            label: 'Delivery fee',
            value: subtotal > 0 ? '\$5.00' : '\$0.00',
          ),
          Divider(height: 16.h),
          _SummaryRow(
            label: 'Total',
            value: '\$${(subtotal + (subtotal > 0 ? 5 : 0)).toStringAsFixed(2)}',
            emphasise: true,
          ),
          SizedBox(height: 10.h),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: CustomText(
                  text: 'Order confirmed for $items items.',
                  fontSize: 12.sp,
                ),
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(44.h),
            ),
            child: CustomText(
              text: 'Confirm Order',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// A label and amount line in the summary.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: emphasise ? 14.sp : 12.sp,
          fontWeight: emphasise ? FontWeight.bold : FontWeight.normal,
          color: emphasise ? null : scheme.onSurfaceVariant,
        ),
        CustomText(
          text: value,
          fontSize: emphasise ? 15.sp : 12.sp,
          fontWeight: emphasise ? FontWeight.bold : FontWeight.w600,
          color: emphasise ? scheme.primary : null,
        ),
      ],
    );
  }
}

// Shown when the user has no cart or removed every row.
class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56.sp, color: muted),
            SizedBox(height: 12.h),
            CustomText(
              text: message,
              fontSize: 13.sp,
              color: muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
