import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/editor/snippet_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';

/// 代码片段管理屏幕
class SnippetsScreen extends ConsumerStatefulWidget {
  const SnippetsScreen({super.key});

  @override
  ConsumerState<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends ConsumerState<SnippetsScreen> {
  String _searchQuery = '';
  String? _selectedLanguage;
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _languages = [
    'SQL',
    'Dart',
    'JavaScript',
    'Python',
    'HTML',
    'CSS',
    'JSON',
    'XML',
    'Markdown',
  ];
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snippetsAsync = ref.watch(snippetServiceProvider.select((service) => service.getAllSnippets()));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('代码片段管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加新片段',
            onPressed: () => _showAddEditSnippetDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: snippetsAsync.when(
              data: (snippets) {
                // 过滤片段
                final filteredSnippets = snippets.where((snippet) {
                  final matchesSearch = _searchQuery.isEmpty || 
                      snippet.name.toLowerCase().contains(_searchQuery) ||
                      snippet.description.toLowerCase().contains(_searchQuery) ||
                      snippet.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
                  
                  final matchesLanguage = _selectedLanguage == null || 
                      snippet.language == _selectedLanguage;
                  
                  return matchesSearch && matchesLanguage;
                }).toList();
                
                if (filteredSnippets.isEmpty) {
                  return const EmptyState(
                    icon: Icons.code,
                    title: '没有找到代码片段',
                    message: '尝试更改搜索条件或添加新的代码片段',
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: filteredSnippets.length,
                  itemBuilder: (context, index) {
                    final snippet = filteredSnippets[index];
                    return _buildSnippetCard(snippet);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stackTrace) => Center(
                child: Text('加载代码片段时出错: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: '搜索代码片段',
              hintText: '按名称、描述或标签搜索',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: FilterChip(
                    label: const Text('全部'),
                    selected: _selectedLanguage == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedLanguage = null;
                        });
                      }
                    },
                  ),
                ),
                ..._languages.map((language) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                    child: FilterChip(
                      label: Text(language),
                      selected: _selectedLanguage == language,
                      onSelected: (selected) {
                        setState(() {
                          _selectedLanguage = selected ? language : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSnippetCard(CodeSnippet snippet) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: ExpansionTile(
        title: Text(snippet.name),
        subtitle: Text(snippet.description),
        leading: _getLanguageIcon(snippet.language),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: '编辑',
              onPressed: () => _showAddEditSnippetDialog(context, snippet: snippet),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              tooltip: '删除',
              onPressed: () => _showDeleteConfirmDialog(context, snippet),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    snippet.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingXs,
                  children: snippet.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('复制'),
                      onPressed: () {
                        // TODO: 复制代码片段到剪贴板
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('代码片段已复制到剪贴板')),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('插入'),
                      onPressed: () {
                        // TODO: 插入代码片段到编辑器
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('代码片段插入功能开发中')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _getLanguageIcon(String language) {
    IconData iconData;
    Color iconColor;
    
    switch (language.toLowerCase()) {
      case 'sql':
        iconData = Icons.storage;
        iconColor = Colors.blue;
        break;
      case 'dart':
        iconData = Icons.code;
        iconColor = Colors.teal;
        break;
      case 'javascript':
        iconData = Icons.javascript;
        iconColor = Colors.amber;
        break;
      case 'python':
        iconData = Icons.code;
        iconColor = Colors.green;
        break;
      case 'html':
        iconData = Icons.html;
        iconColor = Colors.orange;
        break;
      case 'css':
        iconData = Icons.css;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.code;
        iconColor = Colors.grey;
    }
    
    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }
  
  void _showAddEditSnippetDialog(BuildContext context, {CodeSnippet? snippet}) {
    final isEditing = snippet != null;
    final nameController = TextEditingController(text: isEditing ? snippet.name : '');
    final descriptionController = TextEditingController(text: isEditing ? snippet.description : '');
    final codeController = TextEditingController(text: isEditing ? snippet.code : '');
    final tagsController = TextEditingController(text: isEditing ? snippet.tags.join(', ') : '');
    String selectedLanguage = isEditing ? snippet.language : _languages.first;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? '编辑代码片段' : '添加代码片段'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        hintText: '输入代码片段名称',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '输入代码片段描述',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: '语言',
                      ),
                      items: _languages.map((language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      controller: codeController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: '代码',
                        hintText: '输入代码片段内容',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: '标签',
                        hintText: '输入标签，用逗号分隔',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(isEditing ? '保存' : '添加'),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final description = descriptionController.text.trim();
                    final code = codeController.text;
                    final tags = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                    
                    if (name.isEmpty || code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('名称和代码不能为空')),
                      );
                      return;
                    }
                    
                    final snippetService = ref.read(snippetServiceProvider);
                    
                    if (isEditing) {
                      final updatedSnippet = CodeSnippet(
                        id: snippet.id,
                        name: name,
                        description: description,
                        code: code,
                        language: selectedLanguage,
                        tags: tags,
                        createdAt: snippet.createdAt,
                        updatedAt: DateTime.now(),
                      );
                      
                      snippetService.updateSnippet(updatedSnippet);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('代码片段已更新')),
                      );
                    } else {
                      final newSnippet = CodeSnippet(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        description: description,
                        code: code,
                        language: selectedLanguage,
                        tags: tags,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      
                      snippetService.addSnippet(newSnippet);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('代码片段已添加')),
                      );
                    }
                    
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showDeleteConfirmDialog(BuildContext context, CodeSnippet snippet) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除代码片段'),
          content: Text('确定要删除代码片段"${snippet.name}"吗？此操作不可撤销。'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('删除'),
              onPressed: () {
                final snippetService = ref.read(snippetServiceProvider);
                snippetService.deleteSnippet(snippet.id);
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('代码片段已删除')),
                );
              },
            ),
          ],
        );
      },
    );
  }
} 