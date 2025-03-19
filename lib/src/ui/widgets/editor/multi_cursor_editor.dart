import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/editor/controllers/multi_cursor_controller.dart';
import '../../../services/editor/multi_cursor_service.dart';
import '../../../services/editor/history_service.dart';

/// 多光标编辑器组件
class MultiCursorEditor extends ConsumerStatefulWidget {
  final String text;
  final double fontSize;
  final double lineHeight;
  final Function(String) onChanged;
  
  const MultiCursorEditor({
    super.key,
    required this.text,
    this.fontSize = 14.0,
    this.lineHeight = 20.0,
    required this.onChanged,
  });
  
  @override
  ConsumerState<MultiCursorEditor> createState() => _MultiCursorEditorState();
}

class _MultiCursorEditorState extends ConsumerState<MultiCursorEditor> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  String _lastText = '';
  bool _isUndoRedoOperation = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _scrollController = ScrollController();
    _lastText = widget.text;
    
    _controller.addListener(_handleTextChange);
  }
  
  void _handleTextChange() {
    if (_controller.text != _lastText && !_isUndoRedoOperation) {
      final historyService = ref.read(historyServiceProvider);
      final cursorController = ref.read(multiCursorControllerProvider);
      
      // 记录编辑操作
      historyService.addOperation(EditOperation(
        oldText: _lastText,
        newText: _controller.text,
        cursorPosition: _controller.selection.baseOffset,
        selections: cursorController.selections
            .map((s) => s.start.offset)
            .toList(),
      ));
      
      widget.onChanged(_controller.text);
      _lastText = _controller.text;
    }
  }
  
  void _handleUndo() {
    final historyService = ref.read(historyServiceProvider);
    final operation = historyService.undo();
    
    if (operation != null) {
      _isUndoRedoOperation = true;
      _controller.text = operation.oldText;
      _controller.selection = TextSelection.collapsed(
        offset: operation.cursorPosition,
      );
      _isUndoRedoOperation = false;
      _lastText = operation.oldText;
      
      // 恢复选择区域
      final cursorController = ref.read(multiCursorControllerProvider);
      cursorController.clearSelections();
      for (final offset in operation.selections) {
        cursorController.addSelection(SelectionRange(
          start: CursorPosition(
            offset: offset,
            line: 0, // TODO: 计算正确的行号
            column: 0, // TODO: 计算正确的列号
          ),
          end: CursorPosition(
            offset: offset,
            line: 0,
            column: 0,
          ),
        ));
      }
    }
  }
  
  void _handleRedo() {
    final historyService = ref.read(historyServiceProvider);
    final operation = historyService.redo();
    
    if (operation != null) {
      _isUndoRedoOperation = true;
      _controller.text = operation.newText;
      _controller.selection = TextSelection.collapsed(
        offset: operation.cursorPosition,
      );
      _isUndoRedoOperation = false;
      _lastText = operation.newText;
      
      // 恢复选择区域
      final cursorController = ref.read(multiCursorControllerProvider);
      cursorController.clearSelections();
      for (final offset in operation.selections) {
        cursorController.addSelection(SelectionRange(
          start: CursorPosition(
            offset: offset,
            line: 0, // TODO: 计算正确的行号
            column: 0, // TODO: 计算正确的列号
          ),
          end: CursorPosition(
            offset: offset,
            line: 0,
            column: 0,
          ),
        ));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final cursorController = ref.watch(multiCursorControllerProvider);
    final padding = const EdgeInsets.all(8);
    
    return GestureDetector(
      onPanDown: (details) {
        _focusNode.requestFocus();
        cursorController.handleMouseDown(
          _controller.text,
          details.localPosition,
          widget.fontSize,
          widget.lineHeight,
          _scrollController.hasClients ? _scrollController.offset : 0,
          padding,
          details.kind == PointerDeviceKind.mouse && details.buttons == kSecondaryMouseButton,
          details.kind == PointerDeviceKind.mouse && details.buttons == kMiddleMouseButton,
          details.kind == PointerDeviceKind.mouse && details.buttons == kPrimaryMouseButton,
        );
      },
      onPanUpdate: (details) {
        cursorController.handleMouseMove(
          _controller.text,
          details.localPosition,
          widget.fontSize,
          widget.lineHeight,
          _scrollController.hasClients ? _scrollController.offset : 0,
          padding,
          details.kind == PointerDeviceKind.mouse && details.buttons == kSecondaryMouseButton,
          details.kind == PointerDeviceKind.mouse && details.buttons == kMiddleMouseButton,
          details.kind == PointerDeviceKind.mouse && details.buttons == kPrimaryMouseButton,
        );
      },
      onPanEnd: (details) {
        cursorController.handleMouseUp();
      },
      onDoubleTapDown: (details) {
        cursorController.handleDoubleClick(
          _controller.text,
          details.localPosition,
          widget.fontSize,
          widget.lineHeight,
          _scrollController.hasClients ? _scrollController.offset : 0,
          padding,
        );
      },
      onTripleTapDown: (details) {
        cursorController.handleTripleClick(
          _controller.text,
          details.localPosition,
          widget.fontSize,
          widget.lineHeight,
          _scrollController.hasClients ? _scrollController.offset : 0,
          padding,
        );
      },
      child: Stack(
        children: [
          // 编辑器背景
          Container(
            color: Theme.of(context).colorScheme.surface,
          ),
          
          // 文本编辑器
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: padding,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 50, // 提供有限宽度约束
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: widget.fontSize,
                    height: widget.lineHeight / widget.fontSize,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ),
          
          // 光标和选择区域
          RepaintBoundary(
            child: CustomPaint(
              painter: _MultiCursorPainter(
                text: _controller.text,
                selections: cursorController.selections,
                primarySelection: cursorController.primarySelection,
                fontSize: widget.fontSize,
                lineHeight: widget.lineHeight,
                scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
                padding: padding,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    // 先移除监听器，再释放资源
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    
    // 确保ScrollController正确释放
    if (_scrollController.hasClients) {
      _scrollController.removeListener(() {});
    }
    _scrollController.dispose();
    
    // 确保FocusNode正确释放
    _focusNode.dispose();
    
    super.dispose();
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