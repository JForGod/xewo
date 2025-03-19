import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fileTreeWidthProvider = StateProvider<double>((ref) => 240);
final fileTreeCollapsedProvider = StateProvider<bool>((ref) => false);

class CollapsibleFileTree extends ConsumerWidget {
  final Widget child;
  
  const CollapsibleFileTree({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(fileTreeCollapsedProvider);
    final width = ref.watch(fileTreeWidthProvider);
    
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isCollapsed ? 0 : width,
          child: child,
        ),
        Positioned(
          top: 0,
          right: -12,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (!isCollapsed) {
                  final newWidth = width + details.delta.dx;
                  if (newWidth >= 160 && newWidth <= 400) {
                    ref.read(fileTreeWidthProvider.notifier).state = newWidth;
                  }
                }
              },
              child: Container(
                width: 12,
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: isCollapsed ? 4 : -28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              elevation: 2,
              child: InkWell(
                onTap: () {
                  ref.read(fileTreeCollapsedProvider.notifier).state = !isCollapsed;
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: Icon(
                    isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 