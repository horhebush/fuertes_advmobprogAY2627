import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';

import '../widgets/custom_text.dart';

/// The shell screen that hosts the bottom navigation bar.
///
/// It owns which tab is selected - ephemeral state, so `setState` is the right
/// tool here rather than a provider (the lesson carried over from Lab Activity 1).
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Index of the visible tab. Ephemeral state local to this shell.
  int _selectedIndex = 0;

  /// Drives the PageView so tapping the bar and the page shown stay in sync.
  final PageController _pageController = PageController();

  /// Releases the controller when the screen is destroyed, preventing a leak.
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // This is the root page, so the system back gesture should not pop it
      // off the stack and leave the user on a black screen.
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          // The store wordmark identifies the Shop tab; the other tabs get a
          // plain text title instead.
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
            // ENHANCEMENT 3 - entry point to the settings page that holds the
            // dark/light switch.
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          // Swiping is disabled so the bottom bar is the only way to change
          // tabs, which keeps _selectedIndex authoritative.
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

  /// Handles a tap on the bottom navigation bar.
  ///
  /// Updates the highlighted icon and jumps the PageView to the matching page.
  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}

/// A simple empty-state page used for the tabs that are not part of this
/// activity, so every bottom-bar destination leads somewhere valid.
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
