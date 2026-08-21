import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ENHANCEMENT 2: the sign-in screen, backed by UserService.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  // The API only accepts its own accounts, so start on a working one.
  final TextEditingController _usernameController = TextEditingController(
    text: 'emilys',
  );

  final TextEditingController _passwordController = TextEditingController(
    text: 'emilyspass',
  );

  bool _isLoading = false;

  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Logs in, then hands the response to the home screen.
  void _login() async {
    UserService userService = UserService();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // loginUser already saves the user, so there is no second save here.
      final response = await userService.loginUser(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacementNamed(context, '/home', arguments: response);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: 'Login failed: ${e.toString().replaceFirst('Exception: ', '')}',
            fontSize: 12.sp,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/demimart_logo.png',
                    height: 44.sp,
                  ),
                  SizedBox(height: 28.h),
                  CustomText(
                    text: 'Welcome back',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: 'Sign in to see your cart.',
                    fontSize: 12.sp,
                    color: scheme.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28.h),

                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(Icons.person_outline, size: 20.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Enter your username'
                        : null,
                  ),
                  SizedBox(height: 14.h),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(Icons.lock_outline, size: 20.sp),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20.sp,
                        ),
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Enter your password'
                        : null,
                  ),
                  SizedBox(height: 24.h),

                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(48.h),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 18.sp,
                            height: 18.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : CustomText(
                            text: 'Log In',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimary,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
