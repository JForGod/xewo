import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/guardian_theme.dart';
import '../themes/app_theme.dart';
import '../widgets/assistant_container.dart';
import '../widgets/chat_interface.dart';
import '../../domain/models/assistant_mode.dart';
import '../../domain/models/conversation.dart';
import '../../providers/conversation_provider.dart';

// 2025-03-21: 修改 - 将StatelessWidget改为ConsumerStatefulWidget以支持状态管理
class GuardianModePage extends ConsumerStatefulWidget {
  const GuardianModePage({Key? key}) : super(key: key);

  @override
  ConsumerState<GuardianModePage> createState() => _GuardianModePageState();
}

class _GuardianModePageState extends ConsumerState<GuardianModePage> {
  bool _showChat = false;
  
  // 2025-03-21: 新增 - 初始化函数，确保有活动会话
  @override
  void initState() {
    super.initState();
    // 确保在初始化时有一个活动会话
    Future.microtask(() => _ensureActiveConversation());
  }
  
  // 2025-03-21: 新增 - 确保有活动会话
  Future<void> _ensureActiveConversation() async {
    final notifier = ref.read(conversationProvider.notifier);
    final conversations = ref.read(conversationProvider);
    
    // 检查是否有会话，如果没有则创建新会话
    if (conversations.isEmpty || notifier.activeConversation == null) {
      try {
        await notifier.createConversation(
          title: '监护模式对话',
          type: ConversationType.guardian,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建会话失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AssistantContainer(
      mode: AssistantMode.guardian,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          
          // 显示聊天界面或功能卡片
          Expanded(
            child: _showChat 
                ? _buildChatInterface() 
                : _buildContent(),
          ),
          
          const SizedBox(height: 16),
          _buildControlButtons(),
        ],
      ),
    );
  }

  // 2025-03-21: 新增 - 构建聊天界面
  Widget _buildChatInterface() {
    return ChatInterface(
      chatMode: ConversationType.guardian,
      hintText: '请输入你的问题...',
      userAvatar: CircleAvatar(
        backgroundColor: GuardianTheme.accentColor.withOpacity(0.3),
        radius: 16,
        child: const Text(
          '👦',
          style: TextStyle(fontSize: 14),
        ),
      ),
      assistantAvatar: CircleAvatar(
        backgroundColor: GuardianTheme.primaryColor.withOpacity(0.3),
        radius: 16,
        child: const Text(
          '🤖',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(GuardianTheme.spacingUnit / 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(GuardianTheme.borderRadius / 2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: GuardianTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🔒',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 助手 - 监护模式',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: GuardianTheme.fontSizeBase,
                  ),
                ),
                Text(
                  '安全保障已启用',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: GuardianTheme.fontSizeBase * 0.75,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置功能即将推出')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(GuardianTheme.spacingUnit),
      child: Column(
        children: [
          _buildFunctionCard(
            icon: '📚',
            title: '学习助手',
            description: '帮助你更好地学习和理解',
            onTap: () {
              setState(() {
                _showChat = true;
              });
              // 发送初始消息
              _sendInitialMessage("我是学习助手，有什么我可以帮你理解的知识吗？");
            },
          ),
          const SizedBox(height: 12),
          _buildFunctionCard(
            icon: '🎮',
            title: '创意伙伴',
            description: '激发你的创意和想象力',
            onTap: () {
              setState(() {
                _showChat = true;
              });
              _sendInitialMessage("我是创意伙伴，让我们一起来发挥想象力吧！你有什么创意想法想要探索吗？");
            },
          ),
          const SizedBox(height: 12),
          _buildFunctionCard(
            icon: '🧩',
            title: '问题解答',
            description: '解答你的问题和困惑',
            onTap: () {
              setState(() {
                _showChat = true;
              });
              _sendInitialMessage("我是问题解答助手，有什么问题需要解答吗？");
            },
          ),
        ],
      ),
    );
  }
  
  // 2025-03-21: 新增 - 发送初始消息
  Future<void> _sendInitialMessage(String text) async {
    try {
      final notifier = ref.read(conversationProvider.notifier);
      
      // 清空当前会话的消息
      final activeConversation = ref.read(activeConversationProvider);
      if (activeConversation != null) {
        await notifier.clearConversationMessages(activeConversation.id);
      }
      
      // 添加系统消息
      await notifier.addSystemMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化会话失败: $e')),
        );
      }
    }
  }

  Widget _buildFunctionCard({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GuardianTheme.borderRadius / 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GuardianTheme.borderRadius / 2),
        child: Padding(
          padding: const EdgeInsets.all(GuardianTheme.spacingUnit / 2),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GuardianTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(GuardianTheme.borderRadius / 4),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: GuardianTheme.fontSizeBase,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: GuardianTheme.fontSizeBase * 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_showChat)
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GuardianTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _showChat = false;
              });
            },
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.help_outline),
            label: const Text('帮助'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GuardianTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('帮助功能即将推出')),
              );
            },
          ),
      ],
    );
  }
}
