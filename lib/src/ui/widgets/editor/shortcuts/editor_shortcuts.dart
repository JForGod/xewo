import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/providers/shortcut_provider.dart';

/// 保存意图
class SaveIntent extends Intent {
  const SaveIntent();
}

/// 撤销意图
class UndoIntent extends Intent {
  const UndoIntent();
}

/// 重做意图
class RedoIntent extends Intent {
  const RedoIntent();
}

/// 剪切意图
class CutIntent extends Intent {
  const CutIntent();
}

/// 复制意图
class CopyIntent extends Intent {
  const CopyIntent();
}

/// 粘贴意图
class PasteIntent extends Intent {
  const PasteIntent();
}

/// 查找意图
class FindIntent extends Intent {
  const FindIntent();
}

/// 替换意图
class ReplaceIntent extends Intent {
  const ReplaceIntent();
}

/// 格式化意图
class FormatIntent extends Intent {
  const FormatIntent();
}

/// 编辑器快捷键组件
class EditorShortcuts extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onFind;
  final VoidCallback? onReplace;
  final VoidCallback? onFormat;

  const EditorShortcuts({
    super.key,
    required this.child,
    this.onSave,
    this.onUndo,
    this.onRedo,
    this.onCut,
    this.onCopy,
    this.onPaste,
    this.onFind,
    this.onReplace,
    this.onFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcutState = ref.watch(shortcutProvider);
    
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // 文件操作
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): 
            const SaveIntent(),
        
        // 编辑操作
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): 
            const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): 
            const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX): 
            const CutIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC): 
            const CopyIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV): 
            const PasteIntent(),
        
        // 查找替换
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): 
            const FindIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH): 
            const ReplaceIntent(),
        
        // 格式化
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyF): 
            const FormatIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) => onSave?.call(),
          ),
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (intent) => onUndo?.call(),
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (intent) => onRedo?.call(),
          ),
          CutIntent: CallbackAction<CutIntent>(
            onInvoke: (intent) => onCut?.call(),
          ),
          CopyIntent: CallbackAction<CopyIntent>(
            onInvoke: (intent) => onCopy?.call(),
          ),
          PasteIntent: CallbackAction<PasteIntent>(
            onInvoke: (intent) => onPaste?.call(),
          ),
          FindIntent: CallbackAction<FindIntent>(
            onInvoke: (intent) => onFind?.call(),
          ),
          ReplaceIntent: CallbackAction<ReplaceIntent>(
            onInvoke: (intent) => onReplace?.call(),
          ),
          FormatIntent: CallbackAction<FormatIntent>(
            onInvoke: (intent) => onFormat?.call(),
          ),
        },
        child: child,
      ),
    );
  }
} 