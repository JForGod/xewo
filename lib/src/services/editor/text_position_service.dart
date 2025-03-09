import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'multi_cursor_service.dart';

/// 文本位置服务
class TextPositionService {
  /// 从屏幕坐标获取光标位置
  CursorPosition getCursorPosition(
    String text,
    Offset position,
    double fontSize,
    double lineHeight,
    double scrollOffset,
    EdgeInsets padding,
  ) {
    // 计算行号
    final line = ((position.dy + scrollOffset - padding.top) / lineHeight).floor();
    
    // 获取当前行的文本
    final lines = text.split('\n');
    if (line < 0 || line >= lines.length) {
      return const CursorPosition(offset: 0, line: 0, column: 0);
    }
    
    final lineText = lines[line];
    
    // 计算列号
    final column = ((position.dx - padding.left) / fontSize).round();
    final clampedColumn = column.clamp(0, lineText.length);
    
    // 计算偏移量
    int offset = 0;
    for (int i = 0; i < line; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }
    offset += clampedColumn;
    
    return CursorPosition(
      offset: offset,
      line: line,
      column: clampedColumn,
    );
  }
  
  /// 从偏移量获取光标位置
  CursorPosition getCursorPositionFromOffset(
    String text,
    int offset,
  ) {
    if (offset < 0 || offset > text.length) {
      return const CursorPosition(offset: 0, line: 0, column: 0);
    }
    
    final beforeText = text.substring(0, offset);
    final lines = beforeText.split('\n');
    final line = lines.length - 1;
    final column = lines.last.length;
    
    return CursorPosition(
      offset: offset,
      line: line,
      column: column,
    );
  }
  
  /// 获取指定位置的字符宽度
  double getCharacterWidth(
    String text,
    int offset,
    double fontSize,
  ) {
    if (offset < 0 || offset >= text.length) return fontSize;
    
    final char = text[offset];
    if (char == '\t') {
      return fontSize * 2; // 制表符宽度为2个字符
    }
    
    // 检查是否是全角字符
    if (char.codeUnitAt(0) > 0xFF) {
      return fontSize * 2;
    }
    
    return fontSize;
  }
  
  /// 获取指定行的宽度
  double getLineWidth(
    String text,
    int line,
    double fontSize,
  ) {
    final lines = text.split('\n');
    if (line < 0 || line >= lines.length) return 0;
    
    final lineText = lines[line];
    double width = 0;
    
    for (int i = 0; i < lineText.length; i++) {
      width += getCharacterWidth(lineText, i, fontSize);
    }
    
    return width;
  }
  
  /// 获取指定位置的单词范围
  SelectionRange getWordRange(
    String text,
    CursorPosition position,
  ) {
    if (position.offset < 0 || position.offset >= text.length) {
      return SelectionRange(start: position, end: position);
    }
    
    // 向前查找单词开始
    int start = position.offset;
    while (start > 0 && _isWordChar(text[start - 1])) {
      start--;
    }
    
    // 向后查找单词结束
    int end = position.offset;
    while (end < text.length && _isWordChar(text[end])) {
      end++;
    }
    
    return SelectionRange(
      start: getCursorPositionFromOffset(text, start),
      end: getCursorPositionFromOffset(text, end),
    );
  }
  
  /// 获取指定位置的行范围
  SelectionRange getLineRange(
    String text,
    CursorPosition position,
  ) {
    final lines = text.split('\n');
    if (position.line < 0 || position.line >= lines.length) {
      return SelectionRange(start: position, end: position);
    }
    
    // 计算行开始的偏移量
    int start = 0;
    for (int i = 0; i < position.line; i++) {
      start += lines[i].length + 1;
    }
    
    // 计算行结束的偏移量
    final end = start + lines[position.line].length;
    
    return SelectionRange(
      start: getCursorPositionFromOffset(text, start),
      end: getCursorPositionFromOffset(text, end),
    );
  }
  
  /// 检查字符是否是单词字符
  bool _isWordChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }
}

/// 文本位置服务提供者
final textPositionServiceProvider = Provider<TextPositionService>((ref) {
  return TextPositionService();
}); 