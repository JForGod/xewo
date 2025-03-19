import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 查找替换对话框
class FindReplaceDialog extends StatefulWidget {
  /// 初始文本
  final String initialText;
  
  /// 是否显示替换选项
  final bool showReplace;
  
  /// 查找回调
  final void Function(String pattern, bool caseSensitive, bool wholeWord) onFind;
  
  /// 替换回调
  final void Function(String pattern, String replacement, bool caseSensitive, bool wholeWord) onReplace;

  const FindReplaceDialog({
    super.key,
    required this.initialText,
    this.showReplace = false,
    required this.onFind,
    required this.onReplace,
  });

  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog> {
  late TextEditingController _findController;
  late TextEditingController _replaceController;
  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _useRegex = false;
  
  // 查找结果
  List<int> _matchPositions = [];
  int _currentMatchIndex = -1;
  String _currentText = '';
  
  @override
  void initState() {
    super.initState();
    _findController = TextEditingController();
    _replaceController = TextEditingController();
    _currentText = widget.initialText;
    
    // 添加监听器，当查找文本变化时重新搜索
    _findController.addListener(_updateSearch);
  }
  
  @override
  void dispose() {
    _findController.removeListener(_updateSearch);
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }
  
  // 更新搜索结果
  void _updateSearch() {
    if (_findController.text.isEmpty) {
      setState(() {
        _matchPositions = [];
        _currentMatchIndex = -1;
      });
      return;
    }
    
    final pattern = _getSearchPattern();
    final matches = pattern.allMatches(_currentText);
    
    setState(() {
      _matchPositions = matches.map((m) => m.start).toList();
      _currentMatchIndex = _matchPositions.isNotEmpty ? 0 : -1;
    });
  }
  
  // 获取搜索模式
  RegExp _getSearchPattern() {
    String pattern = _findController.text;
    
    if (!_useRegex) {
      pattern = RegExp.escape(pattern);
    }
    
    if (_wholeWord) {
      pattern = '\\b$pattern\\b';
    }
    
    return RegExp(pattern, caseSensitive: _caseSensitive);
  }
  
  // 查找下一个
  void _findNext() {
    if (_matchPositions.isEmpty) return;
    
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
    });
  }
  
  // 查找上一个
  void _findPrevious() {
    if (_matchPositions.isEmpty) return;
    
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matchPositions.length) % _matchPositions.length;
    });
  }
  
  // 替换当前匹配
  void _replaceCurrent() {
    if (_currentMatchIndex == -1 || _matchPositions.isEmpty) return;
    
    final pattern = _getSearchPattern();
    final startPos = _matchPositions[_currentMatchIndex];
    final match = pattern.firstMatch(_currentText.substring(startPos));
    
    if (match != null) {
      final endPos = startPos + match.end;
      final newText = _currentText.substring(0, startPos) +
                      _replaceController.text +
                      _currentText.substring(endPos);
      
      setState(() {
        _currentText = newText;
      });
      
      // 更新搜索结果
      _updateSearch();
    }
  }
  
  // 替换所有匹配
  void _replaceAll() {
    if (_findController.text.isEmpty) return;
    
    final pattern = _getSearchPattern();
    final newText = _currentText.replaceAll(pattern, _replaceController.text);
    
    setState(() {
      _currentText = newText;
    });
    
    // 更新搜索结果
    _updateSearch();
  }
  
  // 完成替换
  void _finishReplace() {
    widget.onReplace(_getSearchPattern().pattern, _replaceController.text, _caseSensitive, _wholeWord);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.showReplace ? '查找和替换' : '查找'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 查找输入框
            TextField(
              controller: _findController,
              decoration: InputDecoration(
                labelText: '查找',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _findController.clear();
                  },
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            
            // 替换输入框
            if (widget.showReplace) ...[
              TextField(
                controller: _replaceController,
                decoration: InputDecoration(
                  labelText: '替换为',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _replaceController.clear();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // 搜索选项
            Wrap(
              spacing: 16,
              children: [
                // 区分大小写
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _caseSensitive,
                      onChanged: (value) {
                        setState(() {
                          _caseSensitive = value ?? false;
                        });
                        _updateSearch();
                      },
                    ),
                    const Text('区分大小写'),
                  ],
                ),
                
                // 全词匹配
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _wholeWord,
                      onChanged: (value) {
                        setState(() {
                          _wholeWord = value ?? false;
                        });
                        _updateSearch();
                      },
                    ),
                    const Text('全词匹配'),
                  ],
                ),
                
                // 使用正则表达式
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _useRegex,
                      onChanged: (value) {
                        setState(() {
                          _useRegex = value ?? false;
                        });
                        _updateSearch();
                      },
                    ),
                    const Text('正则表达式'),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 匹配信息
            Text(
              _matchPositions.isEmpty
                  ? '未找到匹配项'
                  : '找到 ${_matchPositions.length} 个匹配项${_currentMatchIndex >= 0 ? '，当前第 ${_currentMatchIndex + 1} 个' : ''}',
              style: TextStyle(
                color: _matchPositions.isEmpty ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 查找按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _matchPositions.isEmpty ? null : _findPrevious,
              tooltip: '上一个',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: _matchPositions.isEmpty ? null : _findNext,
              tooltip: '下一个',
            ),
          ],
        ),
        
        // 替换按钮
        if (widget.showReplace) ...[
          TextButton(
            onPressed: _currentMatchIndex == -1 ? null : _replaceCurrent,
            child: const Text('替换'),
          ),
          TextButton(
            onPressed: _matchPositions.isEmpty ? null : _replaceAll,
            child: const Text('全部替换'),
          ),
        ],
        
        // 完成按钮
        TextButton(
          onPressed: () {
            if (widget.showReplace) {
              _finishReplace();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.showReplace ? '完成' : '关闭'),
        ),
      ],
    );
  }
} 