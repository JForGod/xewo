import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: theme.colorScheme.surface,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.code),
          label: '编辑器',
        ),
        NavigationDestination(
          icon: Icon(Icons.build),
          label: '工具箱',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: '设置',
        ),
      ],
    );
  }
} 