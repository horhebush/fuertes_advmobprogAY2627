import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'product_screen.dart';

import '../widgets/custom_text.dart';

// Shell screen that holds the bottom navigation bar.
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: (_selectedIndex == 0)
              ? Image.asset(
                  'assets/images/demimart_logo.png',
                  height: 26.sp,
                )
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'Cart'
                      : (_selectedIndex == 2)
                          ? 'Profile'
                          : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
          actions: [
            // ENHANCEMENT 3: opens the settings page with the theme switch.
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
          children: const [
            ProductScreen(),
            // ENHANCEMENT 1: the cart replaces the old Chat tab.
            CartScreen(),
            _PlaceholderTab(
              icon: Icons.person_outline,
              label: 'Profile',
              message: 'Account details will appear here.',
            ),
          ],
        ),
        // ENHANCEMENT 2: Chat left the bottom bar and became this button,
        // which is hidden while the cart is on screen.
        floatingActionButton: (_selectedIndex == 1)
            ? null
            : FloatingActionButton(
                onPressed: _openChat,
                tooltip: 'Chat',
                child: Icon(Icons.chat, size: 24.sp),
              ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false, // selected item
          showUnselectedLabels: false, // unselected item
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            // ENHANCEMENT 2: Cart took the slot Chat used to hold.
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  // ENHANCEMENT 2: what the chat button does for now.
  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
          text: 'Messages with sellers will appear here.',
          fontSize: 12.sp,
        ),
      ),
    );
  }

  // Changes the selected tab.
  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}

// Placeholder page for the tabs outside this activity.
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.label,
    required this.message,
  });

  final IconData icon;
  final String label;
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
            Icon(icon, size: 56.sp, color: muted),
            SizedBox(height: 12.h),
            CustomText(
              text: label,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 6.h),
            CustomText(
              text: message,
              fontSize: 12.sp,
              color: muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
