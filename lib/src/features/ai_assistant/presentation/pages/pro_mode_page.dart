import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/pro_theme.dart';
import '../themes/app_theme.dart';
import '../widgets/assistant_container.dart';
import '../widgets/chat_interface.dart';
import '../widgets/multimodal_controls.dart';
import '../../domain/models/assistant_mode.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/chat_message.dart';
import '../../providers/conversation_provider.dart';
import 'package:flutter/foundation.dart';
import '../pages/llm_config_page.dart';

class ProModePage extends ConsumerStatefulWidget {
  const ProModePage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProModePage> createState() => _ProModePageState();
}

class _ProModePageState extends ConsumerState<ProModePage> with SingleTickerProviderStateMixin {
  InteractionMode _currentInteractionMode = InteractionMode.text;
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    Future.microtask(() => _ensureActiveConversation());
  }
  
  Future<void> _ensureActiveConversation() async {
    final notifier = ref.read(conversationProvider.notifier);
    final conversations = ref.read(conversationProvider);
    
    if (kDebugMode) {
      print('ProModePage: 确保活动会话 - 当前会话数量: ${conversations.length}');
      print('ProModePage: 确保活动会话 - 当前活动会话: ${notifier.activeConversationId}');
    }
    
    // 检查是否有会话，如果没有则创建新会话
    if (conversations.isEmpty) {
      try {
        if (kDebugMode) {
          print('ProModePage: 没有会话，创建新会话');
        }
        await notifier.createConversation(
          title: '专业模式对话',
          type: ConversationType.pro,
          initialMessages: [
            ChatMessage.system(text: '欢迎使用专业模式AI助手，我可以提供更高级的功能和定制选项。'),
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
          print('ProModePage: 有会话但没有活动会话，设置最后一个会话为活动会话');
        }
        
        // 查找专业模式的会话
        final proModeConversations = conversations
            .where((conv) => conv.type == ConversationType.pro)
            .toList();
        
        if (proModeConversations.isNotEmpty) {
          // 使用最近的专业模式会话
          await notifier.setActiveConversation(proModeConversations.last.id);
        } else {
          // 如果没有专业模式会话，创建一个新的
          await notifier.createConversation(
            title: '专业模式对话',
            type: ConversationType.pro,
            initialMessages: [
              ChatMessage.system(text: '欢迎使用专业模式AI助手，我可以提供更高级的功能和定制选项。'),
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
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AssistantContainer(
      mode: AssistantMode.pro,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 4),
          _buildTabs(),
          const SizedBox(height: 4),
          _buildContent(),
          const SizedBox(height: 4),
          _buildMetricsPanel(),
          const SizedBox(height: 4),
          MultimodalControls(
            currentMode: _currentInteractionMode,
            onModeChanged: (mode) {
              setState(() {
                _currentInteractionMode = mode;
              });
            },
            hintText: '输入专业模式指令...',
            onSubmit: (text) async {
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // 获取活动会话信息
    final activeConversation = ref.watch(activeConversationProvider);
    final conversationTitle = activeConversation?.title ?? '新会话';
    final isFavorite = activeConversation?.isFavorite ?? false;
    
    // 添加调试信息
    if (kDebugMode) {
      print('ProModePage: 构建头部 - 活动会话: ${activeConversation?.id}, 收藏状态: $isFavorite');
    }
    
    return Container(
      padding: const EdgeInsets.all(ProTheme.spacingUnit),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ProTheme.accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AI+',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (activeConversation != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 16,
              ),
              tooltip: isFavorite ? '取消收藏' : '收藏会话',
              color: Colors.white.withOpacity(0.7),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: ProTheme.fontSizeBase * 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusIndicator('Active', Colors.green),
          IconButton(
            icon: const Icon(Icons.history, size: 16),
            tooltip: '会话历史',
            color: Colors.white.withOpacity(0.7),
            onPressed: () => _showHistoryDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            tooltip: '新会话',
            color: Colors.white.withOpacity(0.7),
            onPressed: () => _createNewConversation(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 16),
            tooltip: '设置',
            color: Colors.white.withOpacity(0.7),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LLMConfigPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ProTheme.spacingUnit,
        vertical: ProTheme.spacingUnit / 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: ProTheme.fontSizeBase * 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.5),
      indicatorColor: ProTheme.accentColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontSize: ProTheme.fontSizeBase * 0.9,
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(text: 'Chat'),
        Tab(text: 'Code'),
        Tab(text: 'Debug'),
      ],
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildCodeTab(),
          _buildDebugTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Container(
      padding: const EdgeInsets.all(ProTheme.spacingUnit),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
      ),
      child: ChatInterface(
        chatMode: ConversationType.pro,
        hintText: '输入专业模式指令...',
        userAvatar: CircleAvatar(
          backgroundColor: ProTheme.accentColor.withOpacity(0.3),
          radius: 16,
          child: const Icon(
            Icons.person,
            size: 14,
            color: Colors.white,
          ),
        ),
        assistantAvatar: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: ProTheme.accentColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'AI+',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeTab() {
    return Container(
      padding: const EdgeInsets.all(ProTheme.spacingUnit),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
      ),
      child: ClipRect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCodeHeader(),
            const SizedBox(height: 4),
            Expanded(
              child: _buildCodeEditor(),
            ),
            const SizedBox(height: 4),
            _buildCodeActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugTab() {
    return Container(
      padding: const EdgeInsets.all(ProTheme.spacingUnit),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
      ),
      child: ClipRect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDebugHeader(),
            const SizedBox(height: 4),
            Expanded(
              child: _buildDebugConsole(),
            ),
            const SizedBox(height: 4),
            _buildDebugActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ProTheme.spacingUnit,
            vertical: ProTheme.spacingUnit / 2,
          ),
          decoration: BoxDecoration(
            color: ProTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ProTheme.borderRadius),
          ),
          child: const Text(
            'main.dart',
            style: TextStyle(
              color: Colors.white,
              fontSize: ProTheme.fontSizeBase * 0.8,
              fontFamily: 'SF Mono',
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.content_copy,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.download,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      padding: const EdgeInsets.all(ProTheme.spacingUnit),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'SF Mono',
            fontSize: ProTheme.fontSizeBase * 0.9,
            color: Colors.white,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: 'import ',
              style: TextStyle(color: Color(0xFFFF79C6)),
            ),
            TextSpan(
              text: '\'package:flutter/material.dart\';\n\n',
              style: TextStyle(color: Color(0xFFF1FA8C)),
            ),
            TextSpan(
              text: 'void ',
              style: TextStyle(color: Color(0xFFFF79C6)),
            ),
            TextSpan(
              text: 'main',
              style: TextStyle(color: Color(0xFF8BE9FD)),
            ),
            TextSpan(
              text: '() {\n  ',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'runApp',
              style: TextStyle(color: Color(0xFF8BE9FD)),
            ),
            TextSpan(
              text: '(',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'const ',
              style: TextStyle(color: Color(0xFFFF79C6)),
            ),
            TextSpan(
              text: 'MyApp',
              style: TextStyle(color: Color(0xFF50FA7B)),
            ),
            TextSpan(
              text: '());\n}\n\n',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'class ',
              style: TextStyle(color: Color(0xFFFF79C6)),
            ),
            TextSpan(
              text: 'MyApp ',
              style: TextStyle(color: Color(0xFF50FA7B)),
            ),
            TextSpan(
              text: 'extends ',
              style: TextStyle(color: Color(0xFFFF79C6)),
            ),
            TextSpan(
              text: 'StatelessWidget ',
              style: TextStyle(color: Color(0xFF50FA7B)),
            ),
            TextSpan(
              text: '{\n  ',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'const ',
              style: TextStyle(color: Color(0xFFFF79C6)),
            ),
            TextSpan(
              text: 'MyApp({',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'Key? ',
              style: TextStyle(color: Color(0xFF8BE9FD)),
            ),
            TextSpan(
              text: 'key}) : ',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'super',
              style: TextStyle(color: Color(0xFFFF79C6)),
            ),
            TextSpan(
              text: '(key: key);\n\n',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.format_indent_increase, '格式化'),
        _buildActionButton(Icons.content_copy, '复制'),
        _buildActionButton(Icons.play_arrow, '运行'),
        _buildActionButton(Icons.save, '保存'),
      ],
    );
  }

  Widget _buildDebugHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ProTheme.spacingUnit,
            vertical: ProTheme.spacingUnit / 2,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ProTheme.borderRadius),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: Colors.red,
                size: 8,
              ),
              SizedBox(width: 4),
              Text(
                'Live Debug',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: ProTheme.fontSizeBase * 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Icon(
          Icons.refresh,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.more_vert,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildDebugConsole() {
    return Container(
      padding: const EdgeInsets.all(ProTheme.spacingUnit),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
      ),
      child: ListView(
        children: [
          Text(
            '> Starting debug session...',
            style: ProTheme.consoleTextStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '> Syncing files to device...',
            style: ProTheme.consoleTextStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '> Running with sound null safety',
            style: ProTheme.consoleTextStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '> Flutter: Initializing engine...',
            style: ProTheme.consoleTextStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '> Running debug build...',
            style: ProTheme.consoleTextStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '✓ Built build/app/outputs/flutter-apk/app-debug.apk (120MB).',
            style: ProTheme.consoleTextStyle.copyWith(
              color: const Color(0xFF50FA7B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '> Debug service listening on ws://127.0.0.1:51306/...',
            style: ProTheme.consoleTextStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '> Application started.',
            style: ProTheme.consoleTextStyle.copyWith(
              color: const Color(0xFF50FA7B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.pause, '暂停'),
        _buildActionButton(Icons.skip_next, '下一步'),
        _buildActionButton(Icons.bug_report, '断点'),
        _buildActionButton(Icons.stop, '停止'),
      ],
    );
  }

  Widget _buildMetricsPanel() {
    return Container(
      padding: const EdgeInsets.all(ProTheme.spacingUnit),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(ProTheme.borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('CPU', '12%', Colors.blue),
          _buildMetric('Memory', '256MB', Colors.green),
          _buildMetric('Response', '42ms', Colors.orange),
          _buildMetric('Tasks', '3/5', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: ProTheme.fontSizeBase * 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: ProTheme.fontSizeBase,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ProTheme.buttonSize,
          height: ProTheme.buttonSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(ProTheme.borderRadius),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: ProTheme.fontSizeBase * 0.7,
          ),
        ),
      ],
    );
  }

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
            print('ProModePage: 显示历史对话框 - 收藏会话数: ${favoriteConversations.length}, 最近会话数: ${recentConversations.length}');
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
                      labelColor: ProTheme.accentColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: '收藏'),
                        Tab(text: '最近'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
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
                child: const Text('关闭', style: TextStyle(color: ProTheme.accentColor)),
              ),
              TextButton(
                onPressed: _createNewConversation,
                child: const Text('新会话', style: TextStyle(color: ProTheme.accentColor)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationList(List<Conversation> conversations, Function onUpdate) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final isActive = ref.read(conversationProvider.notifier).activeConversationId == conversation.id;
        
        String previewText = '';
        if (conversation.messages.isNotEmpty) {
          final nonSystemMessages = conversation.messages
              .where((m) => m.type != MessageType.system)
              .toList();
          
          if (nonSystemMessages.isNotEmpty) {
            final lastMessage = nonSystemMessages.last;
            previewText = lastMessage.text;
            if (previewText.length > 50) {
              previewText = '${previewText.substring(0, 47)}...';
            }
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${conversation.updatedAt.toLocal().toString().substring(0, 16)} · ${conversation.messages.length}条消息',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              if (previewText.isNotEmpty)
                Text(
                  previewText,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ProTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 4),
              if (conversation.isFavorite)
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                  tooltip: '取消收藏',
                  onPressed: () async {
                    try {
                      final notifier = ref.read(conversationProvider.notifier);
                      await notifier.toggleFavoriteConversation(conversation.id);
                      
                      // 调用onUpdate回调刷新整个对话框
                      onUpdate();
                      
                      // 显示操作成功的提示
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已取消收藏'), 
                            duration: Duration(seconds: 1),
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
                )
              else
                IconButton(
                  icon: const Icon(Icons.star_border, color: Colors.grey, size: 18),
                  tooltip: '收藏会话',
                  onPressed: () async {
                    try {
                      final notifier = ref.read(conversationProvider.notifier);
                      await notifier.toggleFavoriteConversation(conversation.id);
                      
                      // 调用onUpdate回调刷新整个对话框
                      onUpdate();
                      
                      // 显示操作成功的提示
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已收藏会话'), 
                            duration: Duration(seconds: 1),
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
            ],
          ),
          onTap: () async {
            // 2025-03-28: 修改 - 增强会话切换的错误处理和用户反馈
            
            // 先关闭对话框，避免在操作完成后再关闭导致用户体验不好
            Navigator.pop(context);
            
            // 显示加载指示器
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                      SizedBox(width: 10),
                      Text('正在切换会话...'),
                    ],
                  ),
                  duration: Duration(milliseconds: 500),
                ),
              );
            }
            
            try {
              final notifier = ref.read(conversationProvider.notifier);
              
              // 切换活动会话
              await notifier.setActiveConversation(conversation.id);
              
              // 显示成功提示
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已切换到会话: ${conversation.title}'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.green[700],
                  ),
                );
                
                // 强制刷新整个页面状态
                setState(() {});
              }
            } catch (e) {
              // 显示详细的错误信息
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('切换会话失败: $e'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red[700],
                    action: SnackBarAction(
                      label: '重试',
                      textColor: Colors.white,
                      onPressed: () async {
                        try {
                          final notifier = ref.read(conversationProvider.notifier);
                          await notifier.setActiveConversation(conversation.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已切换到会话: ${conversation.title}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (retryError) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('重试失败: $retryError')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              }
              
              if (kDebugMode) {
                print('会话切换失败 - 详细错误: $e');
              }
            }
          },
          tileColor: isActive ? Colors.white.withOpacity(0.05) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        );
      },
    );
  }

  // 2025-03-25: 新增 - 创建新会话
  Future<void> _createNewConversation() async {
    try {
      final notifier = ref.read(conversationProvider.notifier);
      await notifier.createConversation(
        title: '专业会话 ${DateTime.now().toIso8601String().substring(0, 16)}',
        type: ConversationType.pro,
        initialMessages: [
          ChatMessage.system(text: '欢迎使用专业模式AI助手，我可以提供更高级的功能和定制选项。'),
        ],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('新会话已创建')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建新会话失败: $e')),
        );
      }
    }
  }
  
  // 2025-03-25: 新增 - 显示重命名对话框
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
              borderSide: BorderSide(color: ProTheme.accentColor),
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
              try {
                final newTitle = textController.text.trim();
                if (newTitle.isEmpty) {
                  throw Exception('会话名称不能为空');
                }
                
                final notifier = ref.read(conversationProvider.notifier);
                await notifier.updateConversationTitle(activeConversation.id, newTitle);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('会话已重命名')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('重命名失败: $e')),
                  );
                }
              }
            },
            child: const Text('确定', style: TextStyle(color: ProTheme.accentColor)),
          ),
        ],
      ),
    );
  }
}
