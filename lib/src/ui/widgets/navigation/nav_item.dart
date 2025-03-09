import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/main_screen.dart';
import '../../themes/app_theme.dart';

class NavItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String id;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNavItem = ref.watch(selectedNavItemProvider);
    final isSelected = selectedNavItem == id;
    
    return InkWell(
      onTap: () {
        ref.read(selectedNavItemProvider.notifier).state = id;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary50 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary600 : AppTheme.neutral600,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary600 : AppTheme.neutral600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 