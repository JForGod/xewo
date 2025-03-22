import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/standard_theme.dart';
import '../themes/app_theme.dart';
import '../widgets/assistant_container.dart';
import '../widgets/multimodal_controls.dart';
import '../widgets/chat_interface.dart';
import 'llm_config_page.dart';
import 'settings/routes.dart';
import '../../domain/models/assistant_mode.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/chat_message.dart';
import '../../providers/conversation_provider.dart';
import '../../../../core/ai_engine/llm/llm_service_provider.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/interaction_mode.dart';

// 2025-03-17: 修改 - 更新标准模式页面，集成聊天界面组件
// 2025-03-18: 修改 - 添加LLM配置入口
// 2025-03-22: 修改 - 将设置按钮改为打开多模态设置页面
class StandardModePage extends ConsumerStatefulWidget {
  const StandardModePage({Key? key}) : super(key: key);

  @override
  ConsumerState<StandardModePage> createState() => _StandardModePageState();
}

class _StandardModePageState extends ConsumerState<StandardModePage> {
  InteractionMode _currentInteractionMode = InteractionMode.text;
  
  @override
  void initState() {
    super.initState();
    // 确保在初始化时有一个活动会话，但延迟执行
    Future.microtask(() => _ensureActiveConversation());
  }
  
  // 2025-03-22: 修改 - 优化活动会话初始化逻辑，确保聊天记录正确显示
  Future<void> _ensureActiveConversation() async {
    final notifier = ref.read(conversationProvider.notifier);
    final conversations = ref.read(conversationProvider);
    
    if (kDebugMode) {
      print('StandardModePage: 确保活动会话 - 当前会话数量: ${conversations.length}');
      print('StandardModePage: 确保活动会话 - 当前活动会话: ${notifier.activeConversationId}');
    }
    
    // 检查是否有会话，如果没有则创建新会话
    if (conversations.isEmpty) {
      try {
        if (kDebugMode) {
          print('StandardModePage: 没有会话，创建新会话');
        }
        await notifier.createConversation(
          title: '新对话',
          type: ConversationType.general,
          initialMessages: [
            ChatMessage.system(text: '欢迎使用标准模式AI助手，有什么可以帮助你的？'),
          ],
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建会话失败: $e')),
          );
        }
      }
      return;
    }
    
    // 如果有会话但没有活动会话，设置最后一个会话为活动会话
    if (notifier.activeConversationId == null && conversations.isNotEmpty) {
      try {
        if (kDebugMode) {
          print('StandardModePage: 有会话但没有活动会话，设置最后一个会话为活动会话');
        }
        
        // 查找标准模式的会话
        final standardModeConversations = conversations
            .where((conv) => conv.type == ConversationType.general)
            .toList();
        
        if (standardModeConversations.isNotEmpty) {
          // 使用最近的标准模式会话
          await notifier.setActiveConversation(standardModeConversations.last.id);
        } else {
          // 如果没有标准模式会话，创建一个新的
          await notifier.createConversation(
            title: '新对话',
            type: ConversationType.general,
            initialMessages: [
              ChatMessage.system(text: '欢迎使用标准模式AI助手，有什么可以帮助你的？'),
            ],
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('设置活动会话失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2025-03-25 修改 - 移除SingleChildScrollView，改为Column直接使用Expanded，解决Row区域不显示问题
    return AssistantContainer(
      mode: AssistantMode.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          // 2025-03-25 修改 - 使用Expanded让聊天区域自适应高度
          Expanded(
            child: ChatInterface(
              chatMode: ConversationType.general,
              hintText: '输入消息，按回车发送...',
              userAvatar: _buildUserAvatar(),
              assistantAvatar: _buildAssistantAvatar(),
            ),
          ),
          const SizedBox(height: 12),
          _buildSuggestions(),
          const SizedBox(height: 12),
          // 2025-03-25 修改 - 确保MultimodalControls始终显示在底部
          MultimodalControls(
            mode: AssistantMode.standard,
            onModeChanged: _handleModeChange,
            onSubmit: _handleSubmit,
          ),
        ],
      ),
    );
  }

  // 2025-03-17: 修改 - 更新标题栏，添加会话管理功能
  // 2025-03-18: 修改 - 添加LLM设置按钮
  // 2025-03-20: 修改 - 添加会话历史管理菜单
  // 2025-03-22: 修改 - 更新设置按钮为多模态设置入口
  Widget _buildHeader() {
    // 获取活动会话信息
    final activeConversation = ref.watch(activeConversationProvider);
    final conversationTitle = activeConversation?.title ?? '新对话';
    final isFavorite = activeConversation?.isFavorite ?? false;
    
    // 添加调试信息
    if (kDebugMode) {
      print('StandardModePage: 构建头部 - 活动会话: ${activeConversation?.id}, 收藏状态: $isFavorite');
    }
    
    // 获取LLM服务状态
    final llmStatus = ref.watch(llmServiceStatusProvider);
    final hasLLMError = llmStatus == LLMServiceStatus.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: StandardTheme.headerBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          if (activeConversation != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 18,
              ),
              tooltip: isFavorite ? '取消收藏' : '收藏会话',
              onPressed: () async {
                try {
                  final notifier = ref.read(conversationProvider.notifier);
                  await notifier.toggleFavoriteConversation(activeConversation.id);
                  
                  // 显示操作成功的提示
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFavorite ? '已取消收藏' : '已收藏会话'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('操作失败: $e')),
                    );
                  }
                }
              },
            ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showRenameDialog(),
              child: Text(
                conversationTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // LLM错误指示器
          if (hasLLMError) 
            Tooltip(
              message: ref.watch(llmErrorMessageProvider) ?? '未知错误',
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 18,
              ),
            ),
          // 会话管理按钮
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: '会话管理',
            onPressed: () => _showConversationMenu(),
          ),
          // 多模态设置按钮（以前是LLM配置按钮）
          IconButton(
            icon: Icon(
              Icons.settings,
              color: hasLLMError ? Colors.red : Colors.grey,
            ),
            tooltip: '设置',
            onPressed: () {
              SettingsRoutes.navigateToMultimodalSettings(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新会话',
            onPressed: () => _createNewConversation(),
          ),
        ],
      ),
    );
  }
  
  // 2025-03-20: 新增 - 显示会话管理菜单
  void _showConversationMenu() {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text('历史会话', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showHistoryDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.white),
            title: const Text('搜索会话', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showSearchDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.white),
            title: const Text('清空当前会话', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showClearConfirmation();
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.white),
            title: const Text('导出会话', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await _exportCurrentConversation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text('导入会话', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // 暂不实现导入功能，需要文件选择器
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导入会话功能尚未实现')),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // 2025-03-20: 新增 - 导出当前会话
  Future<void> _exportCurrentConversation() async {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation == null) return;
    
    try {
      final notifier = ref.read(conversationProvider.notifier);
      final filePath = await notifier.exportConversation(activeConversation.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('会话已导出到: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出会话失败: $e')),
        );
      }
    }
  }
  
  // 2025-03-20: 新增 - 显示搜索对话框
  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final notifier = ref.read(conversationProvider.notifier);
            final searchResults = notifier.searchConversations(searchController.text);
            
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('搜索会话', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: '输入关键词搜索',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: StandardTheme.accentColor),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                '没有找到匹配的会话',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final conversation = searchResults[index];
                                return ListTile(
                                  title: Text(
                                    conversation.title,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    '${conversation.updatedAt.toLocal().toString().substring(0, 16)} · ${conversation.messages.length}条消息',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                  ),
                                  onTap: () async {
                                    try {
                                      await notifier.setActiveConversation(conversation.id);
                                      Navigator.pop(context);
                                    } catch (e) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('切换会话失败: $e')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭', style: TextStyle(color: StandardTheme.accentColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: StandardTheme.spacingUnit / 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildSuggestionPill('解释代码'),
          _buildSuggestionPill('Flutter状态管理'),
          _buildSuggestionPill('优化性能'),
          _buildSuggestionPill('UI设计'),
        ],
      ),
    );
  }

  // 2025-03-17: 修改 - 更新建议项功能，点击时发送消息
  Widget _buildSuggestionPill(String text) {
    return GestureDetector(
      onTap: () async {
        try {
          final notifier = ref.read(conversationProvider.notifier);
          await notifier.sendMessageToLLM(text);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('发送消息失败: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StandardTheme.spacingUnit,
          vertical: StandardTheme.spacingUnit / 2,
        ),
        decoration: BoxDecoration(
          color: StandardTheme.accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: StandardTheme.fontSizeBase * 0.8,
          ),
        ),
      ),
    );
  }
  
  // 2025-03-17: 新增 - 创建用户头像
  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: StandardTheme.accentColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '👤',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
  
  // 2025-03-17: 新增 - 创建助手头像
  Widget _buildAssistantAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: StandardTheme.primaryColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'AI',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 2025-03-20: 新增 - 获取最近会话
  List<Conversation> getRecentConversationsByType(ConversationType type, {int limit = 10}) {
    final filteredConversations = ref.read(conversationProvider)
        .where((conv) => conv.type == type)
        .toList();
    
    filteredConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return filteredConversations.take(limit).toList();
  }

  // 2025-03-25: 修改 - 优化历史会话对话框
  void _showHistoryDialog() {
    // 使用StatefulBuilder包装对话框以支持局部状态更新
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 在StatefulBuilder内部获取最新的会话列表
          final notifier = ref.read(conversationProvider.notifier);
          final favoriteConversations = notifier.getFavoriteConversations();
          final allRecentConversations = notifier.getRecentConversations(20);
          
          // 过滤掉已收藏的会话，避免重复显示
          final recentConversations = allRecentConversations
              .where((c) => !favoriteConversations.any((f) => f.id == c.id))
              .toList();
          
          if (kDebugMode) {
            print('StandardModePage: 显示历史对话框 - 收藏会话数: ${favoriteConversations.length}, 最近会话数: ${recentConversations.length}');
          }
          
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('会话历史', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: StandardTheme.accentColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: '收藏'),
                        Tab(text: '最近'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 收藏会话列表
                          favoriteConversations.isEmpty
                              ? const Center(
                                  child: Text(
                                    '没有收藏的会话',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : _buildConversationList(
                                  favoriteConversations, 
                                  () {
                                    // 使用setDialogState更新对话框状态
                                    setDialogState(() {
                                      // 刷新整个对话框
                                      if (kDebugMode) {
                                        print('收藏状态已更改，刷新对话框');
                                      }
                                    });
                                  },
                                ),
                          // 最近会话列表
                          recentConversations.isEmpty
                              ? const Center(
                                  child: Text(
                                    '没有最近会话',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : _buildConversationList(
                                  recentConversations, 
                                  () {
                                    // 使用setDialogState更新对话框状态
                                    setDialogState(() {
                                      // 刷新整个对话框
                                      if (kDebugMode) {
                                        print('收藏状态已更改，刷新对话框');
                                      }
                                    });
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭', style: TextStyle(color: StandardTheme.accentColor)),
              ),
              TextButton(
                onPressed: _createNewConversation,
                child: const Text('新会话', style: TextStyle(color: StandardTheme.accentColor)),
              ),
            ],
          );
        },
      ),
    );
  }

  // 2025-03-25: 修改 - 优化会话列表展示和切换逻辑
  Widget _buildConversationList(List<Conversation> conversations, Function onUpdate) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final isActive = ref.read(conversationProvider.notifier).activeConversationId == conversation.id;
        
        // 简化预览文本计算，减少性能开销
        String previewText = '';
        if (conversation.messages.isNotEmpty) {
          // 只获取最后一条消息，不进行复杂过滤
          final lastMessage = conversation.messages.last;
          previewText = lastMessage.text;
          if (previewText.length > 50) {
            previewText = '${previewText.substring(0, 47)}...';
          }
        }
        
        return ListTile(
          title: Text(
            conversation.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${conversation.updatedAt.toLocal().toString().substring(0, 16)} · ${conversation.messages.length}条消息',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
          trailing: conversation.isFavorite
            ? IconButton(
                icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                tooltip: '取消收藏',
                onPressed: () async {
                  try {
                    final notifier = ref.read(conversationProvider.notifier);
                    await notifier.toggleFavoriteConversation(conversation.id);
                    onUpdate();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('操作失败: $e')),
                      );
                    }
                  }
                },
              )
            : IconButton(
                icon: const Icon(Icons.star_border, color: Colors.grey, size: 18),
                tooltip: '收藏会话',
                onPressed: () async {
                  try {
                    final notifier = ref.read(conversationProvider.notifier);
                    await notifier.toggleFavoriteConversation(conversation.id);
                    onUpdate();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('操作失败: $e')),
                      );
                    }
                  }
                },
              ),
          onTap: () {
            // 关闭对话框
            Navigator.pop(context);
            
            // 使用延迟操作来避免UI阻塞
            Future.delayed(const Duration(milliseconds: 100), () async {
              try {
                final notifier = ref.read(conversationProvider.notifier);
                
                // 显示加载指示器
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('正在切换会话...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
                
                // 切换活动会话
                await notifier.setActiveConversation(conversation.id);
                
                // 手动触发状态刷新
                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('切换会话失败: $e')),
                  );
                }
              }
            });
          },
          tileColor: isActive ? Colors.white.withOpacity(0.05) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        );
      },
    );
  }

  // 2025-03-17: 新增 - 创建新会话
  Future<void> _createNewConversation() async {
    try {
      final notifier = ref.read(conversationProvider.notifier);
      await notifier.createConversation(
        title: '新会话 ${DateTime.now().toIso8601String().substring(0, 16)}',
        type: ConversationType.general,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建新会话失败: $e')),
        );
      }
    }
  }

  // 2025-03-17: 新增 - 显示重命名对话框
  void _showRenameDialog() {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation == null) return;
    
    final textController = TextEditingController(text: activeConversation.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('重命名会话', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '输入新名称',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: StandardTheme.accentColor),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  final notifier = ref.read(conversationProvider.notifier);
                  await notifier.renameConversation(activeConversation.id, newName);
                  Navigator.pop(context);
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('重命名失败: $e')),
                  );
                }
              }
            },
            child: const Text('确定', style: TextStyle(color: StandardTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  // 2025-03-17: 新增 - 显示清空确认对话框
  void _showClearConfirmation() {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('清空会话', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要清空当前会话吗？这将删除所有消息，但保留会话记录。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                final notifier = ref.read(conversationProvider.notifier);
                await notifier.clearConversationMessages(activeConversation.id);
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('清空会话失败: $e')),
                );
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 2025-03-17: 新增 - 删除消息
  Future<void> _deleteMessage(String messageId) async {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation == null) return;
    
    try {
      final notifier = ref.read(conversationProvider.notifier);
      await notifier.deleteMessage(activeConversation.id, messageId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除消息失败: $e')),
        );
      }
    }
  }

  void _handleModeChange(InteractionMode mode) {
    setState(() {
      _currentInteractionMode = mode;
    });
  }

  void _handleSubmit(String text) async {
    try {
      final notifier = ref.read(conversationProvider.notifier);
      await notifier.sendMessageToLLM(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送消息失败: $e')),
        );
      }
    }
  }
}
