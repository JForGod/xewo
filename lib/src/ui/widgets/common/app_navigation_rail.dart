import 'package:flutter/material.dart';

class AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  
  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: theme.colorScheme.surface,
      selectedIconTheme: IconThemeData(
        color: theme.colorScheme.primary,
      ),
      unselectedIconTheme: IconThemeData(
        color: theme.colorScheme.onSurface,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.code),
          label: Text('编辑器'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.build),
          label: Text('工具箱'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
    );
  }
} 