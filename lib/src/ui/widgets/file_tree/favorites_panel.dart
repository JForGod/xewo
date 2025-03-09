import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../themes/app_theme.dart';

/// 收藏项类型
enum FavoriteItemType {
  file,
  folder,
  project,
}

/// 收藏项
class FavoriteItem {
  final String path;
  final String name;
  final FavoriteItemType type;
  final DateTime addedAt;

  FavoriteItem({
    required this.path,
    required this.name,
    required this.type,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// 从JSON创建收藏项
  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      path: json['path'] as String,
      name: json['name'] as String,
      type: FavoriteItemType.values[json['type'] as int],
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'type': type.index,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

/// 收藏夹状态
class FavoritesState {
  final List<FavoriteItem> items;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<FavoriteItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 收藏夹状态提供者
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState()) {
    _loadFavorites();
  }

  /// 加载收藏项
  Future<void> _loadFavorites() async {
    state = state.copyWith(isLoading: true);

    try {
      // 这里应该从本地存储加载收藏项
      // 暂时使用模拟数据
      await Future.delayed(const Duration(milliseconds: 300));
      
      final items = [
        FavoriteItem(
          path: 'H:\\AxE\\xewo\\lib\\src\\ui',
          name: 'UI目录',
          type: FavoriteItemType.folder,
        ),
        FavoriteItem(
          path: 'H:\\AxE\\xewo\\lib\\src\\ui\\widgets',
          name: '组件目录',
          type: FavoriteItemType.folder,
        ),
        FavoriteItem(
          path: 'H:\\AxE\\xewo\\lib\\src\\ui\\themes\\app_theme.dart',
          name: '主题配置',
          type: FavoriteItemType.file,
        ),
        FavoriteItem(
          path: 'H:\\AxE\\xewo',
          name: 'xEwo项目',
          type: FavoriteItemType.project,
        ),
      ];
      
      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载收藏夹失败: $e',
      );
    }
  }

  /// 添加收藏项
  Future<void> addFavorite(FileNode node) async {
    // 检查是否已存在
    if (state.items.any((item) => item.path == node.path)) {
      return;
    }

    final newItem = FavoriteItem(
      path: node.path,
      name: node.name,
      type: node.isDirectory ? FavoriteItemType.folder : FavoriteItemType.file,
    );

    state = state.copyWith(
      items: [...state.items, newItem],
    );

    // 保存到本地存储
    _saveFavorites();
  }

  /// 添加项目到收藏夹
  Future<void> addProject(String path, String name) async {
    // 检查是否已存在
    if (state.items.any((item) => item.path == path)) {
      return;
    }

    final newItem = FavoriteItem(
      path: path,
      name: name,
      type: FavoriteItemType.project,
    );

    state = state.copyWith(
      items: [...state.items, newItem],
    );

    // 保存到本地存储
    _saveFavorites();
  }

  /// 移除收藏项
  Future<void> removeFavorite(String path) async {
    state = state.copyWith(
      items: state.items.where((item) => item.path != path).toList(),
    );

    // 保存到本地存储
    _saveFavorites();
  }

  /// 重命名收藏项
  Future<void> renameFavorite(String path, String newName) async {
    final updatedItems = state.items.map((item) {
      if (item.path == path) {
        return FavoriteItem(
          path: item.path,
          name: newName,
          type: item.type,
          addedAt: item.addedAt,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);

    // 保存到本地存储
    _saveFavorites();
  }

  /// 保存收藏项到本地存储
  Future<void> _saveFavorites() async {
    // 这里应该将收藏项保存到本地存储
    // 暂时只打印日志
    print('保存收藏夹: ${state.items.length}项');
  }
}

/// 收藏夹提供者
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier();
});

/// 收藏夹面板组件
class FavoritesPanel extends ConsumerWidget {
  final Function(String) onItemSelected;

  const FavoritesPanel({
    Key? key,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          child: Row(
            children: [
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: AppTheme.spacingSm),
              const Text(
                '收藏夹',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => ref.read(favoritesProvider.notifier)._loadFavorites(),
                tooltip: '刷新',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),

        // 收藏项列表
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(child: Text(state.error!))
                  : state.items.isEmpty
                      ? const Center(child: Text('暂无收藏项'))
                      : ListView.builder(
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _buildFavoriteItem(context, ref, item);
                          },
                        ),
        ),
      ],
    );
  }

  /// 构建收藏项
  Widget _buildFavoriteItem(BuildContext context, WidgetRef ref, FavoriteItem item) {
    return ListTile(
      leading: Icon(
        _getIconForType(item.type),
        color: _getColorForType(item.type),
        size: 20,
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.path,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      onTap: () => onItemSelected(item.path),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        onPressed: () => _showRemoveConfirmation(context, ref, item),
        tooltip: '移除',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
      onLongPress: () => _showRenameDialog(context, ref, item),
    );
  }

  /// 获取图标
  IconData _getIconForType(FavoriteItemType type) {
    switch (type) {
      case FavoriteItemType.file:
        return Icons.insert_drive_file;
      case FavoriteItemType.folder:
        return Icons.folder;
      case FavoriteItemType.project:
        return Icons.work;
    }
  }

  /// 获取颜色
  Color _getColorForType(FavoriteItemType type) {
    switch (type) {
      case FavoriteItemType.file:
        return Colors.blue;
      case FavoriteItemType.folder:
        return Colors.amber;
      case FavoriteItemType.project:
        return Colors.green;
    }
  }

  /// 显示移除确认对话框
  Future<void> _showRemoveConfirmation(BuildContext context, WidgetRef ref, FavoriteItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除收藏'),
        content: Text('确定要从收藏夹中移除 ${item.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(favoritesProvider.notifier).removeFavorite(item.path);
    }
  }

  /// 显示重命名对话框
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, FavoriteItem item) async {
    final controller = TextEditingController(text: item.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名收藏'),
        content: Container(
          width: 300,
          constraints: const BoxConstraints(maxWidth: 300),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '名称',
              isDense: true,
            ),
            maxLines: 1,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('重命名'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != item.name) {
      ref.read(favoritesProvider.notifier).renameFavorite(item.path, result);
    }
  }
} 