import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// utils
import '../utils/login_type.dart';
import '../utils/validators.dart';

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

  // ENHANCEMENT 2: which backend the Log In button talks to.
  LoginType _backend = LoginType.dummyJson;

  bool get _isFirebase => _backend == LoginType.firebase;

  // Swaps the backend and the credentials that go with it.
  void _switchBackend(LoginType backend) {
    setState(() {
      _backend = backend;
      _usernameController.text = _isFirebase ? '' : 'emilys';
      _passwordController.text = _isFirebase ? '' : 'emilyspass';
    });
  }

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
      if (_isFirebase) {
        await userService.signIn(
          email: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // loginUser already saves the user, so there is no second save here.
        await userService.loginUser(
          _usernameController.text,
          _passwordController.text,
        );
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: 'Login failed: ${_message(e)}',
            fontSize: 12.sp,
          ),
        ),
      );
    }
  }

  // Strips the bracketed error code Firebase puts in front of its messages.
  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^\[[^\]]*\]\s*|^Exception:\s*'),
    '',
  );

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
                  SizedBox(height: 20.h),

                  // ENHANCEMENT 2: the same screen drives either backend.
                  SegmentedButton<LoginType>(
                    segments: [
                      ButtonSegment(
                        value: LoginType.dummyJson,
                        label: CustomText(text: 'DummyJSON', fontSize: 11.sp),
                        icon: Icon(Icons.cloud_outlined, size: 16.sp),
                      ),
                      ButtonSegment(
                        value: LoginType.firebase,
                        label: CustomText(text: 'Firebase', fontSize: 11.sp),
                        icon: Icon(
                          Icons.local_fire_department_outlined,
                          size: 16.sp,
                        ),
                      ),
                    ],
                    selected: {_backend},
                    onSelectionChanged: (selection) =>
                        _switchBackend(selection.first),
                  ),
                  SizedBox(height: 20.h),

                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: _isFirebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: _isFirebase ? 'Email address' : 'Username',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(
                        _isFirebase ? Icons.mail_outline : Icons.person_outline,
                        size: 20.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) => _isFirebase
                        ? validateEmail(value)
                        : validateRequired(value, 'username'),
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

                  // Only Firebase lets the app create accounts of its own.
                  if (_isFirebase)
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/signup'),
                      child: CustomText(
                        text: 'Create an account',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
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
