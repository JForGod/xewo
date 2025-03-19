import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolbarVisibilityProvider = StateProvider<bool>((ref) => false);

class FloatingToolbar extends ConsumerWidget {
  final VoidCallback onFormat;
  final VoidCallback onFind;
  final VoidCallback onReplace;
  final VoidCallback onToggleLineNumbers;
  final VoidCallback onToggleMinimap;
  final VoidCallback onToggleFileTree;
  final bool showFileTree;
  
  const FloatingToolbar({
    Key? key,
    required this.onFormat,
    required this.onFind,
    required this.onReplace,
    required this.onToggleLineNumbers,
    required this.onToggleMinimap,
    required this.onToggleFileTree,
    this.showFileTree = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(toolbarVisibilityProvider);
    
    return MouseRegion(
      onEnter: (_) => ref.read(toolbarVisibilityProvider.notifier).state = true,
      onExit: (_) => ref.read(toolbarVisibilityProvider.notifier).state = false,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarButton(
                  context,
                  customIcon: Image.asset(
                    showFileTree 
                      ? 'assets/icons/file_tree_.png' 
                      : 'assets/icons/file_tree_hidden.png',
                    width: 14,
                    height: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  tooltip: showFileTree ? '隐藏文件树' : '显示文件树',
                  onPressed: onToggleFileTree,
                  size: 24,
                  padding: 4,
                ),
                
                Container(
                  width: 1,
                  height: 16,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: 2),
                
                IconButton(
                  icon: const Icon(Icons.format_align_left, size: 14),
                  tooltip: '格式化代码',
                  onPressed: onFormat,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.search, size: 14),
                  tooltip: '查找',
                  onPressed: onFind,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.find_replace, size: 14),
                  tooltip: '替换',
                  onPressed: onReplace,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 2),
                Container(
                  width: 1,
                  height: 16,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: 2),
                _buildToolbarButton(
                  context,
                  icon: Icons.format_list_numbered,
                  tooltip: '显示/隐藏行号',
                  onPressed: onToggleLineNumbers,
                  size: 24,
                  iconSize: 14,
                  padding: 4,
                ),
                _buildToolbarButton(
                  context,
                  icon: Icons.map,
                  tooltip: '显示/隐藏小地图',
                  onPressed: onToggleMinimap,
                  size: 24,
                  iconSize: 14,
                  padding: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildToolbarButton(
    BuildContext context, {
    IconData? icon,
    Widget? customIcon,
    required String tooltip,
    required VoidCallback onPressed,
    double size = 28,
    double iconSize = 16,
    double padding = 6,
  }) {
    assert(icon != null || customIcon != null, '必须提供icon或customIcon');
    
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: customIcon ?? Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
} 