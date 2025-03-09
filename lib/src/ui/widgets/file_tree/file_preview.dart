import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../../services/file/file_service.dart';
import '../../../state/providers/file_tree_provider.dart';

/// 文件预览组件
class FilePreview extends ConsumerStatefulWidget {
  final FileNode? node;
  final VoidCallback? onClose;

  const FilePreview({
    Key? key,
    this.node,
    this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends ConsumerState<FilePreview> {
  final FileService _fileService = FileService();
  String? _fileContent;
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadFilePreview();
  }
  
  @override
  void didUpdateWidget(FilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node?.path != oldWidget.node?.path) {
      _loadFilePreview();
    }
  }
  
  Future<void> _loadFilePreview() async {
    if (widget.node == null || widget.node!.isDirectory) {
      setState(() {
        _fileContent = null;
        _isLoading = false;
        _error = null;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // 检查文件大小，如果太大则不加载内容
      final fileSize = await _fileService.getFileSize(widget.node!.path);
      if (fileSize > 1024 * 1024) { // 大于1MB的文件不预览
        setState(() {
          _fileContent = null;
          _isLoading = false;
          _error = '文件过大，无法预览';
        });
        return;
      }
      
      // 根据文件类型决定如何预览
      final extension = path.extension(widget.node!.path).toLowerCase();
      
      // 文本文件直接读取内容
      if (_isTextFile(extension)) {
        final content = await _fileService.readFile(widget.node!.path);
        setState(() {
          _fileContent = content;
          _isLoading = false;
        });
      } else {
        setState(() {
          _fileContent = null;
          _isLoading = false;
          _error = '不支持预览此类型的文件';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '加载预览失败: $e';
      });
    }
  }
  
  bool _isTextFile(String extension) {
    final textExtensions = [
      '.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', 
      '.js', '.ts', '.dart', '.py', '.java', '.c', '.cpp', '.h', '.cs',
      '.go', '.rs', '.rb', '.php', '.sh', '.bat', '.ps1', '.log', '.csv',
      '.ini', '.conf', '.properties', '.gradle', '.kt', '.swift'
    ];
    return textExtensions.contains(extension);
  }
  
  bool _isImageFile(String extension) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp'];
    return imageExtensions.contains(extension);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.node == null) {
      return Center(
        child: Text(
          '选择一个文件进行预览',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 预览头部
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.node!.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: widget.onClose,
                  splashRadius: 16,
                  tooltip: '关闭预览',
                ),
            ],
          ),
        ),
        
        // 预览内容
        Expanded(
          child: _buildPreviewContent(context),
        ),
      ],
    );
  }
  
  Widget _buildPreviewContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    
    if (widget.node!.isDirectory) {
      return Center(child: Text('${widget.node!.name} 是一个目录'));
    }
    
    final extension = path.extension(widget.node!.path).toLowerCase();
    
    // 图片预览
    if (_isImageFile(extension)) {
      return _buildImagePreview();
    }
    
    // 文本预览
    if (_fileContent != null) {
      return _buildTextPreview();
    }
    
    return Center(child: Text('无法预览 ${widget.node!.name}'));
  }
  
  Widget _buildTextPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _fileContent!,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildImagePreview() {
    return Center(
      child: Image.file(
        File(widget.node!.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text('无法加载图片'));
        },
      ),
    );
  }
} 