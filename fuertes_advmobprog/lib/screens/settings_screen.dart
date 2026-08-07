import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// providers
import '../providers/theme_provider.dart';

// widgets
import '../widgets/custom_text.dart';

// ENHANCEMENT 3: settings page that holds the dark/light mode switch.
// Stateless because the switch value comes from ThemeProvider, not from a
// field in this widget.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          CustomText(
            text: 'Appearance',
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
          SizedBox(height: 8.h),
          Card(
            child: SwitchListTile(
              title: CustomText(
                text: 'Dark Mode',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              subtitle: CustomText(
                text: themeProvider.isDark
                    ? 'Dark theme is on'
                    : 'Light theme is on',
                fontSize: 11.sp,
                color: scheme.onSurfaceVariant,
              ),
              secondary: Icon(
                themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                size: 22.sp,
              ),
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          SizedBox(height: 20.h),
          CustomText(
            text: 'About',
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
          SizedBox(height: 8.h),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.storefront, size: 22.sp),
                  title: CustomText(text: 'Demi Mart', fontSize: 14.sp),
                  subtitle: CustomText(
                    text: 'Lab Activity 2 - API',
                    fontSize: 11.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.person_outline, size: 22.sp),
                  title: CustomText(text: 'Jorge Fuertes', fontSize: 14.sp),
                  subtitle: CustomText(
                    text: 'INF231',
                    fontSize: 11.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
