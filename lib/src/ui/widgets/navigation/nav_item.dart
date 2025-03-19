import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';
import '../../../providers/navigation_provider.dart';

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
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
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
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
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