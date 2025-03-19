import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 编辑器状态栏组件
class EditorStatusBar extends StatelessWidget {
  final String language;
  final int line;
  final int column;
  final String? filePath;
  
  const EditorStatusBar({
    Key? key,
    required this.language,
    required this.line,
    required this.column,
    this.filePath,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // 语言模式
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              language.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          const SizedBox(width: 8.0),
          
          // 行列信息
          Text(
            '第 $line 行，第 $column 列',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          
          const Spacer(),
          
          // 文件路径
          if (filePath != null)
            Expanded(
              child: Text(
                filePath!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
} 