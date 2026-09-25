import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Shell screen that holds the bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  // ENHANCEMENT 3: the saved user drives the profile and the cart.
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Reads back whoever the splash or sign-in screen saved.
  Future<void> _loadUser() async {
    final user = await UserService().getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
    });
  }

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
                          ? (_user?.firstName.isNotEmpty ?? false)
                                ? _user!.firstName
                                : 'Profile'
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
        body: (_user == null)
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _selectedIndex = page;
                  });
                },
                children: [
                  const ProductScreen(),
                  // ENHANCEMENT 3: the cart of whoever signed in. A Firebase
                  // account has no dummyJSON id, and /carts/user/0 is a 404,
                  // so it falls back to the sample cart.
                  CartScreen(
                    userId: _user!.id == 0 ? defaultUserId : _user!.id,
                  ),
                  ProfileScreen(user: _user!),
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

  // The chat button now opens the chat list. Only a Firebase account has a
  // uid to send messages from, so a dummyJSON session is turned away here.
  void _openChat() {
    if (_user!.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: 'Sign in with a Firebase account to use the chat.',
            fontSize: 12.sp,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
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
