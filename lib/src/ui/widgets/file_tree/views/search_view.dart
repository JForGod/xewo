import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/providers/file_tree_provider.dart';
import '../../../../models/file_node.dart';
import '../../common/loading_indicator.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
        ref.read(fileTreeProvider.notifier).searchFiles(query);
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(fileTreeProvider);

    return Column(
      children: [
        // 搜索输入框
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: '搜索文件...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(fileTreeProvider.notifier).clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                _handleSearch(value);
              } else if (value.isEmpty) {
                ref.read(fileTreeProvider.notifier).clearSearch();
              }
            },
          ),
        ),

        // 搜索结果
        Expanded(
          child: _isSearching
              ? const Center(child: LoadingIndicator())
              : state.searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? '输入关键词开始搜索'
                            : '没有找到匹配的文件',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) {
                        final file = state.searchResults[index];
                        return ListTile(
                          leading: Icon(
                            file.type == FileNodeType.directory
                                ? Icons.folder
                                : Icons.insert_drive_file,
                            color: file.type == FileNodeType.directory
                                ? Colors.amber
                                : theme.colorScheme.onSurface,
                          ),
                          title: Text(file.name),
                          subtitle: Text(
                            file.path,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          onTap: () {
                            if (file.type == FileNodeType.directory) {
                              ref.read(fileTreeProvider.notifier).toggleNodeExpansion(file.path);
                            } else {
                              ref.read(fileTreeProvider.notifier).selectFile(file.path);
                            }
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
