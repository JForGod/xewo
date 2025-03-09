import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/search_history_provider.dart';
import '../../../services/file/file_service.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../../state/providers/editor_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// 文件搜索结果
class SearchResult {
  final String filePath;
  final String fileName;
  final bool isDirectory;
  final List<String> matchedLines;
  final List<int> matchedLineNumbers;

  SearchResult({
    required this.filePath,
    required this.fileName,
    required this.isDirectory,
    this.matchedLines = const [],
    this.matchedLineNumbers = const [],
  });
}

/// 文件搜索组件
class FileSearch extends ConsumerStatefulWidget {
  final String initialDirectory;
  final VoidCallback? onClose;

  const FileSearch({
    Key? key,
    required this.initialDirectory,
    this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<FileSearch> createState() => _FileSearchState();
}

class _FileSearchState extends ConsumerState<FileSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FileService _fileService = FileService();
  
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _error;
  bool _showSuggestions = false;
  
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
  
  // 执行搜索
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _error = null;
      _showSuggestions = false;
    });
    
    try {
      // 添加到搜索历史
      await ref.read(searchHistoryProvider.notifier).addSearch(query);
      
      // 执行搜索
      final results = await _searchFiles(widget.initialDirectory, query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = '搜索失败: $e';
      });
    }
  }
  
  // 搜索文件
  Future<List<SearchResult>> _searchFiles(String directory, String query) async {
    final results = <SearchResult>[];
    final entities = await _fileService.listDirectory(directory);
    
    for (final entity in entities) {
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        
        // 跳过隐藏目录和特定目录
        if (dirName.startsWith('.') || 
            ['node_modules', 'build', 'dist', '.git', '.dart_tool'].contains(dirName)) {
          continue;
        }
        
        // 如果目录名包含查询字符串，添加到结果
        if (dirName.toLowerCase().contains(query.toLowerCase())) {
          results.add(SearchResult(
            filePath: entity.path,
            fileName: dirName,
            isDirectory: true,
          ));
        }
        
        // 递归搜索子目录
        try {
          final subResults = await _searchFiles(entity.path, query);
          results.addAll(subResults);
        } catch (e) {
          // 忽略子目录搜索错误，继续搜索其他目录
        }
      } else if (entity is File) {
        final fileName = path.basename(entity.path);
        
        // 跳过隐藏文件和特定文件
        if (fileName.startsWith('.') || fileName.endsWith('.lock')) {
          continue;
        }
        
        // 如果文件名包含查询字符串，添加到结果
        if (fileName.toLowerCase().contains(query.toLowerCase())) {
          results.add(SearchResult(
            filePath: entity.path,
            fileName: fileName,
            isDirectory: false,
          ));
          continue;
        }
        
        // 检查文件内容是否包含查询字符串
        try {
          // 跳过二进制文件和大文件
          final extension = path.extension(entity.path).toLowerCase();
          if (_isBinaryFile(extension) || await entity.length() > 1024 * 1024) {
            continue;
          }
          
          final content = await _fileService.readFile(entity.path);
          final lines = content.split('\n');
          final matchedLines = <String>[];
          final matchedLineNumbers = <int>[];
          
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].toLowerCase().contains(query.toLowerCase())) {
              matchedLines.add(lines[i].trim());
              matchedLineNumbers.add(i + 1);
              
              // 限制匹配行数
              if (matchedLines.length >= 3) {
                break;
              }
            }
          }
          
          if (matchedLines.isNotEmpty) {
            results.add(SearchResult(
              filePath: entity.path,
              fileName: fileName,
              isDirectory: false,
              matchedLines: matchedLines,
              matchedLineNumbers: matchedLineNumbers,
            ));
          }
        } catch (e) {
          // 忽略文件读取错误，继续搜索其他文件
        }
      }
    }
    
    return results;
  }
  
  // 判断是否是二进制文件
  bool _isBinaryFile(String extension) {
    final binaryExtensions = [
      '.exe', '.dll', '.so', '.dylib', '.obj', '.o', '.a', '.lib',
      '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.webp',
      '.mp3', '.wav', '.ogg', '.mp4', '.avi', '.mov', '.webm',
      '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz',
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    ];
    return binaryExtensions.contains(extension);
  }
  
  // 打开文件
  Future<void> _openFile(String filePath) async {
    try {
      final content = await _fileService.readFile(filePath);
      ref.read(editorProvider.notifier).updateCurrentFile(filePath, content);
      
      if (widget.onClose != null) {
        widget.onClose!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开文件失败: $e')),
      );
    }
  }
  
  // 显示搜索建议
  void _showSearchSuggestions() {
    if (_searchController.text.isEmpty) {
      final history = ref.read(searchHistoryProvider).history;
      if (history.isNotEmpty) {
        setState(() {
          _showSuggestions = true;
        });
      }
    } else {
      final suggestions = ref.read(searchHistoryProvider.notifier).getSuggestions(_searchController.text);
      if (suggestions.isNotEmpty) {
        setState(() {
          _showSuggestions = true;
        });
      }
    }
  }
  
  // 隐藏搜索建议
  void _hideSearchSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchHistory = ref.watch(searchHistoryProvider);
    
    return Column(
      children: [
        // 搜索头部
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: '搜索文件和文件夹',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _error = null;
                              });
                              _showSearchSuggestions();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: _performSearch,
                  onTap: _showSearchSuggestions,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final suggestions = ref.read(searchHistoryProvider.notifier).getSuggestions(value);
                      setState(() {
                        _showSuggestions = suggestions.isNotEmpty;
                      });
                    } else {
                      _showSearchSuggestions();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  tooltip: '关闭搜索',
                ),
            ],
          ),
        ),
        
        // 搜索建议
        if (_showSuggestions)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchController.text.isEmpty
                  ? searchHistory.history.length
                  : ref.read(searchHistoryProvider.notifier).getSuggestions(_searchController.text).length,
              itemBuilder: (context, index) {
                final suggestion = _searchController.text.isEmpty
                    ? searchHistory.history[index]
                    : ref.read(searchHistoryProvider.notifier).getSuggestions(_searchController.text)[index];
                
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(suggestion),
                  dense: true,
                  onTap: () {
                    _searchController.text = suggestion;
                    _hideSearchSuggestions();
                    _performSearch(suggestion);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      ref.read(searchHistoryProvider.notifier).removeSearch(suggestion);
                    },
                    splashRadius: 16,
                    tooltip: '删除',
                  ),
                );
              },
            ),
          ),
        
        // 搜索结果
        Expanded(
          child: GestureDetector(
            onTap: _hideSearchSuggestions,
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? '输入关键字搜索文件和文件夹'
                                  : '未找到匹配的文件或文件夹',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return _buildSearchResultItem(result);
                            },
                          ),
          ),
        ),
      ],
    );
  }
  
  // 构建搜索结果项
  Widget _buildSearchResultItem(SearchResult result) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        result.isDirectory ? Icons.folder : Icons.insert_drive_file,
        color: result.isDirectory ? Colors.amber : theme.colorScheme.primary,
      ),
      title: Text(result.fileName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.filePath,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (!result.isDirectory && result.matchedLines.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...List.generate(result.matchedLines.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.matchedLineNumbers[i]}: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        result.matchedLines[i],
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
      onTap: () {
        if (result.isDirectory) {
          // 打开目录
          ref.read(fileTreeProvider.notifier).loadDirectory(result.filePath);
          if (widget.onClose != null) {
            widget.onClose!();
          }
        } else {
          // 打开文件
          _openFile(result.filePath);
        }
      },
    );
  }
} 