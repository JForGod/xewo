import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 编辑器行号组件
class LineNumbers extends StatefulWidget {
  /// 文本内容
  final String text;
  
  /// 当前行
  final int currentLine;
  
  /// 滚动控制器
  final ScrollController scrollController;
  
  /// 行高
  final double lineHeight;
  
  /// 构造函数
  const LineNumbers({
    Key? key,
    required this.text,
    required this.currentLine,
    required this.scrollController,
    this.lineHeight = 20.0,
  }) : super(key: key);
  
  @override
  State<LineNumbers> createState() => _LineNumbersState();
}

class _LineNumbersState extends State<LineNumbers> {
  @override
  Widget build(BuildContext context) {
    final lines = widget.text.split('\n');
    final lineCount = lines.length;
    
    return Container(
      width: 48,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(lineCount, (index) {
            final lineNumber = index + 1;
            final isCurrentLine = lineNumber == widget.currentLine;
            
            return Container(
              height: widget.lineHeight,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: isCurrentLine
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                border: isCurrentLine
                    ? Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2.0,
                        ),
                      )
                    : null,
              ),
              child: Text(
                '$lineNumber',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: isCurrentLine
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
} 