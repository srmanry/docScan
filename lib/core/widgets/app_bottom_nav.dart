import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:doc_sense/core/theme/app_theme.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const AppBottomNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Floating pill-style bottom nav from the Figma design: a rounded card
/// riding above the screen edge, with the active tab rendered as a filled
/// orange pill and inactive tabs as plain icon-over-label. The bar is
/// frosted — the page scrolls under it through a blur (the shell sets
/// extendBody so there is something to blur).
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppBottomNavItem> items;

  const AppBottomNav({super.key, required this.selectedIndex, required this.onDestinationSelected, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                // Thin at the top so whatever scrolls under shows through,
                // denser at the bottom to keep the labels readable.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.warmWhite.withValues(alpha: 0.22),
                    AppColors.warmWhite.withValues(alpha: 0.45),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavItem(item: items[i], selected: i == selectedIndex, onTap: () => onDestinationSelected(i)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      //borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: selected ? AppColors.buntOrange : Colors.transparent, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? Colors.white : AppColors.ink.withValues(alpha: 0.45),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: selected ? AppColors.buntOrange : AppColors.ink.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
