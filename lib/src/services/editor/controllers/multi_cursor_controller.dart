import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../multi_cursor_service.dart';
import '../text_position_service.dart';

/// 多光标编辑控制器
class MultiCursorController extends ChangeNotifier {
  final MultiCursorService _service;
  final TextPositionService _textPositionService;
  bool _isColumnMode = false;
  
  MultiCursorController(this._service, this._textPositionService);
  
  /// 获取所有选择区域
  List<SelectionRange> get selections => _service.selections;
  
  /// 获取主选择区域
  SelectionRange? get primarySelection => _service.primarySelection;
  
  /// 是否处于列选择模式
  bool get isColumnMode => _isColumnMode;
  
  /// 添加选择区域
  void addSelection(SelectionRange selection) {
    _service.addSelection(selection);
    notifyListeners();
  }
  
  /// 移除选择区域
  void removeSelection(SelectionRange selection) {
    _service.removeSelection(selection);
    notifyListeners();
  }
  
  /// 清除所有选择区域
  void clearSelections() {
    _service.clearSelections();
    notifyListeners();
  }
  
  /// 设置主选择区域
  void setPrimarySelection(SelectionRange selection) {
    _service.setPrimarySelection(selection);
    notifyListeners();
  }
  
  /// 更新选择区域
  void updateSelection(SelectionRange oldSelection, SelectionRange newSelection) {
    _service.updateSelection(oldSelection, newSelection);
    notifyListeners();
  }
  
  /// 切换列选择模式
  void toggleColumnMode() {
    _isColumnMode = !_isColumnMode;
    notifyListeners();
  }
  
  /// 处理鼠标点击事件
  void handleMouseDown(
    String text,
    Offset position,
    double fontSize,
    double lineHeight,
    double scrollOffset,
    EdgeInsets padding,
    bool isShiftPressed,
    bool isCtrlPressed,
    bool isAltPressed,
  ) {
    final cursorPosition = _textPositionService.getCursorPosition(
      text,
      position,
      fontSize,
      lineHeight,
      scrollOffset,
      padding,
    );
    
    if (isCtrlPressed) {
      // 添加新的光标
      addSelection(SelectionRange(
        start: cursorPosition,
        end: cursorPosition,
      ));
    } else if (isAltPressed) {
      // 切换列选择模式
      toggleColumnMode();
      if (_isColumnMode && primarySelection != null) {
        final columnSelections = _service.getColumnSelection(
          text,
          primarySelection!.start,
          cursorPosition,
        );
        clearSelections();
        for (final selection in columnSelections) {
          addSelection(selection);
        }
      }
    } else if (isShiftPressed && primarySelection != null) {
      // 扩展选择区域
      updateSelection(
        primarySelection!,
        SelectionRange(
          start: primarySelection!.start,
          end: cursorPosition,
        ),
      );
    } else {
      // 新建选择区域
      clearSelections();
      addSelection(SelectionRange(
        start: cursorPosition,
        end: cursorPosition,
      ));
    }
  }
  
  /// 处理鼠标移动事件
  void handleMouseMove(
    String text,
    Offset position,
    double fontSize,
    double lineHeight,
    double scrollOffset,
    EdgeInsets padding,
    bool isShiftPressed,
    bool isCtrlPressed,
    bool isAltPressed,
  ) {
    if (primarySelection == null) return;
    
    final cursorPosition = _textPositionService.getCursorPosition(
      text,
      position,
      fontSize,
      lineHeight,
      scrollOffset,
      padding,
    );
    
    if (_isColumnMode) {
      final columnSelections = _service.getColumnSelection(
        text,
        primarySelection!.start,
        cursorPosition,
      );
      clearSelections();
      for (final selection in columnSelections) {
        addSelection(selection);
      }
    } else {
      updateSelection(
        primarySelection!,
        SelectionRange(
          start: primarySelection!.start,
          end: cursorPosition,
        ),
      );
    }
  }
  
  /// 处理鼠标释放事件
  void handleMouseUp() {
    // 如果是列选择模式，保持选择区域
    if (!_isColumnMode) {
      // 如果所有选择区域都是折叠的，只保留主选择区域
      final collapsedSelections = selections.where((s) => s.isCollapsed).toList();
      if (collapsedSelections.length == selections.length) {
        final primary = primarySelection;
        if (primary != null) {
          clearSelections();
          addSelection(primary);
        }
      }
    }
  }
  
  /// 处理双击事件
  void handleDoubleClick(
    String text,
    Offset position,
    double fontSize,
    double lineHeight,
    double scrollOffset,
    EdgeInsets padding,
  ) {
    final cursorPosition = _textPositionService.getCursorPosition(
      text,
      position,
      fontSize,
      lineHeight,
      scrollOffset,
      padding,
    );
    
    final wordRange = _textPositionService.getWordRange(text, cursorPosition);
    clearSelections();
    addSelection(wordRange);
  }
  
  /// 处理三击事件
  void handleTripleClick(
    String text,
    Offset position,
    double fontSize,
    double lineHeight,
    double scrollOffset,
    EdgeInsets padding,
  ) {
    final cursorPosition = _textPositionService.getCursorPosition(
      text,
      position,
      fontSize,
      lineHeight,
      scrollOffset,
      padding,
    );
    
    final lineRange = _textPositionService.getLineRange(text, cursorPosition);
    clearSelections();
    addSelection(lineRange);
  }
}

/// 多光标编辑控制器提供者
final multiCursorControllerProvider = ChangeNotifierProvider<MultiCursorController>((ref) {
  final service = ref.watch(multiCursorServiceProvider);
  final textPositionService = ref.watch(textPositionServiceProvider);
  return MultiCursorController(service, textPositionService);
}); 