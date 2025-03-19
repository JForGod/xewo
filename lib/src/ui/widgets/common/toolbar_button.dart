import 'package:flutter/material.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
} 