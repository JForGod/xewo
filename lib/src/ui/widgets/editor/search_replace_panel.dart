import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchReplacePanel extends StatefulWidget {
  final String text;
  final Function(String) onTextChanged;
  final Function(String, String) onReplace;
  final Function(String, String) onReplaceAll;
  final VoidCallback onClose;
  final Function(String) onFind;
  final VoidCallback onFindNext;
  final VoidCallback onFindPrevious;

  const SearchReplacePanel({
    super.key,
    required this.text,
    required this.onTextChanged,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
    required this.onFind,
    required this.onFindNext,
    required this.onFindPrevious,
  });

  @override
  State<SearchReplacePanel> createState() => _SearchReplacePanelState();
}

class _SearchReplacePanelState extends State<SearchReplacePanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  bool _showReplace = false;
  bool _matchCase = false;
  bool _wholeWord = false;
  bool _useRegex = false;
  List<Match> _matches = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _findMatches();
  }

  void _findMatches() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
      });
      return;
    }
    
    // 实现查找逻辑
    // ...
  }

  void _findNext() {
    if (_matches.isEmpty) return;
    
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    
    // 滚动到当前匹配项
    // ...
  }

  void _findPrevious() {
    if (_matches.isEmpty) return;
    
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    
    // 滚动到当前匹配项
    // ...
  }

  void _replace() {
    if (_currentMatchIndex < 0 || _matches.isEmpty) return;
    
    final match = _matches[_currentMatchIndex];
    final newText = widget.text.replaceRange(
      match.start,
      match.end,
      _replaceController.text,
    );
    
    widget.onTextChanged(newText);
    
    // 更新匹配项
    _findMatches();
  }

  void _replaceAll() {
    if (_matches.isEmpty) return;
    
    String newText = widget.text;
    
    // 从后向前替换，以避免索引变化
    for (int i = _matches.length - 1; i >= 0; i--) {
      final match = _matches[i];
      newText = newText.replaceRange(
        match.start,
        match.end,
        _replaceController.text,
      );
    }
    
    widget.onTextChanged(newText);
    
    // 更新匹配项
    _findMatches();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  onChanged: widget.onFind,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: widget.onFindPrevious,
                tooltip: '查找上一个',
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: widget.onFindNext,
                tooltip: '查找下一个',
              ),
              IconButton(
                icon: Icon(_showReplace ? Icons.unfold_less : Icons.unfold_more),
                onPressed: () {
                  setState(() {
                    _showReplace = !_showReplace;
                  });
                },
                tooltip: _showReplace ? '隐藏替换' : '显示替换',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
                tooltip: '关闭',
              ),
            ],
          ),
          if (_showReplace) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      hintText: '替换为',
                      prefixIcon: const Icon(Icons.find_replace),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    widget.onReplace(
                      _searchController.text,
                      _replaceController.text,
                    );
                  },
                  child: const Text('替换'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    widget.onReplaceAll(
                      _searchController.text,
                      _replaceController.text,
                    );
                  },
                  child: const Text('全部替换'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildToggleButton(
                value: _matchCase,
                onChanged: (value) => setState(() => _matchCase = value),
                tooltip: '区分大小写',
                icon: const Text('Aa', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              _buildToggleButton(
                value: _wholeWord,
                onChanged: (value) => setState(() => _wholeWord = value),
                tooltip: '全字匹配',
                icon: const Text('ab', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              _buildToggleButton(
                value: _useRegex,
                onChanged: (value) => setState(() => _useRegex = value),
                tooltip: '使用正则表达式',
                icon: const Text('.*', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          if (_matches.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '找到 ${_matches.length} 个匹配项，当前第 ${_currentMatchIndex + 1} 个',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required bool value,
    required Function(bool) onChanged,
    required String tooltip,
    required Widget icon,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: value
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: icon,
        ),
      ),
    );
  }
} 