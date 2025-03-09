import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/services/core/language_support.dart';
import 'package:xewo/src/services/editor/performance_service.dart';
import 'package:xewo/src/services/editor/indentation_service.dart';
import 'package:xewo/src/services/editor/bracket_matching_service.dart';
import 'package:xewo/src/services/editor/refactoring_service.dart';

/// 高级编辑器核心组件
class AdvancedEditorCore extends ConsumerStatefulWidget {
  /// 文本内容
  final String text;
  
  /// 文本控制器
  final TextEditingController? controller;
  
  /// 语言
  final String language;
  
  /// 文件路径
  final String? filePath;
  
  /// 只读模式
  final bool readOnly;
  
  /// 文本变化回调
  final Function(String)? onTextChanged;
  
  /// 光标位置变化回调
  final Function(int)? onCursorPositionChanged;
  
  /// 构造函数
  const AdvancedEditorCore({
    Key? key,
    required this.text,
    this.controller,
    required this.language,
    this.filePath,
    this.readOnly = false,
    this.onTextChanged,
    this.onCursorPositionChanged,
  }) : super(key: key);
  
  @override
  ConsumerState<AdvancedEditorCore> createState() => _AdvancedEditorCoreState();
}

class _AdvancedEditorCoreState extends ConsumerState<AdvancedEditorCore> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  
  // 性能优化相关
  List<String>? _lines;
  int _startLine = 0;
  int _endLine = 0;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  
  // 高亮相关
  String _highlightedText = '';
  
  // 括号匹配相关
  List<int> _bracketHighlightPositions = [];
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.text);
    
    // 添加文本变化监听
    _controller.addListener(_onTextChanged);
    
    // 初始化文本
    _initializeText(widget.text);
    
    // 添加滚动监听
    _verticalScrollController.addListener(_onScroll);
  }
  
  @override
  void didUpdateWidget(AdvancedEditorCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      _controller = widget.controller ?? TextEditingController(text: widget.text);
      _controller.addListener(_onTextChanged);
    }
    
    if (widget.text != oldWidget.text && widget.text != _controller.text) {
      _initializeText(widget.text);
    }
    
    if (widget.language != oldWidget.language) {
      _updateHighlightedText();
    }
  }
  
  @override
  void dispose() {
    // 先移除监听器，再释放资源
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    
    // 确保FocusNode正确释放
    _focusNode.dispose();
    
    // 确保ScrollController正确释放
    if (_verticalScrollController.hasClients) {
      _verticalScrollController.removeListener(_onScroll);
    }
    _verticalScrollController.dispose();
    
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.removeListener(() {});
    }
    _horizontalScrollController.dispose();
    
    super.dispose();
  }
  
  /// 初始化文本
  Future<void> _initializeText(String text) async {
    final performanceService = ref.read(performanceServiceProvider);
    
    // 使用性能服务分块加载文本
    _lines = await performanceService.loadTextInChunks(text);
    
    // 更新可见行
    _updateVisibleLines();
    
    // 更新高亮文本
    _updateHighlightedText();
    
    setState(() {});
  }
  
  /// 文本变化处理
  void _onTextChanged() {
    final performanceService = ref.read(performanceServiceProvider);
    
    // 获取当前文本
    final text = _controller.text;
    
    // 通知外部文本变化
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(text);
    }
    
    // 获取光标位置
    final selection = _controller.selection;
    if (selection.isValid && selection.isCollapsed) {
      // 通知外部光标位置变化
      if (widget.onCursorPositionChanged != null) {
        widget.onCursorPositionChanged!(selection.baseOffset);
      }
      
      // 更新括号高亮
      _updateBracketHighlight(selection.baseOffset);
    }
    
    // 增量更新文本行
    if (_lines != null) {
      _lines = text.split('\n');
      _updateVisibleLines();
      _updateHighlightedText();
    }
  }
  
  /// 滚动处理
  void _onScroll() {
    _updateVisibleLines();
    _updateHighlightedText();
  }
  
  /// 更新可见行
  void _updateVisibleLines() {
    if (_lines == null || _lines!.isEmpty) return;
    
    final performanceService = ref.read(performanceServiceProvider);
    
    // 计算可见行范围
    final scrollPosition = _verticalScrollController.position;
    final lineHeight = 20.0; // 估计的行高
    
    final firstVisibleLine = (scrollPosition.pixels / lineHeight).floor();
    final lastVisibleLine = ((scrollPosition.pixels + scrollPosition.viewportDimension) / lineHeight).ceil();
    
    // 获取可见行，并添加缓冲区
    final visibleLines = performanceService.getVisibleLines(
      _lines!,
      Math.max(0, firstVisibleLine - 50),
      Math.min(_lines!.length, lastVisibleLine + 50),
    );
    
    _startLine = Math.max(0, firstVisibleLine - 50);
    _endLine = Math.min(_lines!.length, lastVisibleLine + 50);
    
    setState(() {});
  }
  
  /// 更新高亮文本
  void _updateHighlightedText() {
    if (_lines == null) return;
    
    final languageSupport = ref.read(languageSupportProvider);
    
    // 获取可见文本
    final visibleText = _lines!.sublist(
      _startLine,
      Math.min(_lines!.length, _endLine),
    ).join('\n');
    
    // 应用语法高亮
    _highlightedText = languageSupport.highlightSyntax(visibleText, widget.language);
    
    setState(() {});
  }
  
  /// 更新括号高亮
  void _updateBracketHighlight(int cursorPosition) {
    final bracketMatchingService = ref.read(bracketMatchingServiceProvider);
    
    if (!bracketMatchingService.isEnabled()) {
      _bracketHighlightPositions = [];
      return;
    }
    
    // 获取高亮位置
    _bracketHighlightPositions = bracketMatchingService.getHighlightPositions(
      _controller.text,
      cursorPosition,
    );
    
    setState(() {});
  }
  
  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
    
    final indentationService = ref.read(indentationServiceProvider);
    final bracketMatchingService = ref.read(bracketMatchingServiceProvider);
    
    // 获取当前文本和光标位置
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (!selection.isValid) return KeyEventResult.ignored;
    
    // 处理回车键
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final newText = indentationService.handleEnterPressed(
        text,
        selection.baseOffset,
        widget.language,
      );
      
      // 计算新的光标位置
      final newCursorPosition = newText.length - text.length + selection.baseOffset;
      
      // 更新文本和光标位置
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
      
      return KeyEventResult.handled;
    }
    
    // 处理Tab键
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final shiftPressed = event.isShiftPressed;
      
      final newText = indentationService.handleTabPressed(
        text,
        selection.baseOffset,
        shiftPressed,
      );
      
      // 计算新的光标位置
      final cursorOffset = shiftPressed ? -2 : 2; // 假设缩进是2个空格
      final newCursorPosition = Math.max(0, selection.baseOffset + cursorOffset);
      
      // 更新文本和光标位置
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
      
      return KeyEventResult.handled;
    }
    
    // 处理括号输入
    final char = event.character;
    if (char != null && (char == '(' || char == '[' || char == '{' || char == '"' || char == "'" || char == '`')) {
      final newText = bracketMatchingService.handleBracketInput(
        text,
        selection.baseOffset,
        char,
      );
      
      // 更新文本和光标位置
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset + 1),
      );
      
      return KeyEventResult.handled;
    }
    
    // 处理退格键
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final newText = bracketMatchingService.handleBackspace(
        text,
        selection.baseOffset,
      );
      
      // 更新文本和光标位置
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset - 1),
      );
      
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  /// 显示重构菜单
  void _showRefactoringMenu(BuildContext context, Offset position) {
    final refactoringService = ref.read(refactoringServiceProvider);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: RefactoringType.rename,
          child: const Text('重命名'),
        ),
        PopupMenuItem(
          value: RefactoringType.extractMethod,
          child: const Text('提取方法'),
        ),
        PopupMenuItem(
          value: RefactoringType.extractVariable,
          child: const Text('提取变量'),
        ),
        PopupMenuItem(
          value: RefactoringType.inlineVariable,
          child: const Text('内联变量'),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case RefactoringType.rename:
          _showRenameDialog(context);
          break;
        case RefactoringType.extractMethod:
          _showExtractMethodDialog(context);
          break;
        case RefactoringType.extractVariable:
          _showExtractVariableDialog(context);
          break;
        case RefactoringType.inlineVariable:
          _performInlineVariable();
          break;
        default:
          break;
      }
    });
  }
  
  /// 显示重命名对话框
  void _showRenameDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '新名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performRename(textController.text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 执行重命名操作
  Future<void> _performRename(String newName) async {
    if (newName.isEmpty || widget.filePath == null) return;
    
    final refactoringService = ref.read(refactoringServiceProvider);
    
    final result = await refactoringService.rename(
      _controller.text,
      _controller.selection.baseOffset,
      newName,
      widget.language,
      widget.filePath!,
    );
    
    if (result.success && result.newCode != null) {
      _controller.value = TextEditingValue(
        text: result.newCode!,
        selection: TextSelection.collapsed(
          offset: result.newCursorPosition ?? _controller.selection.baseOffset,
        ),
      );
    } else if (!result.success && result.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
      }
    }
  }
  
  /// 显示提取方法对话框
  void _showExtractMethodDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提取方法'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '方法名',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performExtractMethod(textController.text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 执行提取方法操作
  Future<void> _performExtractMethod(String methodName) async {
    if (methodName.isEmpty || widget.filePath == null) return;
    
    final refactoringService = ref.read(refactoringServiceProvider);
    final selection = _controller.selection;
    
    if (!selection.isValid || selection.isCollapsed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择要提取的代码')),
        );
      }
      return;
    }
    
    final result = await refactoringService.extractMethod(
      _controller.text,
      selection.start,
      selection.end,
      methodName,
      widget.language,
      widget.filePath!,
    );
    
    if (result.success && result.newCode != null) {
      _controller.value = TextEditingValue(
        text: result.newCode!,
        selection: TextSelection.collapsed(
          offset: result.newCursorPosition ?? selection.baseOffset,
        ),
      );
    } else if (!result.success && result.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
      }
    }
  }
  
  /// 显示提取变量对话框
  void _showExtractVariableDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提取变量'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '变量名',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performExtractVariable(textController.text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 执行提取变量操作
  Future<void> _performExtractVariable(String variableName) async {
    if (variableName.isEmpty || widget.filePath == null) return;
    
    final refactoringService = ref.read(refactoringServiceProvider);
    final selection = _controller.selection;
    
    if (!selection.isValid || selection.isCollapsed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择要提取的表达式')),
        );
      }
      return;
    }
    
    final result = await refactoringService.extractVariable(
      _controller.text,
      selection.start,
      selection.end,
      variableName,
      widget.language,
      widget.filePath!,
    );
    
    if (result.success && result.newCode != null) {
      _controller.value = TextEditingValue(
        text: result.newCode!,
        selection: TextSelection.collapsed(
          offset: result.newCursorPosition ?? selection.baseOffset,
        ),
      );
    } else if (!result.success && result.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
      }
    }
  }
  
  /// 执行内联变量操作
  Future<void> _performInlineVariable() async {
    if (widget.filePath == null) return;
    
    final refactoringService = ref.read(refactoringServiceProvider);
    
    final result = await refactoringService.inlineVariable(
      _controller.text,
      _controller.selection.baseOffset,
      widget.language,
      widget.filePath!,
    );
    
    if (result.success && result.newCode != null) {
      _controller.value = TextEditingValue(
        text: result.newCode!,
        selection: TextSelection.collapsed(
          offset: result.newCursorPosition ?? _controller.selection.baseOffset,
        ),
      );
    } else if (!result.success && result.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 如果文本行尚未加载完成，显示加载指示器
    if (_lines == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return GestureDetector(
      onSecondaryTapDown: (details) {
        // 显示重构菜单
        _showRefactoringMenu(context, details.globalPosition);
      },
      child: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              width: MediaQuery.of(context).size.width - 50, // 提供有限宽度约束
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                readOnly: widget.readOnly,
                enableInteractiveSelection: true,
                buildCounter: (
                  BuildContext context, {
                  required int currentLength,
                  required bool isFocused,
                  required int? maxLength,
                }) {
                  return null;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Math工具类
class Math {
  static int max(int a, int b) => a > b ? a : b;
  static int min(int a, int b) => a < b ? a : b;
} 