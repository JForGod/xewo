import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../services/file/file_service.dart';
import '../../../state/models/file_node.dart';
import '../../themes/app_theme.dart';

/// 文件树节点组件
class FileTreeNodeWidget extends StatelessWidget {
  final FileNode node;
  final int depth;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onExpand;
  final Function(String)? onDragCompleted;
  final bool isDraggable;
  final bool isDropTarget;
  final Function(DragTargetDetails<FileNode>)? onAcceptDrop;
  final Function(DragUpdateDetails)? onDragUpdate;
  final Function(Offset) onRightClick;

  const FileTreeNodeWidget({
    Key? key,
    required this.node,
    required this.depth,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.onDoubleTap,
    this.onExpand,
    this.onDragCompleted,
    this.isDraggable = true,
    this.isDropTarget = true,
    this.onAcceptDrop,
    this.onDragUpdate,
    required this.onRightClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDirectory = node.type == FileNodeType.directory;
    final icon = _getFileIcon(node.name, isDirectory);
    final backgroundColor = isSelected 
        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
        : Colors.transparent;
    
    Widget nodeContent = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onSecondaryTapDown: (details) => onRightClick(details.globalPosition),
        borderRadius: BorderRadius.circular(4),
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Container(
          height: 24,
          padding: EdgeInsets.only(left: 4.0, right: 4.0),
          margin: EdgeInsets.only(left: depth * 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDirectory) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Center(
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(width: 16),
              ],
              SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                color: _getIconColor(context, node.name),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  node.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    
    // 如果是可拖拽的，包装为Draggable
    if (isDraggable) {
      nodeContent = MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Draggable<FileNode>(
          data: node,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: _getIconColor(context, node.name),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    node.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: nodeContent,
          ),
          onDragStarted: () {
            // 添加震动反馈
            HapticFeedback.selectionClick();
          },
          onDragCompleted: () {
            if (onDragCompleted != null) {
              onDragCompleted!(node.path);
            }
            // 添加震动反馈
            HapticFeedback.heavyImpact();
          },
          onDraggableCanceled: (_, __) {
            // 添加震动反馈
            HapticFeedback.selectionClick();
          },
          child: nodeContent,
        ),
      );
    }
    
    // 如果是可接收拖放的，包装为DragTarget
    if (isDirectory && isDropTarget) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isHovering = false;

          return DragTarget<FileNode>(
            onAccept: (data) {
              if (onAcceptDrop != null) {
                onAcceptDrop!(DragTargetDetails<FileNode>(
                  data: data,
                  offset: Offset.zero,
                ));
              }
              setState(() => isHovering = false);
              // 添加震动反馈
              HapticFeedback.heavyImpact();
            },
            onWillAccept: (data) {
              // 不允许将目录拖入自身或其子目录
              if (data == null) return false;
              if (data.path == node.path) return false;
              if (data.path.startsWith('${node.path}/')) return false;
              setState(() => isHovering = true);
              // 添加震动反馈
              HapticFeedback.selectionClick();
              return true;
            },
            onLeave: (_) {
              setState(() => isHovering = false);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  border: isHovering
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(4),
                  color: isHovering
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                      : Colors.transparent,
                ),
                child: nodeContent,
              );
            },
          );
        },
      );
    }
    
    // 普通节点
    return nodeContent;
  }
  
  /// 获取文件图标
  IconData _getFileIcon(String fileName, bool isDirectory) {
    if (isDirectory) {
      return isExpanded ? Icons.folder_open : Icons.folder;
    }
    
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.dart':
        return Icons.code;
      case '.json':
      case '.yaml':
      case '.yml':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Icons.image;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.mp3':
      case '.wav':
      case '.ogg':
        return Icons.audio_file;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Icons.video_file;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive;
      case '.exe':
      case '.bat':
      case '.sh':
        return Icons.terminal;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  /// 获取图标颜色
  Color _getIconColor(BuildContext context, String fileName) {
    if (node.type == FileNodeType.directory) {
      return Colors.amber;
    }
    
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.dart':
        return Colors.blue;
      case '.json':
      case '.yaml':
      case '.yml':
        return Colors.green;
      case '.md':
        return Colors.purple;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Colors.pink;
      case '.pdf':
        return Colors.red;
      case '.mp3':
      case '.wav':
      case '.ogg':
        return Colors.orange;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Colors.indigo;
      case '.zip':
      case '.rar':
      case '.7z':
        return Colors.brown;
      case '.exe':
      case '.bat':
      case '.sh':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
} 