import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../themes/app_theme.dart';
import 'version_control_indicator.dart';

/// 支持拖放操作的文件树节点组件
class DraggableFileTreeNode extends StatelessWidget {
  final FileNode node;
  final int level;
  final bool isExpanded;
  final bool isSelected;
  final bool isMultiSelected; // 是否在多选中被选中
  final bool isMultiSelectMode; // 是否处于多选模式
  final Function(FileNode) onNodeTap;
  final Function(FileNode, RawKeyEvent, bool) onNodeKeyDown; // 添加键盘事件处理
  final Function(FileNode, Offset) onNodeRightClick;
  final Function(FileNode, FileNode) onNodeDrop;

  const DraggableFileTreeNode({
    Key? key,
    required this.node,
    required this.level,
    required this.isExpanded,
    required this.isSelected,
    this.isMultiSelected = false,
    this.isMultiSelectMode = false,
    required this.onNodeTap,
    required this.onNodeKeyDown,
    required this.onNodeRightClick,
    required this.onNodeDrop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点本身（可拖动）
        LongPressDraggable<FileNode>(
          data: node,
          feedback: Material(
            elevation: 4.0,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              color: Theme.of(context).highlightColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForNode(node),
                    size: 18,
                    color: _getColorForNode(context, node),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    node.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildNodeContent(context),
          ),
          onDragStarted: () {
            // 拖动开始时的处理
          },
          child: DragTarget<FileNode>(
            builder: (context, candidateData, rejectedData) {
              return _buildNodeContent(
                context,
                isDropTarget: candidateData.isNotEmpty,
              );
            },
            onWillAccept: (data) {
              // 不接受拖放到自身
              if (data == node) return false;
              
              // 不接受拖放到非目录
              if (!node.isDirectory) return false;
              
              // 不接受拖放到子目录（防止循环）
              if (data!.isDirectory && node.path.startsWith(data.path)) return false;
              
              return true;
            },
            onAccept: (data) {
              onNodeDrop(data, node);
            },
          ),
        ),
        
        // 子节点（如果是展开的文件夹）
        if (node.isDirectory && isExpanded && node.children.isNotEmpty)
          ...node.children.map((child) => DraggableFileTreeNode(
                node: child,
                level: level + 1,
                isExpanded: isExpanded && child.isDirectory,
                isSelected: isSelected && node.path == child.path,
                isMultiSelected: isMultiSelected && node.path == child.path,
                isMultiSelectMode: isMultiSelectMode,
                onNodeTap: onNodeTap,
                onNodeKeyDown: onNodeKeyDown,
                onNodeRightClick: onNodeRightClick,
                onNodeDrop: onNodeDrop,
              )),
      ],
    );
  }

  /// 构建节点内容
  Widget _buildNodeContent(BuildContext context, {bool isDropTarget = false}) {
    final theme = Theme.of(context);
    
    // 计算左边距
    final leftPadding = (level * 16.0) + 8.0;
    
    return GestureDetector(
      onTap: () => onNodeTap(node),
      onSecondaryTapDown: (details) => onNodeRightClick(node, details.globalPosition),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is RawKeyDownEvent) {
            onNodeKeyDown(this.node, event, isMultiSelectMode);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          height: 24,
          decoration: BoxDecoration(
            color: _getNodeBackgroundColor(context),
            border: isDropTarget
                ? Border.all(color: theme.colorScheme.primary, width: 1)
                : null,
          ),
          padding: EdgeInsets.only(left: leftPadding),
          child: Row(
            children: [
              // 展开/折叠图标（仅目录显示）
              if (node.isDirectory)
                Icon(
                  isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              if (!node.isDirectory) const SizedBox(width: 16),
              
              // 文件/文件夹图标
              Icon(
                _getIconForNode(node),
                size: 16,
                color: _getColorForNode(context, node),
              ),
              const SizedBox(width: 4),
              
              // 多选复选框
              if (isMultiSelectMode)
                Checkbox(
                  value: isMultiSelected,
                  onChanged: (value) => onNodeTap(node),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              
              // 文件/文件夹名称
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: isSelected || isMultiSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 版本控制状态指示器
              VersionControlIndicator(node: node, size: 14),
              
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取节点背景颜色
  Color _getNodeBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isMultiSelected) {
      return theme.colorScheme.primaryContainer;
    } else if (isSelected) {
      return theme.colorScheme.primary.withOpacity(0.2);
    } else {
      return Colors.transparent;
    }
  }

  /// 获取节点图标
  IconData _getIconForNode(FileNode node) {
    if (node.isDirectory) {
      return isExpanded ? Icons.folder_open : Icons.folder;
    } else {
      // 根据文件扩展名返回不同图标
      final extension = node.name.split('.').last.toLowerCase();
      switch (extension) {
        case 'dart':
          return Icons.code;
        case 'html':
          return Icons.html;
        case 'css':
          return Icons.css;
        case 'js':
        case 'ts':
          return Icons.javascript;
        case 'json':
          return Icons.data_object;
        case 'md':
          return Icons.description;
        case 'png':
        case 'jpg':
        case 'jpeg':
        case 'gif':
        case 'svg':
          return Icons.image;
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'zip':
        case 'rar':
        case '7z':
          return Icons.archive;
        case 'mp3':
        case 'wav':
        case 'ogg':
          return Icons.audio_file;
        case 'mp4':
        case 'avi':
        case 'mov':
          return Icons.video_file;
        default:
          return Icons.insert_drive_file;
      }
    }
  }

  /// 获取节点图标颜色
  Color _getColorForNode(BuildContext context, FileNode node) {
    final theme = Theme.of(context);
    
    if (node.isDirectory) {
      return Colors.amber;
    } else {
      // 根据文件扩展名返回不同颜色
      final extension = node.name.split('.').last.toLowerCase();
      switch (extension) {
        case 'dart':
          return Colors.blue;
        case 'html':
          return Colors.orange;
        case 'css':
          return Colors.purple;
        case 'js':
          return Colors.yellow.shade800;
        case 'ts':
          return Colors.blue.shade800;
        case 'json':
          return Colors.green;
        case 'md':
          return Colors.blueGrey;
        case 'png':
        case 'jpg':
        case 'jpeg':
        case 'gif':
        case 'svg':
          return Colors.pink;
        case 'pdf':
          return Colors.red;
        case 'zip':
        case 'rar':
        case '7z':
          return Colors.brown;
        case 'mp3':
        case 'wav':
        case 'ogg':
          return Colors.purple;
        case 'mp4':
        case 'avi':
        case 'mov':
          return Colors.red.shade800;
        default:
          return theme.colorScheme.onSurface.withOpacity(0.7);
      }
    }
  }
} 