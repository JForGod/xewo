import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 编辑操作
class EditOperation {
  final String oldText;
  final String newText;
  final int cursorPosition;
  final List<int> selections;
  
  const EditOperation({
    required this.oldText,
    required this.newText,
    required this.cursorPosition,
    required this.selections,
  });
}

/// 编辑历史服务
class HistoryService {
  final List<EditOperation> _undoStack = [];
  final List<EditOperation> _redoStack = [];
  static const int maxHistorySize = 1000;
  
  /// 添加编辑操作
  void addOperation(EditOperation operation) {
    _undoStack.add(operation);
    _redoStack.clear();
    
    // 限制历史记录大小
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }
  
  /// 撤销操作
  EditOperation? undo() {
    if (_undoStack.isEmpty) return null;
    
    final operation = _undoStack.removeLast();
    _redoStack.add(operation);
    return operation;
  }
  
  /// 重做操作
  EditOperation? redo() {
    if (_redoStack.isEmpty) return null;
    
    final operation = _redoStack.removeLast();
    _undoStack.add(operation);
    return operation;
  }
  
  /// 清空历史记录
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
  
  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;
  
  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;
}

/// 编辑历史服务提供者
final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
}); 