import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';

import '../widgets/custom_text.dart';

// Shell screen that holds the bottom navigation bar. The selected tab is
// ephemeral state, so setState is enough here.
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Index of the visible tab.
  int _selectedIndex = 0;

  // Keeps the bar and the shown page in sync.
  final PageController _pageController = PageController();

  // Release the controller so it does not leak.
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Root page, so the back gesture should not pop it off the stack.
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          // Wordmark on the Shop tab, a plain title on the others.
          title: (_selectedIndex == 0)
              ? Image.asset(
                  'assets/images/demimart_logo.png',
                  height: 26.sp,
                )
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'Chat'
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
          // Swiping off so the bottom bar is the only way to change tabs.
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
          children: const [
            ProductScreen(),
            _PlaceholderTab(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              message: 'Messages with sellers will appear here.',
            ),
            _PlaceholderTab(
              icon: Icons.person_outline,
              label: 'Profile',
              message: 'Account details will appear here.',
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false, // selected item
          showUnselectedLabels: false, // unselected item
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  // Highlights the tapped icon and jumps to the matching page.
  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}

// Placeholder for the tabs that are not part of this activity, so every
// destination still leads somewhere.
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
