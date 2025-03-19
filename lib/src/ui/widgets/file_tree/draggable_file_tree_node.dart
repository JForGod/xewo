import 'package:flutter/material.dart';
import '../../../state/models/file_node.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../themes/app_theme.dart';

/// 支持拖放操作的文件树节点组件
class DraggableFileTreeNode extends StatefulWidget {
  final FileNode node;
  final int level;
  final bool isExpanded;
  final bool isSelected;
  final Function(FileNode) onNodeTap;
  final Function(FileNode, Offset) onNodeRightClick;
  final Function(FileNode, FileNode) onNodeDrop;

  const DraggableFileTreeNode({
    Key? key,
    required this.node,
    required this.level,
    required this.isExpanded,
    required this.isSelected,
    required this.onNodeTap,
    required this.onNodeRightClick,
    required this.onNodeDrop,
  }) : super(key: key);

  @override
  State<DraggableFileTreeNode> createState() => _DraggableFileTreeNodeState();
}

class _DraggableFileTreeNodeState extends State<DraggableFileTreeNode> with SingleTickerProviderStateMixin {
  bool _isDragTarget = false;
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: DragTarget<FileNode>(
        onWillAccept: (data) {
          if (data == null) return false;
          // 不允许拖拽到自身或子目录
          if (data == widget.node || 
              widget.node.path.startsWith('${data.path}/')) {
            return false;
          }
          // 只允许拖拽到目录
          return widget.node.type == FileNodeType.directory;
        },
        onAccept: (data) {
          widget.onNodeDrop(data, widget.node);
          setState(() => _isDragTarget = false);
        },
        onLeave: (_) {
          setState(() => _isDragTarget = false);
        },
        onMove: (_) {
          if (!_isDragTarget) {
            setState(() => _isDragTarget = true);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: Draggable<FileNode>(
              data: widget.node,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: _buildDragFeedback(context),
              child: _buildNodeContent(context),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: _buildNodeContent(context),
              ),
              onDragStarted: () {
                HapticFeedback.lightImpact();
              },
              onDragEnd: (_) {
                HapticFeedback.mediumImpact();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragFeedback(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.node.type == FileNodeType.directory
                  ? Icons.folder
                  : _getFileIcon(),
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              widget.node.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeContent(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onNodeTap(widget.node),
      onSecondaryTapDown: (details) => 
          widget.onNodeRightClick(widget.node, details.globalPosition),
      child: Container(
        height: 32,
        padding: EdgeInsets.only(left: widget.level * 16.0),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          border: _isDragTarget
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (widget.node.type == FileNodeType.directory)
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: widget.isExpanded ? 0.25 : 0,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              widget.node.type == FileNodeType.directory
                  ? widget.isExpanded ? Icons.folder_open : Icons.folder
                  : _getFileIcon(),
              size: 20,
              color: _getIconColor(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.node.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isHovered || widget.isSelected)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onPressed: () => widget.onNodeRightClick(
                      widget.node,
                      Offset.zero, // 这里需要计算正确的位置
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (_isDragTarget) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.15);
    }
    if (widget.isSelected) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
    if (_isHovered) {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.05);
    }
    return Colors.transparent;
  }

  Color _getIconColor(BuildContext context) {
    if (widget.node.type == FileNodeType.directory) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  IconData _getFileIcon() {
    final extension = widget.node.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return Icons.code;
      case 'json':
        return Icons.data_object;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      case 'md':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
} 