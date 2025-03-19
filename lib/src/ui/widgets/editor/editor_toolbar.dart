import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/app_theme.dart';
import '../../../services/global_assistant_service/global_assistant_service.dart';
import '../../../utils/theme_utils.dart';
import '../../../state/providers/editor_provider.dart';
import '../search/search_bar.dart';

/// 编辑器工具栏组件
class EditorToolbar extends ConsumerWidget {
  /// 是否显示返回按钮
  final bool showBackButton;
  
  /// 是否显示打开项目按钮
  final bool showOpenProjectButton;
  
  /// 是否显示在新窗口打开按钮
  final bool showOpenInNewWindowButton;
  
  /// 是否显示切换文件树按钮
  final bool showToggleFileTreeButton;
  
  /// 是否显示格式化代码按钮
  final bool showFormatCodeButton;
  
  /// 是否显示搜索按钮
  final bool showSearchButton;
  
  /// 是否显示替换按钮
  final bool showReplaceButton;
  
  /// 是否显示切换行号按钮
  final bool showToggleLineNumbersButton;
  
  /// 是否显示切换小地图按钮
  final bool showToggleMinimapButton;
  
  /// 是否显示全部折叠按钮
  final bool showFoldAllButton;
  
  /// 是否显示全部展开按钮
  final bool showExpandAllButton;
  
  /// 是否显示保存按钮
  final bool showSaveButton;
  
  /// 返回按钮回调
  final VoidCallback? onBack;
  
  /// 打开项目按钮回调
  final VoidCallback? onOpenProject;
  
  /// 在新窗口打开按钮回调
  final VoidCallback? onOpenInNewWindow;
  
  /// 切换文件树按钮回调
  final VoidCallback? onToggleFileTree;
  
  /// 格式化代码按钮回调
  final VoidCallback? onFormat;
  
  /// 搜索按钮回调
  final VoidCallback? onFind;
  
  /// 替换按钮回调
  final VoidCallback? onFindReplacePressed;
  
  /// 切换行号按钮回调
  final VoidCallback? onToggleLineNumbers;
  
  /// 切换小地图按钮回调
  final VoidCallback? onToggleMinimap;
  
  /// 全部折叠按钮回调
  final VoidCallback? onFoldAll;
  
  /// 全部展开按钮回调
  final VoidCallback? onExpandAll;
  
  /// 保存按钮回调
  final VoidCallback? onSave;
  
  /// 当前文件路径
  final String? filePath;
  
  /// 是否显示文件树
  final bool showFileTree;
  
  /// 是否显示行号
  final bool showLineNumbers;
  
  /// 是否显示小地图
  final bool showMinimap;

  /// 构造函数
  const EditorToolbar({
    Key? key,
    this.showBackButton = true,
    this.showOpenProjectButton = true,
    this.showOpenInNewWindowButton = true,
    this.showToggleFileTreeButton = true,
    this.showFormatCodeButton = true,
    this.showSearchButton = true,
    this.showReplaceButton = true,
    this.showToggleLineNumbersButton = true,
    this.showToggleMinimapButton = true,
    this.showFoldAllButton = true,
    this.showExpandAllButton = true,
    this.showSaveButton = true,
    this.onBack,
    this.onOpenProject,
    this.onOpenInNewWindow,
    this.onToggleFileTree,
    this.onFormat,
    this.onFind,
    this.onFindReplacePressed,
    this.onToggleLineNumbers,
    this.onToggleMinimap,
    this.onFoldAll,
    this.onExpandAll,
    this.onSave,
    this.filePath,
    this.showFileTree = true,
    this.showLineNumbers = true,
    this.showMinimap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalAssistantService globalAssistantService = GlobalAssistantService();
    final String currentWindowId = globalAssistantService.getActiveWindowContext()?.windowId ?? const Uuid().v4();
    final editorState = ref.watch(editorProvider);
    final currentDirectoryPath = editorState.currentDirectoryPath;
    final directoryName = currentDirectoryPath?.split(RegExp(r'[/\\]')).last ?? '全局搜索';
    
    // 定义左侧工具栏按钮数据
    final List<Map<String, dynamic>> leftToolbarItems = [
      // 返回按钮
      if (showBackButton && onBack != null)
        {
          'icon': 'assets/icons/arrow_back.svg',
          'tooltip': '返回',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.windowSwitch,
              {
                'action': 'back',
                'source': 'editor_toolbar',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onBack!();
          },
        },
      
      // 切换文件树按钮
      if (showToggleFileTreeButton && onToggleFileTree != null)
        {
          'icon': 'assets/icons/file_tree.svg',
          'tooltip': '切换文件树',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.toggleFileTree,
              {
                'action': 'toggle_file_tree',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onToggleFileTree!();
          },
        },
      
      // 打开项目按钮
      if (showOpenProjectButton && onOpenProject != null)
        {
          'icon': 'assets/icons/folder_open.svg',
          'tooltip': '打开项目',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.openProject,
              {
                'action': 'open_project',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onOpenProject!();
          },
        },
    ];
    
    // 定义右侧工具栏按钮数据
    final List<Map<String, dynamic>> rightToolbarItems = [
      // 在新窗口打开按钮
      if (showOpenInNewWindowButton && onOpenInNewWindow != null)
        {
          'icon': 'assets/icons/open_in_new.svg',
          'tooltip': '在新窗口打开',
          'onPressed': () {
            try {
              // 记录操作到全局上下文
              final action = {
                'action': 'open_in_new_window',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'filePath': filePath ?? '',
                'timestamp': DateTime.now().toIso8601String(),
              };
              
              // 记录编辑器操作
              globalAssistantService.logEditorAction(
                WindowContextAction.openNewWindow,
                action,
              );
              
              // 执行打开新窗口的操作
              onOpenInNewWindow!();
            } catch (e) {
              print('打开新窗口时出错: $e');
            }
          },
        },
      
      // 格式化代码按钮
      if (showFormatCodeButton && onFormat != null)
        {
          'icon': 'assets/icons/format.svg',
          'tooltip': '格式化代码',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.formatCode,
              {
                'action': 'format_code',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onFormat!();
          },
        },
      
      // 搜索按钮
      if (showSearchButton && onFind != null)
        {
          'icon': 'assets/icons/search.svg',
          'tooltip': '搜索',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.search,
              {
                'action': 'search',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onFind!();
          },
        },
      
      // 替换按钮
      if (showReplaceButton && onFindReplacePressed != null)
        {
          'icon': 'assets/icons/find_replace.svg',
          'tooltip': '替换',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.replace,
              {
                'action': 'replace',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onFindReplacePressed!();
          },
        },
      
      // 切换行号按钮
      if (showToggleLineNumbersButton && onToggleLineNumbers != null)
        {
          'icon': 'assets/icons/line_numbers.svg',
          'tooltip': '切换行号',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.toggleLineNumbers,
              {
                'action': 'toggle_line_numbers',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onToggleLineNumbers!();
          },
        },
      
      // 切换小地图按钮
      if (showToggleMinimapButton && onToggleMinimap != null)
        {
          'icon': 'assets/icons/minimap.svg',
          'tooltip': '切换小地图',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.toggleMinimap,
              {
                'action': 'toggle_minimap',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onToggleMinimap!();
          },
        },
      
      // 全部折叠按钮
      if (showFoldAllButton && onFoldAll != null)
        {
          'icon': 'assets/icons/fold_all.svg',
          'tooltip': '全部折叠',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.foldAll,
              {
                'action': 'fold_all',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onFoldAll!();
          },
        },
      
      // 全部展开按钮
      if (showExpandAllButton && onExpandAll != null)
        {
          'icon': 'assets/icons/expand_all.svg',
          'tooltip': '全部展开',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.expandAll,
              {
                'action': 'expand_all',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onExpandAll!();
          },
        },
      
      // 保存按钮
      if (showSaveButton && onSave != null)
        {
          'icon': 'assets/icons/save.svg',
          'tooltip': '保存',
          'onPressed': () {
            globalAssistantService.logEditorAction(
              WindowContextAction.saveFile,
              {
                'action': 'save_file',
                'source': 'editor_toolbar',
                'windowId': currentWindowId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            onSave!();
          },
        },
    ];
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧按钮组
          ...leftToolbarItems.map((item) => _buildToolbarItem(context, item)),
          
          // 中间搜索框
          Expanded(
            child: Container(
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.search,
                    size: 16,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // 背景提示文本
                        if (directoryName.isNotEmpty)
                          Positioned(
                            left: 0,
                            child: Text(
                              directoryName,
                              style: TextStyle(
                                color: Theme.of(context).hintColor.withOpacity(0.3),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        // 搜索输入框
                        TextField(
                          decoration: InputDecoration(
                            hintText: '搜索功能、设置、文件、代码...',
                            hintStyle: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) {
                            // 通知全局AI助手搜索内容变化
                            globalAssistantService.logEditorAction(
                              WindowContextAction.search,
                              {
                                'action': 'global_search',
                                'query': value,
                                'source': 'editor_toolbar',
                                'windowId': currentWindowId,
                                'directoryName': directoryName,
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 右侧按钮组
          ...rightToolbarItems.map((item) => _buildToolbarItem(context, item)),
        ],
      ),
    );
  }
  
  Widget _buildToolbarItem(BuildContext context, Map<String, dynamic> item) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: SvgPicture.asset(
          item['icon'],
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            getIconColor(context),
            BlendMode.srcIn,
          ),
        ),
        tooltip: item['tooltip'],
        onPressed: item['onPressed'],
      ),
    );
  }
  
  /// 获取文件名
  String _getFileName(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : path;
  }
} 