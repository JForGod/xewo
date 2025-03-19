import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/loading_indicator.dart';

class ExtensionsView extends ConsumerStatefulWidget {
  const ExtensionsView({super.key});

  @override
  ConsumerState<ExtensionsView> createState() => _ExtensionsViewState();
}

class _ExtensionsViewState extends ConsumerState<ExtensionsView> {
  bool _isLoading = false;
  List<Extension> _installedExtensions = [];
  List<Extension> _recommendedExtensions = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExtensions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadExtensions() async {
    setState(() {
      _isLoading = true;
    });

    // 模拟加载扩展
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isLoading = false;
      _installedExtensions = [
        Extension(
          id: 'dart-code.dart-code',
          name: 'Dart',
          publisher: 'Dart Code',
          description: 'Dart语言支持和调试器',
          version: '3.40.0',
          isInstalled: true,
          isEnabled: true,
          icon: Icons.code,
        ),
        Extension(
          id: 'dart-code.flutter',
          name: 'Flutter',
          publisher: 'Dart Code',
          description: 'Flutter框架支持和调试器',
          version: '3.40.0',
          isInstalled: true,
          isEnabled: true,
          icon: Icons.flutter_dash,
        ),
        Extension(
          id: 'xewo.theme',
          name: 'Xewo Theme',
          publisher: 'Xewo',
          description: 'Xewo编辑器默认主题',
          version: '1.0.0',
          isInstalled: true,
          isEnabled: true,
          icon: Icons.color_lens,
        ),
      ];

      _recommendedExtensions = [
        Extension(
          id: 'github.copilot',
          name: 'GitHub Copilot',
          publisher: 'GitHub',
          description: 'AI代码助手',
          version: '1.85.0',
          isInstalled: false,
          isEnabled: false,
          icon: Icons.smart_toy,
        ),
        Extension(
          id: 'esbenp.prettier-vscode',
          name: 'Prettier',
          publisher: 'Prettier',
          description: '代码格式化工具',
          version: '9.10.4',
          isInstalled: false,
          isEnabled: false,
          icon: Icons.format_align_left,
        ),
        Extension(
          id: 'dbaeumer.vscode-eslint',
          name: 'ESLint',
          publisher: 'Microsoft',
          description: 'JavaScript和TypeScript代码检查工具',
          version: '2.4.0',
          isInstalled: false,
          isEnabled: false,
          icon: Icons.rule,
        ),
      ];
    });
  }

  List<Extension> get _filteredInstalledExtensions {
    if (_searchQuery.isEmpty) return _installedExtensions;
    return _installedExtensions.where((ext) {
      return ext.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ext.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ext.publisher.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Extension> get _filteredRecommendedExtensions {
    if (_searchQuery.isEmpty) return _recommendedExtensions;
    return _recommendedExtensions.where((ext) {
      return ext.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ext.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ext.publisher.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索扩展...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),

        // 扩展列表
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: '已安装'),
                          Tab(text: '推荐'),
                        ],
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                        indicatorColor: theme.colorScheme.primary,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 已安装扩展
                            _filteredInstalledExtensions.isEmpty
                                ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? '没有已安装的扩展'
                                          : '没有找到匹配的扩展',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredInstalledExtensions.length,
                                    itemBuilder: (context, index) {
                                      final extension = _filteredInstalledExtensions[index];
                                      return _buildExtensionTile(extension, theme);
                                    },
                                  ),

                            // 推荐扩展
                            _filteredRecommendedExtensions.isEmpty
                                ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? '没有推荐的扩展'
                                          : '没有找到匹配的扩展',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredRecommendedExtensions.length,
                                    itemBuilder: (context, index) {
                                      final extension = _filteredRecommendedExtensions[index];
                                      return _buildExtensionTile(extension, theme);
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildExtensionTile(Extension extension, ThemeData theme) {
    return ListTile(
      leading: Icon(
        extension.icon,
        color: theme.colorScheme.primary,
      ),
      title: Row(
        children: [
          Text(extension.name),
          const SizedBox(width: 8),
          Text(
            extension.publisher,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(extension.description),
          const SizedBox(height: 4),
          Text(
            '版本: ${extension.version}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      trailing: extension.isInstalled
          ? IconButton(
              icon: Icon(
                extension.isEnabled ? Icons.toggle_on : Icons.toggle_off,
                color: extension.isEnabled ? theme.colorScheme.primary : null,
              ),
              onPressed: () {
                setState(() {
                  extension.isEnabled = !extension.isEnabled;
                });
              },
            )
          : ElevatedButton(
              onPressed: () {
                setState(() {
                  extension.isInstalled = true;
                  extension.isEnabled = true;
                  _installedExtensions.add(extension);
                  _recommendedExtensions.remove(extension);
                });
              },
              child: const Text('安装'),
            ),
      isThreeLine: true,
      dense: true,
    );
  }
}

class Extension {
  final String id;
  final String name;
  final String publisher;
  final String description;
  final String version;
  bool isInstalled;
  bool isEnabled;
  final IconData icon;

  Extension({
    required this.id,
    required this.name,
    required this.publisher,
    required this.description,
    required this.version,
    required this.isInstalled,
    required this.isEnabled,
    required this.icon,
  });
} 