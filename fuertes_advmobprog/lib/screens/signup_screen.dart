import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/user.dart';

// services
import '../services/user_service.dart';

// utils
import '../utils/validators.dart';

// widgets
import '../widgets/custom_text.dart';

// ENHANCEMENT 2: sign-up form, backed by Firebase instead of the dummyJSON API.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _age = TextEditingController();
  final _contactNo = TextEditingController();
  final _username = TextEditingController();
  final _emailAddress = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final controller in [
      _fName,
      _lName,
      _age,
      _contactNo,
      _username,
      _emailAddress,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // Creates the account, then stores the fields Auth cannot hold.
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final service = UserService();

    try {
      await service.createAccount(
        email: _emailAddress.text.trim(),
        password: _password.text,
      );

      // The profile document has to exist before updateUsername edits it.
      await service.saveUserProfile(
        User(
          id: 0,
          username: _username.text.trim(),
          email: _emailAddress.text.trim(),
          firstName: _fName.text.trim(),
          lastName: _lName.text.trim(),
          gender: '',
          image: '',
          accessToken: '',
          refreshToken: '',
          age: int.parse(_age.text.trim()),
          contactNo: _contactNo.text.trim(),
        ),
      );
      await service.updateUsername(username: _username.text.trim());

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: 'Sign up failed: ${_message(e)}',
            fontSize: 12.sp,
          ),
        ),
      );
    }
  }

  // Firebase errors carry a readable message; anything else gets its text.
  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^\[[^\]]*\]\s*|^Exception:\s*'), '');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Create account',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  text: 'Your Firebase account',
                  fontSize: 12.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: 16.h),
                _Field(
                  controller: _fName,
                  label: 'First name',
                  icon: Icons.person_outline,
                  validator: (v) => validateRequired(v, 'first name'),
                ),
                _Field(
                  controller: _lName,
                  label: 'Last name',
                  icon: Icons.person_outline,
                  validator: (v) => validateRequired(v, 'last name'),
                ),
                _Field(
                  controller: _age,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: validateAge,
                ),
                _Field(
                  controller: _contactNo,
                  label: 'Contact number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: validateContactNo,
                ),
                _Field(
                  controller: _username,
                  label: 'Username',
                  icon: Icons.alternate_email,
                  validator: (v) => validateRequired(v, 'username'),
                ),
                _Field(
                  controller: _emailAddress,
                  label: 'Email address',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                _Field(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  validator: validatePassword,
                ),
                _Field(
                  controller: _confirmPassword,
                  label: 'Confirm password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  validator: (v) => validateConfirmPassword(v, _password.text),
                ),
                SizedBox(height: 10.h),
                FilledButton(
                  onPressed: _isLoading ? null : _signUp,
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
                          text: 'Sign Up',
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
    );
  }
}

// One field of the sign-up form, so the eight of them stay readable.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.formatters,
    this.obscure = false,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        obscureText: obscure,
        textInputAction: TextInputAction.next,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13.sp),
          prefixIcon: Icon(icon, size: 20.sp),
          suffixIcon: onToggleObscure == null
              ? null
              : IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20.sp,
                  ),
                  tooltip: obscure ? 'Show password' : 'Hide password',
                  onPressed: onToggleObscure,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
