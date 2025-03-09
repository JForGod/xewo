import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 扩展项
class ExtensionItem {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final bool isInstalled;
  
  const ExtensionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    this.isInstalled = false,
  });
}

/// 扩展屏幕
class ExtensionsScreen extends ConsumerStatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  ConsumerState<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends ConsumerState<ExtensionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<ExtensionItem> _extensions = [
    const ExtensionItem(
      id: 'dart-formatter',
      name: 'Dart格式化工具',
      description: '格式化Dart代码的工具',
      author: 'xEwo Team',
      version: '1.0.0',
      isInstalled: true,
    ),
    const ExtensionItem(
      id: 'flutter-snippets',
      name: 'Flutter代码片段',
      description: 'Flutter常用代码片段集合',
      author: 'xEwo Team',
      version: '1.0.0',
      isInstalled: true,
    ),
    const ExtensionItem(
      id: 'git-integration',
      name: 'Git集成',
      description: '集成Git版本控制功能',
      author: 'xEwo Team',
      version: '1.0.0',
      isInstalled: false,
    ),
    const ExtensionItem(
      id: 'theme-pack',
      name: '主题包',
      description: '多种编辑器主题',
      author: 'xEwo Team',
      version: '1.0.0',
      isInstalled: false,
    ),
    const ExtensionItem(
      id: 'code-analyzer',
      name: '代码分析器',
      description: '分析代码质量和性能',
      author: 'xEwo Team',
      version: '1.0.0',
      isInstalled: false,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扩展市场'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '已安装'),
            Tab(text: '市场'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索扩展',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 已安装的扩展
                _buildExtensionList(
                  _extensions.where((e) => 
                    e.isInstalled && 
                    (_searchQuery.isEmpty || 
                     e.name.toLowerCase().contains(_searchQuery) || 
                     e.description.toLowerCase().contains(_searchQuery))
                  ).toList(),
                ),
                
                // 市场扩展
                _buildExtensionList(
                  _extensions.where((e) => 
                    !e.isInstalled && 
                    (_searchQuery.isEmpty || 
                     e.name.toLowerCase().contains(_searchQuery) || 
                     e.description.toLowerCase().contains(_searchQuery))
                  ).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExtensionList(List<ExtensionItem> extensions) {
    if (extensions.isEmpty) {
      return Center(
        child: Text(
          '没有找到扩展',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.neutral600,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: extensions.length,
      itemBuilder: (context, index) {
        final extension = extensions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          child: ListTile(
            title: Text(extension.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(extension.description),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  '作者: ${extension.author} | 版本: ${extension.version}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
            trailing: extension.isInstalled
                ? TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('卸载'),
                    onPressed: () {
                      // TODO: 卸载扩展
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('卸载${extension.name}功能开发中')),
                      );
                    },
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('安装'),
                    onPressed: () {
                      // TODO: 安装扩展
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('安装${extension.name}功能开发中')),
                      );
                    },
                  ),
            isThreeLine: true,
            contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
          ),
        );
      },
    );
  }
} 