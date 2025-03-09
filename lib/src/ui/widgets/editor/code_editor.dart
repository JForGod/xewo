import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'multi_cursor_editor.dart';
import '../../../state/providers/editor_settings_provider.dart';

/// 代码编辑器组件
class CodeEditor extends ConsumerStatefulWidget {
  /// 代码内容
  final String code;
  
  /// 编程语言
  final String language;
  
  /// 代码变更回调
  final ValueChanged<String> onCodeChanged;

  const CodeEditor({
    Key? key,
    required this.code,
    required this.language,
    required this.onCodeChanged,
  }) : super(key: key);

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    _focusNode = FocusNode(debugLabel: 'CodeEditorFocusNode');
    _scrollController = ScrollController();
    
    // 添加文本变更监听
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果外部代码变更且与当前不同，则更新编辑器内容
    if (widget.code != oldWidget.code && widget.code != _controller.text) {
      _controller.text = widget.code;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 文本变更处理
  void _onTextChanged() {
    widget.onCodeChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(editorSettingsProvider);
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Expanded(
            child: MultiCursorEditor(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              style: TextStyle(
                fontFamily: settings.fontFamily,
                fontSize: settings.fontSize,
                color: theme.colorScheme.onSurface,
              ),
              padding: const EdgeInsets.all(16),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              expands: true,
              enableSuggestions: false,
              autocorrect: false,
              enableIMEPersonalizedLearning: false,
              cursorColor: theme.colorScheme.primary,
              cursorWidth: 2,
              cursorRadius: const Radius.circular(1),
              selectionControls: MaterialTextSelectionControls(),
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
              onTap: () {
                // 确保点击时获取焦点
                if (!_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                }
              },
            ),
          ),
          
          // 状态栏
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.language.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_controller.text.split('\n').length} 行',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 