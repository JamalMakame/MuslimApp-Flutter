import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../theme/app_theme.dart';

/// The floating 4-slot pill nav from the Stitch design —
/// Home · Quran · Azkar · Settings. Rendered as a Scaffold
/// bottomNavigationBar so it floats over content.
class FloatingNavPill extends StatelessWidget {
  const FloatingNavPill({super.key, required this.active});

  /// 'home' | 'quran' | 'azkar' | 'settings'
  final String active;

  static const _items = [
    ('home', Icons.mosque_outlined, Routes.home, 'navHome'),
    ('quran', Icons.menu_book_outlined, Routes.quran, 'navQuran'),
    ('azkar', Icons.fingerprint, Routes.azkar, 'navAzkar'),
    ('settings', Icons.tune, Routes.settings, 'navSettings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0A4A3F),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (key, icon, route, label) in _items)
              _NavItem(
                icon: icon,
                label: label.tr,
                selected: key == active,
                onTap: () {
                  if (key == active) return;
                  Get.offAllNamed(route);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : AppColors.sage,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.body(
                  12,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
