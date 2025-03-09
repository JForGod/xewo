import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 文件过滤类型
enum FileFilterType {
  all,
  dart,
  javascript,
  html,
  css,
  json,
  markdown,
  image,
  document,
  custom,
}

/// 文件过滤组件
class FileFilter extends StatefulWidget {
  final FileFilterType initialFilterType;
  final String? initialCustomPattern;
  final Function(FileFilterType, String?) onFilterChanged;

  const FileFilter({
    Key? key,
    this.initialFilterType = FileFilterType.all,
    this.initialCustomPattern,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<FileFilter> createState() => _FileFilterState();
}

class _FileFilterState extends State<FileFilter> {
  late FileFilterType _currentFilterType;
  String? _customPattern;
  final TextEditingController _customPatternController = TextEditingController();
  bool _showCustomFilter = false;

  @override
  void initState() {
    super.initState();
    _currentFilterType = widget.initialFilterType;
    _customPattern = widget.initialCustomPattern;
    _customPatternController.text = _customPattern ?? '';
    _showCustomFilter = _currentFilterType == FileFilterType.custom;
  }

  @override
  void dispose() {
    _customPatternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 过滤类型选择器
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingXs,
          children: [
            _buildFilterChip(FileFilterType.all, '全部文件'),
            _buildFilterChip(FileFilterType.dart, 'Dart'),
            _buildFilterChip(FileFilterType.javascript, 'JavaScript'),
            _buildFilterChip(FileFilterType.html, 'HTML'),
            _buildFilterChip(FileFilterType.css, 'CSS'),
            _buildFilterChip(FileFilterType.json, 'JSON'),
            _buildFilterChip(FileFilterType.markdown, 'Markdown'),
            _buildFilterChip(FileFilterType.image, '图片'),
            _buildFilterChip(FileFilterType.document, '文档'),
            _buildFilterChip(FileFilterType.custom, '自定义'),
          ],
        ),
        
        // 自定义过滤规则输入框
        if (_showCustomFilter) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: TextField(
                    controller: _customPatternController,
                    decoration: InputDecoration(
                      hintText: '输入过滤规则 (例如: *.txt)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, size: 18),
                        onPressed: _applyCustomFilter,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _applyCustomFilter(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Tooltip(
                message: '过滤规则说明:\n'
                    '*.dart: 所有Dart文件\n'
                    '*.{js,ts}: 所有JavaScript和TypeScript文件\n'
                    'test_*: 所有以test_开头的文件\n'
                    '正则表达式: /^test.*\\.dart\$/',
                child: const Icon(Icons.help_outline, size: 16),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 构建过滤选项芯片
  Widget _buildFilterChip(FileFilterType type, String label) {
    return FilterChip(
      label: Text(label),
      selected: _currentFilterType == type,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilterType = type;
            _showCustomFilter = type == FileFilterType.custom;
          });
          
          if (type != FileFilterType.custom) {
            widget.onFilterChanged(type, null);
          } else if (_customPattern != null) {
            widget.onFilterChanged(type, _customPattern);
          }
        }
      },
      backgroundColor: Theme.of(context).chipTheme.backgroundColor,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  /// 应用自定义过滤规则
  void _applyCustomFilter() {
    final pattern = _customPatternController.text.trim();
    if (pattern.isNotEmpty) {
      setState(() {
        _customPattern = pattern;
      });
      widget.onFilterChanged(FileFilterType.custom, pattern);
    }
  }
}

/// 文件过滤工具类
class FileFilterUtils {
  /// 根据过滤类型和自定义规则过滤文件名
  static bool matchesFilter(String fileName, FileFilterType filterType, String? customPattern) {
    switch (filterType) {
      case FileFilterType.all:
        return true;
      case FileFilterType.dart:
        return fileName.toLowerCase().endsWith('.dart');
      case FileFilterType.javascript:
        return fileName.toLowerCase().endsWith('.js') || 
               fileName.toLowerCase().endsWith('.ts') ||
               fileName.toLowerCase().endsWith('.jsx') ||
               fileName.toLowerCase().endsWith('.tsx');
      case FileFilterType.html:
        return fileName.toLowerCase().endsWith('.html') || 
               fileName.toLowerCase().endsWith('.htm');
      case FileFilterType.css:
        return fileName.toLowerCase().endsWith('.css') || 
               fileName.toLowerCase().endsWith('.scss') ||
               fileName.toLowerCase().endsWith('.sass');
      case FileFilterType.json:
        return fileName.toLowerCase().endsWith('.json');
      case FileFilterType.markdown:
        return fileName.toLowerCase().endsWith('.md') || 
               fileName.toLowerCase().endsWith('.markdown');
      case FileFilterType.image:
        return fileName.toLowerCase().endsWith('.png') || 
               fileName.toLowerCase().endsWith('.jpg') ||
               fileName.toLowerCase().endsWith('.jpeg') ||
               fileName.toLowerCase().endsWith('.gif') ||
               fileName.toLowerCase().endsWith('.svg');
      case FileFilterType.document:
        return fileName.toLowerCase().endsWith('.pdf') || 
               fileName.toLowerCase().endsWith('.doc') ||
               fileName.toLowerCase().endsWith('.docx') ||
               fileName.toLowerCase().endsWith('.xls') ||
               fileName.toLowerCase().endsWith('.xlsx') ||
               fileName.toLowerCase().endsWith('.ppt') ||
               fileName.toLowerCase().endsWith('.pptx') ||
               fileName.toLowerCase().endsWith('.txt');
      case FileFilterType.custom:
        if (customPattern == null || customPattern.isEmpty) return true;
        
        // 处理正则表达式模式
        if (customPattern.startsWith('/') && customPattern.endsWith('/')) {
          try {
            final pattern = customPattern.substring(1, customPattern.length - 1);
            final regex = RegExp(pattern);
            return regex.hasMatch(fileName);
          } catch (e) {
            return false;
          }
        }
        
        // 处理通配符模式
        if (customPattern.contains('*') || customPattern.contains('?')) {
          return _matchWildcard(fileName, customPattern);
        }
        
        // 处理扩展名列表模式 (*.{js,ts})
        if (customPattern.contains('{') && customPattern.contains('}')) {
          final parts = customPattern.split('.');
          if (parts.length >= 2) {
            final extPart = parts.last;
            if (extPart.startsWith('{') && extPart.endsWith('}')) {
              final extensions = extPart.substring(1, extPart.length - 1).split(',');
              for (final ext in extensions) {
                if (fileName.toLowerCase().endsWith('.${ext.trim()}')) {
                  return true;
                }
              }
              return false;
            }
          }
        }
        
        // 简单包含匹配
        return fileName.toLowerCase().contains(customPattern.toLowerCase());
    }
  }

  /// 通配符匹配
  static bool _matchWildcard(String fileName, String pattern) {
    // 将通配符模式转换为正则表达式
    String regexPattern = pattern
        .replaceAll('.', '\\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');
    
    try {
      final regex = RegExp('^$regexPattern\$', caseSensitive: false);
      return regex.hasMatch(fileName);
    } catch (e) {
      return false;
    }
  }
} 