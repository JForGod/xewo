import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 光标位置
class CursorPosition {
  final int offset;
  final int line;
  final int column;
  
  const CursorPosition({
    required this.offset,
    required this.line,
    required this.column,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursorPosition &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          line == other.line &&
          column == other.column;
  
  @override
  int get hashCode => offset.hashCode ^ line.hashCode ^ column.hashCode;
}

/// 选择区域
class SelectionRange {
  final CursorPosition start;
  final CursorPosition end;
  
  const SelectionRange({
    required this.start,
    required this.end,
  });
  
  bool get isCollapsed => start == end;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;
  
  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// 多光标编辑服务
class MultiCursorService {
  final List<SelectionRange> _selections = [];
  int _primarySelectionIndex = 0;
  
  /// 获取所有选择区域
  List<SelectionRange> get selections => List.unmodifiable(_selections);
  
  /// 获取主选择区域
  SelectionRange? get primarySelection =>
      _selections.isEmpty ? null : _selections[_primarySelectionIndex];
  
  /// 添加选择区域
  void addSelection(SelectionRange selection) {
    _selections.add(selection);
    _primarySelectionIndex = _selections.length - 1;
  }
  
  /// 移除选择区域
  void removeSelection(SelectionRange selection) {
    final index = _selections.indexOf(selection);
    if (index != -1) {
      _selections.removeAt(index);
      if (_primarySelectionIndex >= _selections.length) {
        _primarySelectionIndex = _selections.isEmpty ? 0 : _selections.length - 1;
      }
    }
  }
  
  /// 清除所有选择区域
  void clearSelections() {
    _selections.clear();
    _primarySelectionIndex = 0;
  }
  
  /// 设置主选择区域
  void setPrimarySelection(SelectionRange selection) {
    final index = _selections.indexOf(selection);
    if (index != -1) {
      _primarySelectionIndex = index;
    }
  }
  
  /// 获取指定位置的选择区域
  SelectionRange? getSelectionAt(CursorPosition position) {
    return _selections.firstWhere(
      (selection) =>
          position.offset >= selection.start.offset &&
          position.offset <= selection.end.offset,
      orElse: () => throw StateError('No selection found at position'),
    );
  }
  
  /// 更新选择区域
  void updateSelection(SelectionRange oldSelection, SelectionRange newSelection) {
    final index = _selections.indexOf(oldSelection);
    if (index != -1) {
      _selections[index] = newSelection;
    }
  }
  
  /// 获取选择的文本
  List<String> getSelectedText(String text) {
    return _selections.map((selection) {
      final start = selection.start.offset;
      final end = selection.end.offset;
      return text.substring(start, end);
    }).toList();
  }
  
  /// 替换选择的文本
  String replaceSelectedText(String text, String replacement) {
    // 按照偏移量从大到小排序，以避免替换时影响后续偏移量
    final sortedSelections = List.of(_selections)
      ..sort((a, b) => b.start.offset.compareTo(a.start.offset));
    
    String result = text;
    for (final selection in sortedSelections) {
      final start = selection.start.offset;
      final end = selection.end.offset;
      result = result.replaceRange(start, end, replacement);
    }
    
    return result;
  }
  
  /// 获取列选择模式的选择区域
  List<SelectionRange> getColumnSelection(
    String text,
    CursorPosition start,
    CursorPosition end,
  ) {
    final lines = text.split('\n');
    final startLine = start.line;
    final endLine = end.line;
    final startColumn = start.column;
    final endColumn = end.column;
    
    final selections = <SelectionRange>[];
    for (int line = startLine; line <= endLine; line++) {
      final lineText = lines[line];
      final lineLength = lineText.length;
      
      // 计算当前行的选择范围
      final selectionStart = CursorPosition(
        offset: _getOffsetForPosition(lines, line, startColumn),
        line: line,
        column: startColumn,
      );
      
      final selectionEnd = CursorPosition(
        offset: _getOffsetForPosition(lines, line, endColumn),
        line: line,
        column: endColumn,
      );
      
      selections.add(SelectionRange(
        start: selectionStart,
        end: selectionEnd,
      ));
    }
    
    return selections;
  }
  
  /// 获取指定位置的偏移量
  int _getOffsetForPosition(List<String> lines, int line, int column) {
    int offset = 0;
    
    // 计算之前所有行的长度
    for (int i = 0; i < line; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }
    
    // 添加当前行的列偏移
    offset += column;
    return offset;
  }
}

/// 多光标编辑服务提供者
final multiCursorServiceProvider = Provider<MultiCursorService>((ref) {
  return MultiCursorService();
}); 