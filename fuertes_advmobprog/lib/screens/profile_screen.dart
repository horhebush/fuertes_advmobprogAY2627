import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/user.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ENHANCEMENT 3: the Profile tab, rendered from the saved user.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  // Clears the saved user and goes back to sign-in.
  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
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
                    foregroundImage: user.image.isEmpty
                        ? null
                        : NetworkImage(user.image),
                    child: Icon(
                      Icons.person,
                      size: 40.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  CustomText(
                    text: user.fullName.isEmpty ? user.username : user.fullName,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: '@${user.username}',
                    fontSize: 12.sp,
                    color: scheme.primary,
                  ),
                  SizedBox(height: 20.h),
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: user.email,
                  ),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Gender',
                    value: user.gender,
                  ),
                  _InfoRow(
                    icon: Icons.card_membership_outlined,
                    label: 'User ID',
                    value: '#${user.id}',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          FilledButton.icon(
            onPressed: () => _logout(context),
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
