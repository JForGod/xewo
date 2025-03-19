import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/ui/widgets/editor/editor_core.dart';
import 'package:xewo/src/ui/widgets/editor/status_bar.dart';
import 'package:xewo/src/ui/widgets/editor/line_numbers.dart';
import 'package:xewo/src/ui/widgets/editor/minimap.dart';
import 'package:xewo/src/ui/themes/app_theme.dart';
import 'package:xewo/src/ui/widgets/editor/search_replace_panel.dart';
import 'package:xewo/src/ui/widgets/editor/code_folding.dart';
import 'dart:convert';
import 'dart:io';

/// 代码编辑器组件
class CodeEditor extends ConsumerStatefulWidget {
  /// 文本内容
  final String text;
  
  /// 文件路径
  final String filePath;
  
  /// 只读模式
  final bool readOnly;
  
  /// 显示行号
  final bool showLineNumbers;
  
  /// 显示小地图
  final bool showMinimap;
  
  /// 焦点节点
  final FocusNode focusNode;
  
  /// 文本变化回调
  final Function(String) onTextChanged;
  
  /// 光标位置变化回调
  final Function(int, int)? onCursorPositionChanged;
  
  /// 选择变化回调
  final Function(TextSelection)? onSelectionChanged;
  
  /// 行号切换回调
  final Function()? onToggleLineNumbers;
  
  /// 小地图切换回调
  final Function()? onToggleMinimap;
  
  /// 文件打开回调
  final Function(String)? onFileOpened;
  
  /// 构造函数
  const CodeEditor({
    Key? key,
    required this.text,
    required this.filePath,
    required this.readOnly,
    required this.showLineNumbers,
    required this.showMinimap,
    required this.focusNode,
    required this.onTextChanged,
    this.onCursorPositionChanged,
    this.onSelectionChanged,
    this.onToggleLineNumbers,
    this.onToggleMinimap,
    this.onFileOpened,
  }) : super(key: key);
  
  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  final CodeFoldingManager _foldingManager = CodeFoldingManager();
  late TextEditingController _controller;
  late ScrollController _editorScrollController;
  late ScrollController _lineNumbersScrollController;
  late ScrollController _minimapScrollController;
  int _cursorLine = 1;
  int _cursorColumn = 1;
  bool _isModified = false;
  bool _showSearchPanel = false;
  TextSelection? _currentSelection;
  bool _isScrolling = false;
  
  List<FoldingRegion> _foldingRegions = [];
  static const double _lineHeight = 24.0;
  String _language = 'plaintext';
  
  List<Match> _searchMatches = [];
  int _currentMatchIndex = -1;
  
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _editorScrollController = ScrollController();
    _lineNumbersScrollController = ScrollController();
    _minimapScrollController = ScrollController();
    
    // 同步滚动
    _editorScrollController.addListener(() {
      if (!_isScrolling) {
        _isScrolling = true;
        _syncScroll(_editorScrollController.offset);
        _isScrolling = false;
      }
    });
    
    // 分析代码结构以获取可折叠区域
    _analyzeFoldingRegions();
    _detectLanguage();
  }
  
  void _syncScroll(double offset) {
    if (_lineNumbersScrollController.hasClients) {
      _lineNumbersScrollController.jumpTo(offset);
    }
    if (_minimapScrollController.hasClients) {
      _minimapScrollController.jumpTo(offset / 2);
    }
  }
  
  void _analyzeFoldingRegions() {
    final lines = widget.text.split('\n');
    final regions = <FoldingRegion>[];
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测类定义
      if (line.startsWith('class ') || line.startsWith('abstract class ')) {
        final endLine = _findMatchingBrace(lines, i);
        if (endLine != -1) {
          regions.add(FoldingRegion(
            startLine: i + 1,
            endLine: endLine + 1,
            placeholder: '...',
          ));
        }
      }
      
      // 检测函数定义
      else if (line.contains('(') && line.contains(')') && line.endsWith('{')) {
        final endLine = _findMatchingBrace(lines, i);
        if (endLine != -1) {
          regions.add(FoldingRegion(
            startLine: i + 1,
            endLine: endLine + 1,
            placeholder: '...',
          ));
        }
      }
      
      // 检测其他代码块
      else if (line.endsWith('{')) {
        final endLine = _findMatchingBrace(lines, i);
        if (endLine != -1 && endLine > i + 2) { // 至少包含2行
          regions.add(FoldingRegion(
            startLine: i + 1,
            endLine: endLine + 1,
            placeholder: '...',
          ));
        }
      }
    }
    
    setState(() {
      _foldingRegions = regions;
    });
  }
  
  int _findMatchingBrace(List<String> lines, int startLine) {
    int braceCount = 0;
    
    for (var i = startLine; i < lines.length; i++) {
      final line = lines[i];
      braceCount += '{'.allMatches(line).length;
      braceCount -= '}'.allMatches(line).length;
      
      if (braceCount == 0) {
        return i;
      }
    }
    
    return -1;
  }
  
  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果文本内容发生变化，更新编辑器内容
    if (widget.text != oldWidget.text) {
      // 使用 Future.microtask 延迟状态更新
      Future.microtask(() {
        if (mounted) {
          _controller.text = widget.text;
        }
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _lineNumbersScrollController.dispose();
    _minimapScrollController.dispose();
    super.dispose();
  }
  
  /// 处理文本变化
  void _onTextChanged(String text) {
    // 使用 Future.microtask 延迟状态更新
    Future.microtask(() {
      if (mounted && widget.onTextChanged != null) {
        widget.onTextChanged(text);
      }
    });
  }
  
  /// 处理光标位置变化
  void _onCursorPositionChanged(int line, int column) {
    setState(() {
      _cursorLine = line;
      _cursorColumn = column;
    });
    widget.onCursorPositionChanged?.call(line, column);
  }
  
  /// 处理选择变化
  void _onSelectionChanged(TextSelection selection) {
    setState(() {
      _currentSelection = selection;
    });
    widget.onSelectionChanged?.call(selection);
  }
  
  /// 格式化代码
  void _formatCode() {
    final text = _controller.text;
    final formattedText = _formatCodeByLanguage(text, _language);
    if (formattedText != text) {
      setState(() {
        _controller.text = formattedText;
        widget.onTextChanged?.call(formattedText);
      });
    }
  }
  
  String _formatCodeByLanguage(String code, String language) {
    // TODO: 根据不同语言实现格式化
    switch (language.toLowerCase()) {
      case 'dart':
        return _formatDartCode(code);
      case 'json':
        return _formatJsonCode(code);
      default:
        return code;
    }
  }
  
  String _formatDartCode(String code) {
    // TODO: 使用dart_style包格式化Dart代码
    return code;
  }
  
  String _formatJsonCode(String code) {
    try {
      final jsonObj = jsonDecode(code);
      return jsonEncode(jsonObj);
    } catch (e) {
      return code;
    }
  }
  
  /// 查找替换
  void _showFindDialog() {
    setState(() {
      _showSearchPanel = true;
    });
  }
  
  /// 显示设置
  void _showReplaceDialog() {
    setState(() {
      _showSearchPanel = true;
    });
  }
  
  void _hideSearch() {
    setState(() {
      _showSearchPanel = false;
    });
  }
  
  void _handleFind(String searchText) {
    if (searchText.isEmpty) return;

    final text = _controller.text;
    final matches = RegExp(searchText).allMatches(text).toList();
    
    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isEmpty ? -1 : 0;
      if (matches.isNotEmpty) {
        _selectMatch(matches[0]);
      }
    });
  }
  
  void _handleSearch(String query) {
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // 使用 Future.microtask 延迟状态更新
    Future.microtask(() {
      if (mounted) {
        // TODO: 实现搜索功能
        setState(() {
          _isSearching = false;
        });
      }
    });
  }
  
  void _handleReplace(String searchText, String replaceText) {
    if (_currentSelection == null) return;
    
    final text = _controller.text;
    final start = _currentSelection!.start;
    final end = _currentSelection!.end;
    
    if (start < 0 || end > text.length) return;
    
    final newText = text.replaceRange(start, end, replaceText);
    setState(() {
      _controller.text = newText;
      widget.onTextChanged(newText);
    });
  }
  
  void _handleReplaceAll(String searchText, String replaceText) {
    final text = _controller.text;
    final newText = text.replaceAll(searchText, replaceText);
    setState(() {
      _controller.text = newText;
      widget.onTextChanged(newText);
    });
  }
  
  void _selectMatch(Match match) {
    final selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
    _controller.selection = selection;
  }
  
  void _findNext() {
    if (_searchMatches.isEmpty || _currentMatchIndex < 0) return;
    
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      _selectMatch(_searchMatches[_currentMatchIndex]);
    });
  }
  
  void _findPrevious() {
    if (_searchMatches.isEmpty || _currentMatchIndex < 0) return;
    
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
      _selectMatch(_searchMatches[_currentMatchIndex]);
    });
  }
  
  void _detectLanguage() {
    if (widget.filePath == null) return;
    
    final extension = widget.filePath!.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        _language = 'dart';
        break;
      case 'py':
      case 'pyw':
      case 'pyx':
        _language = 'python';
        break;
      case 'js':
        _language = 'javascript';
        break;
      case 'ts':
        _language = 'typescript';
        break;
      case 'html':
        _language = 'html';
        break;
      case 'css':
        _language = 'css';
        break;
      case 'json':
        _language = 'json';
        break;
      case 'yaml':
      case 'yml':
        _language = 'yaml';
        break;
      case 'md':
        _language = 'markdown';
        break;
      case 'sql':
        _language = 'sql';
        break;
      case 'sh':
      case 'bash':
        _language = 'bash';
        break;
      default:
        _language = 'plaintext';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showSearchPanel)
            SearchReplacePanel(
              text: widget.text,
              onTextChanged: widget.onTextChanged,
              onReplace: _handleReplace,
              onReplaceAll: _handleReplaceAll,
              onClose: _hideSearch,
              onFind: _handleFind,
              onFindNext: _findNext,
              onFindPrevious: _findPrevious,
            ),
          // 编辑区域
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 行号区域
                if (widget.showLineNumbers)
                  Container(
                    width: 40,
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.only(right: 4),
                    child: ListView.builder(
                      controller: _lineNumbersScrollController,
                      itemCount: widget.text.split('\n').length,
                      itemBuilder: (context, index) {
                        final region = _foldingRegions.firstWhere(
                          (r) => r.startLine == index + 1,
                          orElse: () => FoldingRegion(
                            startLine: -1,
                            endLine: -1,
                            placeholder: '',
                          ),
                        );
                        if (region.startLine != -1) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                // TODO: 实现折叠功能
                              });
                            },
                            child: Container(
                              height: 20,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 20);
                      },
                    ),
                  ),
                
                // 代码区域
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - (widget.showLineNumbers ? 40 : 0) - (widget.showMinimap ? 80 : 0),
                      child: EditorCore(
                        text: widget.text,
                        controller: _controller,
                        language: _language,
                        filePath: widget.filePath,
                        readOnly: widget.readOnly,
                        onTextChanged: _onTextChanged,
                        onCursorPositionChanged: _onCursorPositionChanged,
                        onSelectionChanged: _onSelectionChanged,
                        scrollController: _editorScrollController,
                        foldingRegions: _foldingRegions,
                      ),
                    ),
                  ),
                ),
                
                // 小地图
                if (widget.showMinimap)
                  SizedBox(
                    width: 80,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Center(
                        child: Text(
                          'Minimap',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 状态栏
          StatusBar(
            line: _cursorLine,
            column: _cursorColumn,
            language: _language,
          ),
        ],
      ),
    );
  }

  // 添加拖拽打开文件功能
  Widget _buildEditorWithDragDrop() {
    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return _buildEditor();
      },
      onAccept: (filePath) {
        // 处理文件拖拽
        if (filePath.isNotEmpty) {
          _openFile(filePath);
        }
      },
    );
  }

  // 构建编辑器
  Widget _buildEditor() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Stack(
        children: [
          // 编辑器核心
          EditorCore(
            text: widget.text,
            controller: _controller,
            language: _language,
            filePath: widget.filePath,
            readOnly: widget.readOnly,
            onTextChanged: (text) {
              widget.onTextChanged(text);
              _isModified = true;
            },
            onCursorPositionChanged: (line, column) {
              setState(() {
                _cursorLine = line;
                _cursorColumn = column;
              });
              widget.onCursorPositionChanged?.call(line, column);
            },
            onSelectionChanged: (selection) {
              setState(() {
                _currentSelection = selection;
              });
              widget.onSelectionChanged?.call(selection);
            },
            scrollController: _editorScrollController,
            foldingRegions: _foldingRegions,
          ),
          
          // 搜索面板
          if (_showSearchPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SearchReplacePanel(
                text: widget.text,
                onTextChanged: widget.onTextChanged,
                onReplace: _handleReplace,
                onReplaceAll: _handleReplaceAll,
                onClose: _hideSearch,
                onFind: _handleFind,
                onFindNext: _findNext,
                onFindPrevious: _findPrevious,
              ),
            ),
        ],
      ),
    );
  }

  // 打开文件
  void _openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        
        // 更新编辑器内容
        widget.onTextChanged(content);
        
        // 通知外部文件已打开
        if (widget.onFileOpened != null) {
          widget.onFileOpened!(filePath);
        }
        
        // 更新语言和折叠区域
        setState(() {
          // 检测语言
          _detectLanguage();
          
          // 分析折叠区域
          _analyzeFoldingRegions();
        });
      }
    } catch (e) {
      debugPrint('打开文件失败: $e');
    }
  }

  // 添加右键菜单
  Widget _buildEditorWithContextMenu() {
    return GestureDetector(
      onSecondaryTap: () {
        _showEditorContextMenu();
      },
      child: _buildEditorWithDragDrop(),
    );
  }

  void _showEditorContextMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'cut',
          child: ListTile(
            leading: Icon(Icons.content_cut),
            title: Text('剪切'),
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.content_copy),
            title: Text('复制'),
          ),
        ),
        PopupMenuItem(
          value: 'paste',
          child: ListTile(
            leading: Icon(Icons.content_paste),
            title: Text('粘贴'),
          ),
        ),
        PopupMenuItem(
          value: 'find',
          child: ListTile(
            leading: Icon(Icons.search),
            title: Text('查找'),
          ),
        ),
        PopupMenuItem(
          value: 'format',
          child: ListTile(
            leading: Icon(Icons.format_align_left),
            title: Text('格式化'),
          ),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value == null) return;
      
      switch (value) {
        case 'cut':
          // 实现剪切功能
          break;
        case 'copy':
          // 实现复制功能
          break;
        case 'paste':
          // 实现粘贴功能
          break;
        case 'find':
          _showFindDialog();
          break;
        case 'format':
          _formatCode();
          break;
      }
    });
  }
} 