import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/editor/controllers/multi_cursor_controller.dart';
import '../../../services/editor/multi_cursor_service.dart';
import '../../../services/editor/history_service.dart';

/// 多光标编辑器组件
class MultiCursorEditor extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final TextStyle? style;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool expands;
  final bool enableSuggestions;
  final bool autocorrect;
  final bool enableIMEPersonalizedLearning;
  final Color? cursorColor;
  final double cursorWidth;
  final Radius? cursorRadius;
  final TextSelectionControls? selectionControls;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final EdgeInsetsGeometry? padding;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;

  const MultiCursorEditor({
    Key? key,
    this.controller,
    this.focusNode,
    this.scrollController,
    this.style,
    this.decoration,
    this.keyboardType,
    this.maxLines,
    this.expands = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.enableIMEPersonalizedLearning = true,
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.selectionControls,
    this.contextMenuBuilder,
    this.padding,
    this.onChanged,
    this.onTap,
  }) : super(key: key);

  @override
  State<MultiCursorEditor> createState() => _MultiCursorEditorState();
}

class _MultiCursorEditorState extends State<MultiCursorEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  List<TextSelection> _selections = [];
  TextSelection? _primarySelection;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        scrollController: _scrollController,
        style: widget.style,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        expands: widget.expands,
        enableSuggestions: widget.enableSuggestions,
        autocorrect: widget.autocorrect,
        enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
        cursorColor: widget.cursorColor,
        cursorWidth: widget.cursorWidth,
        cursorRadius: widget.cursorRadius,
        selectionControls: widget.selectionControls,
        contextMenuBuilder: widget.contextMenuBuilder,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
      ),
    );
  }
}

/// 多光标绘制器
class _MultiCursorPainter extends CustomPainter {
  final String text;
  final List<SelectionRange> selections;
  final SelectionRange? primarySelection;
  final double fontSize;
  final double lineHeight;
  final double scrollOffset;
  final EdgeInsets padding;
  
  _MultiCursorPainter({
    required this.text,
    required this.selections,
    required this.primarySelection,
    required this.fontSize,
    required this.lineHeight,
    required this.scrollOffset,
    required this.padding,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final cursorPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    
    // 计算可见区域
    final visibleStart = (scrollOffset / lineHeight).floor();
    final visibleEnd = ((scrollOffset + size.height) / lineHeight).ceil();
    
    for (final selection in selections) {
      // 跳过不在可见区域的选择
      if (selection.end.line < visibleStart || selection.start.line > visibleEnd) {
        continue;
      }
      
      final isCollapsed = selection.isCollapsed;
      final isPrimary = selection == primarySelection;
      
      if (isCollapsed) {
        // 绘制光标
        final cursorX = _getXForColumn(text, selection.start.line, selection.start.column) + padding.left;
        final cursorY = selection.start.line * lineHeight - scrollOffset + padding.top;
        
        canvas.drawRect(
          Rect.fromLTWH(cursorX, cursorY, 2, lineHeight),
          cursorPaint,
        );
      } else {
        // 绘制选择区域
        final startX = _getXForColumn(text, selection.start.line, selection.start.column) + padding.left;
        final startY = selection.start.line * lineHeight - scrollOffset + padding.top;
        final endX = _getXForColumn(text, selection.end.line, selection.end.column) + padding.left;
        final endY = selection.end.line * lineHeight - scrollOffset + padding.top;
        
        if (selection.start.line == selection.end.line) {
          // 单行选择
          canvas.drawRect(
            Rect.fromLTWH(startX, startY, endX - startX, lineHeight),
            paint,
          );
        } else {
          // 多行选择
          // 第一行
          canvas.drawRect(
            Rect.fromLTWH(startX, startY, endX - startX, lineHeight),
            paint,
          );
          
          // 中间行
          for (int line = selection.start.line + 1; line < selection.end.line; line++) {
            final y = line * lineHeight - scrollOffset + padding.top;
            canvas.drawRect(
              Rect.fromLTWH(padding.left, y, size.width - padding.horizontal, lineHeight),
              paint,
            );
          }
          
          // 最后一行
          canvas.drawRect(
            Rect.fromLTWH(padding.left, endY, endX - padding.left, lineHeight),
            paint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _MultiCursorPainter oldDelegate) {
    return text != oldDelegate.text ||
        selections != oldDelegate.selections ||
        primarySelection != oldDelegate.primarySelection ||
        fontSize != oldDelegate.fontSize ||
        lineHeight != oldDelegate.lineHeight ||
        scrollOffset != oldDelegate.scrollOffset ||
        padding != oldDelegate.padding;
  }
  
  /// 获取指定列的X坐标
  double _getXForColumn(String text, int line, int column) {
    final lines = text.split('\n');
    if (line >= lines.length) return 0;
    
    final lineText = lines[line];
    if (column > lineText.length) return lineText.length * fontSize;
    
    return column * fontSize;
  }
} 