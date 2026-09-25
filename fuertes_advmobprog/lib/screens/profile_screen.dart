import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/user.dart';

// services
import '../services/user_service.dart';

// utils
import '../utils/login_type.dart';
import '../utils/validators.dart';

// widgets
import '../widgets/custom_text.dart';

// ENHANCEMENT 3: the Profile tab, rendered from whichever backend signed in.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  late User _user = widget.user;

  LoginType _loginType = LoginType.dummyJson;

  bool get _isFirebase => _loginType == LoginType.firebase;

  @override
  void initState() {
    super.initState();
    _loadLoginType();
  }

  // The backend decides which details and which actions are on offer.
  Future<void> _loadLoginType() async {
    final loginType = await readLoginType();
    if (!mounted) return;
    setState(() => _loginType = loginType);
  }

  // Pulls the profile again after an edit so the card matches the account.
  Future<void> _refresh() async {
    final user = await _userService.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  // Clears the session and goes back to sign-in.
  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  // Runs an account action, reporting whichever way it went.
  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      _show(done);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _show(e.toString().replaceFirst(RegExp(r'^\[[^\]]*\]\s*'), ''));
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: CustomText(text: message, fontSize: 12.sp)),
    );
  }

  // Asks for a new username and saves it.
  Future<void> _updateUsername() async {
    final controller = TextEditingController(text: _user.username);

    final username = await _prompt(
      title: 'Update username',
      fields: [
        _PromptField(
          controller: controller,
          label: 'Username',
          validator: (v) => validateRequired(v, 'username'),
        ),
      ],
    );

    if (username == null) return;
    await _run(
      () => _userService.updateUsername(username: controller.text.trim()),
      'Username updated',
    );
  }

  // Asks for the current and new password, then swaps them over.
  Future<void> _changePassword() async {
    final current = TextEditingController();
    final replacement = TextEditingController();

    final confirmed = await _prompt(
      title: 'Change password',
      fields: [
        _PromptField(
          controller: current,
          label: 'Current password',
          obscure: true,
          validator: (v) => validateRequired(v, 'current password'),
        ),
        _PromptField(
          controller: replacement,
          label: 'New password',
          obscure: true,
          validator: validatePassword,
        ),
      ],
    );

    if (confirmed == null) return;
    await _run(
      () => _userService.resetPasswordFromCurrentPassword(
        currentPassword: current.text,
        newPassword: replacement.text,
        email: _user.email,
      ),
      'Password changed',
    );
  }

  // Asks for the password one last time, then deletes the account for good.
  Future<void> _deleteAccount() async {
    final password = TextEditingController();

    final confirmed = await _prompt(
      title: 'Delete account',
      message: 'This removes the account and its profile permanently.',
      confirmLabel: 'Delete',
      destructive: true,
      fields: [
        _PromptField(
          controller: password,
          label: 'Password',
          obscure: true,
          validator: (v) => validateRequired(v, 'password'),
        ),
      ],
    );

    if (confirmed == null) return;

    try {
      await _userService.deleteAccount(
        email: _user.email,
        password: password.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _show(e.toString().replaceFirst(RegExp(r'^\[[^\]]*\]\s*'), ''));
    }
  }

  // One dialog shape for all three account actions.
  Future<bool?> _prompt({
    required String title,
    required List<_PromptField> fields,
    String? message,
    String confirmLabel = 'Save',
    bool destructive = false,
  }) {
    final formKey = GlobalKey<FormState>();
    final scheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(
          text: title,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message != null) ...[
                CustomText(
                  text: message,
                  fontSize: 12.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(height: 12.h),
              ],
              for (final field in fields)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: TextFormField(
                    controller: field.controller,
                    obscureText: field.obscure,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: field.label,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: field.validator,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText(text: 'Cancel', fontSize: 13.sp),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            child: CustomText(
              text: confirmLabel,
              fontSize: 13.sp,
              color: destructive ? scheme.onError : scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44.r,
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundImage: _user.image.isEmpty
                        ? null
                        : NetworkImage(_user.image),
                    child: Icon(
                      Icons.person,
                      size: 40.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  CustomText(
                    text: _user.fullName.isEmpty
                        ? _user.username
                        : _user.fullName,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: '@${_user.username}',
                    fontSize: 12.sp,
                    color: scheme.primary,
                  ),
                  SizedBox(height: 10.h),
                  // Says out loud which backend this profile came from.
                  Chip(
                    avatar: Icon(
                      _isFirebase
                          ? Icons.local_fire_department_outlined
                          : Icons.cloud_outlined,
                      size: 15.sp,
                    ),
                    label: CustomText(
                      text: _isFirebase
                          ? 'Firebase account'
                          : 'DummyJSON account',
                      fontSize: 10.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: _user.email,
                  ),
                  // The rows below hide themselves when the value is empty,
                  // so each backend shows only the fields it actually has.
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Gender',
                    value: _user.gender,
                  ),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: _user.age == 0 ? '' : '${_user.age}',
                  ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: _user.contactNo,
                  ),
                  _InfoRow(
                    icon: Icons.card_membership_outlined,
                    label: 'User ID',
                    value: _isFirebase ? _user.uid : '#${_user.id}',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // ENHANCEMENT 3: only a Firebase account can edit itself.
          if (_isFirebase) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit_outlined, size: 22.sp),
                    title: CustomText(text: 'Update username', fontSize: 14.sp),
                    onTap: _updateUsername,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.password_outlined, size: 22.sp),
                    title: CustomText(text: 'Change password', fontSize: 14.sp),
                    onTap: _changePassword,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      size: 22.sp,
                      color: scheme.error,
                    ),
                    title: CustomText(
                      text: 'Delete account',
                      fontSize: 14.sp,
                      color: scheme.error,
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          FilledButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout, size: 18.sp),
            label: CustomText(
              text: 'Log Out',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onError,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: Size.fromHeight(46.h),
            ),
          ),
        ],
      ),
    );
  }
}

// One text box inside an account-action dialog.
class _PromptField {
  _PromptField({
    required this.controller,
    required this.label,
    required this.validator,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final bool obscure;
}

// One labelled detail line on the profile card.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: scheme.primary),
          SizedBox(width: 10.w),
          CustomText(
            text: label,
            fontSize: 12.sp,
            color: scheme.onSurfaceVariant,
          ),
          const Spacer(),
          Flexible(
            child: CustomText(
              text: value,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
