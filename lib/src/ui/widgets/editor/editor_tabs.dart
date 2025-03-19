import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../../themes/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 编辑器标签组件
class EditorTabs extends ConsumerWidget {
  /// 打开的文件路径列表
  final List<String> files;
  
  /// 当前活动文件索引
  final int activeIndex;
  
  /// 标签选择回调
  final Function(int) onSelect;
  
  /// 标签关闭回调
  final Function(int) onClose;
  
  /// 构造函数
  const EditorTabs({
    Key? key,
    required this.files,
    required this.activeIndex,
    required this.onSelect,
    required this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final isActive = index == activeIndex;
          final file = files[index];
          final fileName = path.basename(file);
          
          return Container(
            height: 32,
            constraints: const BoxConstraints(
              maxWidth: 200,
              minWidth: 100,
            ),
            margin: const EdgeInsets.only(right: 1),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: InkWell(
              onTap: () => onSelect(index),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onClose(index),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 显示标签页右键菜单
  void _showTabContextMenu(BuildContext context, String filePath, Offset position) {
    final items = <PopupMenuEntry<String>>[];
    
    // 关闭标签
    items.add(
      PopupMenuItem<String>(
        value: 'close',
        child: Row(
          children: [
            Icon(Icons.close, size: 16),
            SizedBox(width: 8),
            Text('关闭'),
          ],
        ),
      ),
    );
    
    // 复制文件名
    items.add(
      PopupMenuItem<String>(
        value: 'copyFilename',
        child: Row(
          children: [
            Icon(Icons.file_copy, size: 16),
            SizedBox(width: 8),
            Text('复制文件名'),
          ],
        ),
      ),
    );
    
    // 复制文件路径
    items.add(
      PopupMenuItem<String>(
        value: 'copyPath',
        child: Row(
          children: [
            Icon(Icons.content_copy, size: 16),
            SizedBox(width: 8),
            Text('复制文件路径'),
          ],
        ),
      ),
    );
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'close':
          onClose(activeIndex);
          break;
        case 'copyFilename':
          Clipboard.setData(ClipboardData(text: path.basename(filePath)));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已复制文件名到剪贴板')),
          );
          break;
        case 'copyPath':
          Clipboard.setData(ClipboardData(text: filePath));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已复制文件路径到剪贴板')),
          );
          break;
      }
    });
  }
  
  /// 获取文件图标
  IconData _getFileIcon(String fileName) {
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
} 