import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../src/state/search_state.dart';
import '../../../../src/utils/theme_utils.dart';

/// 搜索栏组件
class SearchBar extends StatefulWidget {
  /// 搜索回调
  final Function(String)? onSearch;
  
  /// 替换回调
  final Function(String, String)? onReplace;
  
  /// 替换全部回调
  final Function(String, String)? onReplaceAll;
  
  /// 关闭回调
  final VoidCallback? onClose;
  
  /// 构造函数
  const SearchBar({
    Key? key,
    this.onSearch,
    this.onReplace,
    this.onReplaceAll,
    this.onClose,
  }) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  /// 搜索文本控制器
  late TextEditingController _searchController;
  
  /// 替换文本控制器
  late TextEditingController _replaceController;
  
  @override
  void initState() {
    super.initState();
    
    final searchState = Provider.of<SearchState>(context, listen: false);
    
    _searchController = TextEditingController(text: searchState.searchText);
    _replaceController = TextEditingController(text: searchState.replaceText);
    
    _searchController.addListener(() {
      searchState.searchText = _searchController.text;
    });
    
    _replaceController.addListener(() {
      searchState.replaceText = _replaceController.text;
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchState>(
      builder: (context, searchState, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索栏
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        if (widget.onSearch != null) {
                          widget.onSearch!(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: '搜索',
                    onPressed: () {
                      if (widget.onSearch != null) {
                        widget.onSearch!(_searchController.text);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: '上一个',
                    onPressed: () {
                      searchState.selectPreviousResult();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: '下一个',
                    onPressed: () {
                      searchState.selectNextResult();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      }
                    },
                  ),
                ],
              ),
              
              // 替换栏
              if (searchState.showReplacePanel) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replaceController,
                        decoration: InputDecoration(
                          hintText: '替换',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _replaceController.clear();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.onReplace != null) {
                          widget.onReplace!(
                            _searchController.text,
                            _replaceController.text,
                          );
                        }
                      },
                      child: const Text('替换'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.onReplaceAll != null) {
                          widget.onReplaceAll!(
                            _searchController.text,
                            _replaceController.text,
                          );
                        }
                      },
                      child: const Text('全部替换'),
                    ),
                  ],
                ),
              ],
              
              // 搜索选项
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: searchState.caseSensitive,
                    onChanged: (value) {
                      searchState.caseSensitive = value ?? false;
                    },
                  ),
                  const Text('区分大小写'),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: searchState.useRegex,
                    onChanged: (value) {
                      searchState.useRegex = value ?? false;
                    },
                  ),
                  const Text('正则表达式'),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: searchState.wholeWord,
                    onChanged: (value) {
                      searchState.wholeWord = value ?? false;
                    },
                  ),
                  const Text('全字匹配'),
                  const Spacer(),
                  Text(
                    searchState.searchResults.isEmpty
                        ? '无匹配项'
                        : '${searchState.selectedResultIndex + 1}/${searchState.searchResults.length}',
                    style: TextStyle(
                      color: getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
} 