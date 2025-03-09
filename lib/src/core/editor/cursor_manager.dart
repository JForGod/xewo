import 'package:flutter/material.dart';
import 'text_position_utils.dart';

class CursorManager {
  final TextEditingController controller;
  final List<TextPosition> _cursors = [];

  CursorManager(this.controller);

  void addCursor() {
    final TextSelection selection = controller.selection;
    if (selection.isValid) {
      final TextPosition newCursor = TextPosition(
        offset: selection.end,
        affinity: selection.affinity,
      );
      
      if (!_cursors.contains(newCursor)) {
        _cursors.add(newCursor);
        _updateSelection();
      }
    }
  }

  void removeCursor(TextPosition cursor) {
    _cursors.remove(cursor);
    _updateSelection();
  }

  void _updateSelection() {
    if (_cursors.isEmpty) return;

    // 创建多光标选择
    final TextSelection newSelection = TextSelection(
      baseOffset: _cursors.first.offset,
      extentOffset: _cursors.last.offset,
      affinity: _cursors.first.affinity,
      isDirectional: true,
    );

    controller.selection = newSelection;
  }

  void dispose() {
    _cursors.clear();
  }
}