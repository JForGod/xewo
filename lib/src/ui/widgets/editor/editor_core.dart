import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart' as vs_theme;
import 'package:flutter_highlight/themes/vs2015.dart' as vs2015_theme;
import 'package:highlight/languages/dart.dart' as dart_lang;
import 'package:highlight/languages/javascript.dart' as js_lang;
import 'package:highlight/languages/python.dart' as py_lang;
import 'package:highlight/languages/json.dart' as json_lang;
import 'package:highlight/languages/yaml.dart' as yaml_lang;
import 'package:highlight/languages/markdown.dart' as md_lang;
import 'package:highlight/languages/xml.dart' as xml_lang;
import 'package:highlight/languages/css.dart' as css_lang;
import 'package:highlight/languages/sql.dart' as sql_lang;
import 'package:highlight/languages/bash.dart' as bash_lang;
import 'package:highlight/highlight.dart' show highlight;
import 'package:xewo/src/ui/widgets/editor/code_folding.dart';

/// 编辑器核心组件
class EditorCore extends ConsumerStatefulWidget {
  /// 文本内容
  final String text;
  
  /// 文本控制器
  final TextEditingController controller;
  
  /// 语言
  final String language;
  
  /// 文件路径
  final String? filePath;
  
  /// 只读模式
  final bool readOnly;
  
  /// 文本变化回调
  final Function(String)? onTextChanged;
  
  /// 光标位置变化回调
  final Function(int, int)? onCursorPositionChanged;
  
  /// 选择变化回调
  final Function(TextSelection)? onSelectionChanged;
  
  /// 滚动控制器
  final ScrollController scrollController;
  
  /// 折叠区域
  final List<FoldingRegion> foldingRegions;
  
  /// 构造函数
  const EditorCore({
    Key? key,
    required this.text,
    required this.controller,
    required this.language,
    this.filePath,
    this.readOnly = false,
    this.onTextChanged,
    this.onCursorPositionChanged,
    this.onSelectionChanged,
    required this.scrollController,
    required this.foldingRegions,
  }) : super(key: key);
  
  @override
  ConsumerState<EditorCore> createState() => _EditorCoreState();
}

class _EditorCoreState extends ConsumerState<EditorCore> {
  late FocusNode _focusNode;
  late TextSelection _selection;
  int _cursorLine = 1;
  int _cursorColumn = 1;
  bool _isInitialized = false;
  final CodeFoldingManager _foldingManager = CodeFoldingManager();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _selection = const TextSelection.collapsed(offset: 0);
    
    // 监听文本变化
    widget.controller.addListener(_handleTextChanged);
    
    // 监听选择变化
    widget.controller.addListener(() {
      if (widget.controller.selection != _selection) {
        _handleSelectionChanged(widget.controller.selection);
      }
    });

    // 延迟初始化以避免构建时的状态更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        setState(() {
          _isInitialized = true;
        });
        _updateFoldingRegions();
      }
    });
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }
  
  void _updateFoldingRegions() {
    _foldingManager.analyzeFoldingRegions(widget.text, widget.language);
    setState(() {});
  }
  
  void toggleFold(int lineNumber) {
    setState(() {
      _foldingManager.toggleFold(lineNumber);
      final text = _getVisibleText();
      widget.controller.value = TextEditingValue(
        text: text,
        selection: widget.controller.selection,
      );
    });
  }
  
  String _getVisibleText() {
    final lines = widget.text.split('\n');
    final visibleLines = <String>[];
    
    for (var i = 0; i < lines.length; i++) {
      if (_foldingManager.isLineFolded(i)) {
        continue;
      }
      
      final foldedLine = _foldingManager.getFoldedLine(i);
      if (foldedLine.isNotEmpty) {
        visibleLines.add(foldedLine);
      } else {
        visibleLines.add(lines[i]);
      }
    }
    
    return visibleLines.join('\n');
  }
  
  void _handleTextChanged() {
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(widget.controller.text);
    }
    _updateCursorPosition();
    _updateFoldingRegions();
  }
  
  void _updateCursorPosition() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    if (selection.isValid) {
      int line = 1;
      int column = 1;
      
      for (var i = 0; i < selection.baseOffset; i++) {
        if (i >= text.length) break;
        
        if (text[i] == '\n') {
          line++;
          column = 1;
        } else {
          column++;
        }
      }
      
      setState(() {
        _cursorLine = line;
        _cursorColumn = column;
      });
      
      if (widget.onCursorPositionChanged != null) {
        widget.onCursorPositionChanged!(_cursorLine, _cursorColumn);
      }
    }
  }
  
  void _handleSelectionChanged(TextSelection selection) {
    setState(() {
      _selection = selection;
    });
    
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(selection);
    }
    
    _updateCursorPosition();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: widget.scrollController,
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.tab) {
                    final currentText = widget.controller.text;
                    final selection = widget.controller.selection;
                    final newText = currentText.replaceRange(
                      selection.start,
                      selection.end,
                      '  ',
                    );
                    widget.controller.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: selection.baseOffset + 2,
                      ),
                    );
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    final currentText = widget.controller.text;
                    final selection = widget.controller.selection;
                    
                    // 获取当前行的缩进
                    final textBeforeCursor = currentText.substring(0, selection.start);
                    final lastNewLineIndex = textBeforeCursor.lastIndexOf('\n');
                    final currentLine = lastNewLineIndex == -1
                        ? textBeforeCursor
                        : textBeforeCursor.substring(lastNewLineIndex + 1);
                    
                    // 计算缩进
                    String indent = '';
                    for (int i = 0; i < currentLine.length; i++) {
                      if (currentLine[i] == ' ' || currentLine[i] == '\t') {
                        indent += currentLine[i];
                      } else {
                        break;
                      }
                    }
                    
                    // 检查是否需要增加缩进（如果当前行以'{'结尾）
                    if (currentLine.trim().endsWith('{')) {
                      indent += '  ';
                    }
                    
                    // 插入换行和缩进
                    final newText = currentText.replaceRange(
                      selection.start,
                      selection.end,
                      '\n$indent',
                    );
                    widget.controller.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: selection.baseOffset + indent.length + 1,
                      ),
                    );
                  }
                }
              },
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                readOnly: widget.readOnly,
                onTap: _updateCursorPosition,
                onTapOutside: (_) => _focusNode.unfocus(),
                cursorColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  if (widget.onTextChanged != null) {
                    widget.onTextChanged!(value);
                  }
                  _updateCursorPosition();
                  _updateFoldingRegions();
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _buildFoldingColumn(),
          ),
        ],
      ),
    );
  }

  void _initializeFolding() {
    // 分析代码并找出可折叠区域
    _foldingManager.analyzeFoldingRegions(widget.controller.text, widget.language ?? 'text');
  }

  void _updateFolding() {
    // 重新分析代码折叠区域
    _foldingManager.analyzeFoldingRegions(widget.controller.text, widget.language ?? 'text');
    setState(() {});
  }

  Widget _buildFoldingColumn() {
    return SizedBox(
      width: 12,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.text.split('\n').length,
        itemBuilder: (context, index) {
          for (final region in _foldingManager.regions) {
            if (region.startLine == index) {
              return GestureDetector(
                onTap: () => toggleFold(index),
                child: Icon(
                  region.isFolded ? Icons.chevron_right : Icons.expand_more,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              );
            }
          }
          return const SizedBox(height: 21); // 行高
        },
      ),
    );
  }
}

class SyntaxHighlightPainter extends CustomPainter {
  final String text;
  final String language;
  final Map<String, TextStyle> theme;
  final TextStyle textStyle;

  SyntaxHighlightPainter({
    required this.text,
    required this.language,
    required this.theme,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: _buildHighlightedSpans(),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);
    textPainter.paint(canvas, Offset.zero);
  }

  List<TextSpan> _buildHighlightedSpans() {
    final result = highlight.parse(text, language: language);
    final nodes = result.nodes;

    if (nodes == null) {
      return [TextSpan(text: text, style: textStyle)];
    }

    return nodes.map((node) {
      final style = theme[node.className] ?? textStyle;
      return TextSpan(text: node.value, style: style);
    }).toList();
  }

  @override
  bool shouldRepaint(covariant SyntaxHighlightPainter oldDelegate) {
    return text != oldDelegate.text ||
           language != oldDelegate.language ||
           theme != oldDelegate.theme ||
           textStyle != oldDelegate.textStyle;
  }
} 