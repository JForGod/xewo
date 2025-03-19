import 'package:flutter/material.dart';

/// 编辑器状态栏
class StatusBar extends StatelessWidget {
  /// 语言
  final String language;
  
  /// 当前行
  final int line;
  
  /// 当前列
  final int column;
  
  /// 编码
  final String? encoding;
  
  /// 构造函数
  const StatusBar({
    Key? key,
    required this.language,
    required this.line,
    required this.column,
    this.encoding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '行 $line, 列 $column',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '语言: $language',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 