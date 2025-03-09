import 'package:flutter/material.dart';

/// 保存文件意图
class SaveFileIntent extends Intent {
  const SaveFileIntent();
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

/// 查找下一个意图
class FindNextIntent extends Intent {
  const FindNextIntent();
}

/// 查找上一个意图
class FindPreviousIntent extends Intent {
  const FindPreviousIntent();
}

/// 格式化代码意图
class FormatCodeIntent extends Intent {
  const FormatCodeIntent();
} 