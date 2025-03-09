/// 编辑器命令基类
abstract class EditorCommand {
  void execute();
  void undo();
}

/// 文本修改命令
class TextEditCommand extends EditorCommand {
  final String oldText;
  final String newText;
  final int start;
  final int end;
  final Function(String text, int start, int end) onTextChange;

  TextEditCommand({
    required this.oldText,
    required this.newText,
    required this.start,
    required this.end,
    required this.onTextChange,
  });

  @override
  void execute() {
    onTextChange(newText, start, end);
  }

  @override
  void undo() {
    onTextChange(oldText, start, start + oldText.length);
  }
}

/// 命令历史管理器
class CommandHistory {
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void execute(EditorCommand command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
  }

  void redo() {
    if (!canRedo) return;
    
    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
} 