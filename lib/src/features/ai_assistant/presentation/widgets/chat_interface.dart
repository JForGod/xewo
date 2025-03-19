// 2025-03-17: 新增 - 聊天界面组件
// 2025-03-20: 修改 - 添加代码引用支持和实时响应
// 2025-03-21: 修改 - 修复消息更新显示问题，添加消息监听机制

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/utils/code_block_parser.dart';
import '../../providers/conversation_provider.dart';
import '../themes/standard_theme.dart';
import 'code_block_widget.dart';
import 'code_reference_widget.dart';
import 'typing_indicator.dart';
import 'streaming_text_widget.dart';

/// 聊天界面组件
class ChatInterface extends ConsumerStatefulWidget {
  /// 聊天模式
  final ConversationType chatMode;
  
  /// 是否自动滚动到底部
  final bool autoScrollToBottom;
  
  /// 输入框提示文本
  final String hintText;
  
  /// 用户头像Widget
  final Widget? userAvatar;
  
  /// 助手头像Widget
  final Widget? assistantAvatar;
  
  /// 构造函数
  const ChatInterface({
    Key? key,
    this.chatMode = ConversationType.general,
    this.autoScrollToBottom = true,
    this.hintText = '输入消息...',
    this.userAvatar,
    this.assistantAvatar,
  }) : super(key: key);

  @override
  ConsumerState<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends ConsumerState<ChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  bool _isComposing = false;
  bool _isTyping = false;
  
  // 当前活动会话及消息计数，用于检测变化
  String? _lastConversationId;
  int _lastMessageCount = 0;
  bool _isInitialized = false;
  
  // 2025-03-25: 新增 - 添加分页加载相关状态
  static const int _messagesPerPage = 20;
  bool _isLoadingMoreMessages = false;
  
  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChange);
    
    // 2025-03-25: 新增 - 监听滚动事件，实现向上滚动时加载更多历史消息
    _scrollController.addListener(_handleScroll);
    
    // 2025-03-25: 新增 - 延迟初始化，确保在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeActiveConversation();
    });
  }
  
  @override
  void dispose() {
    _textController.removeListener(_handleTextChange);
    _scrollController.removeListener(_handleScroll);
    _textController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // 2025-03-25: 新增 - 初始化活动会话
  void _initializeActiveConversation() {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation != null) {
      _lastConversationId = activeConversation.id;
      _lastMessageCount = activeConversation.messages.length;
      _isInitialized = true;
      
      // 确保在初始构建完成后滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom(immediate: true);
        }
      });
    }
  }
  
  // 2025-03-25: 新增 - 处理滚动事件，实现向上滚动时加载更多历史消息
  void _handleScroll() {
    if (_scrollController.hasClients && 
        _scrollController.position.pixels <= _scrollController.position.minScrollExtent + 50 && 
        !_isLoadingMoreMessages) {
      _loadMoreMessages();
    }
  }
  
  // 2025-03-25: 新增 - 加载更多历史消息
  Future<void> _loadMoreMessages() async {
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation == null || _isLoadingMoreMessages) return;
    
    // 当所有消息都已加载时不再尝试加载
    if (activeConversation.messages.length < _messagesPerPage) return;
    
    setState(() {
      _isLoadingMoreMessages = true;
    });
    
    // 暂时模拟异步加载，实际应从ConversationProvider获取更多消息
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      _isLoadingMoreMessages = false;
    });
    
    // 保持当前滚动位置
    // 实际情况中，当从数据库加载更多消息后，需要保持滚动位置
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.pixels + 100);
    }
  }
  
  /// 处理文本变更
  void _handleTextChange() {
    setState(() {
      _isComposing = _textController.text.isNotEmpty;
    });
  }
  
  /// 滚动到底部
  void _scrollToBottom({bool immediate = false}) {
    if (!_scrollController.hasClients) return;
    
    try {
      if (immediate) {
        // 使用无动画的直接跳转
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        // 使用动画滚动
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // 忽略滚动错误，但记录日志
      if (kDebugMode) {
        print('滚动到底部失败: $e');
      }
    }
  }

  // 安全地滚动到底部
  void _safeScrollToBottom() {
    // 2025-03-28: 修改 - 优化滚动逻辑，确保在UI更新后正确滚动到底部
    
    if (!mounted || !_scrollController.hasClients) return;
    
    // 使用scheduleFrameCallback确保在下一帧渲染完成后执行
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      
      try {
        // 首先尝试跳转
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        
        // 如果需要，可以添加后续动画效果
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        // 记录错误但不中断程序
        if (kDebugMode) {
          print('安全滚动到底部失败: $e');
        }
      }
    });
  }
  
  /// 发送消息
  Future<void> _handleSubmit(String text) async {
    if (text.isEmpty) return;
    
    _textController.clear();
    setState(() {
      _isComposing = false;
      _isTyping = true;
    });
    
    try {
      // 使用ConversationNotifier发送消息
      final notifier = ref.read(conversationProvider.notifier);
      await notifier.sendMessageToLLM(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送消息失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  /// 创建一个新的会话
  Future<void> _startNewConversation() async {
    try {
      final notifier = ref.read(conversationProvider.notifier);
      await notifier.createConversation(
        title: '新会话 ${DateTime.now().toIso8601String().substring(0, 16)}',
        type: widget.chatMode,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建新会话失败: $e')),
      );
    }
  }
  
  /// 复制消息到剪贴板
  void _copyMessageToClipboard(ChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('消息已复制到剪贴板')),
    );
  }
  
  /// 删除消息
  Future<void> _deleteMessage(String messageId) async {
    // 注意：此功能需要在ConversationNotifier中添加相应的方法
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('删除消息功能尚未实现')),
    );
  }
  
  // 检查状态变化并强制刷新界面
  void _checkForUpdatesAndRebuild(Conversation? conversation) {
    // 2025-03-27: 修改 - 优化会话切换检测，确保UI实时更新
    
    if (conversation == null) return;
    
    final bool conversationChanged = _lastConversationId != conversation.id;
    final bool messageCountChanged = _lastMessageCount != conversation.messages.length;
    final bool isFirstBuild = !_isInitialized;
    
    // 始终记录当前会话ID和消息数，即使没有变化
    _lastConversationId = conversation.id;
    _lastMessageCount = conversation.messages.length;
    _isInitialized = true;
    
    if (conversationChanged || messageCountChanged || isFirstBuild) {
      if (kDebugMode) {
        print('ChatInterface: 检测到更新，会话ID变化: $conversationChanged, 消息数量变化: $messageCountChanged, 首次构建: $isFirstBuild');
      }
      
      // 强制重建UI
      setState(() {});
      
      // 滚动到底部
      if (widget.autoScrollToBottom) {
        // 使用micro-task确保在渲染完成后执行滚动
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _safeScrollToBottom();
          }
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 2025-03-28: 修改 - 全面增强状态监听机制，确保会话切换能正确刷新UI
    
    // 先获取当前会话ID和会话列表状态
    final activeConversationId = ref.watch(conversationProvider.notifier).activeConversationId;
    final conversationState = ref.watch(conversationProvider);
    
    // 监听activeConversationProvider变化 - 这是一个关键点
    // 通过直接监听activeConversationProvider，当活动会话变化时能立即获得通知
    final activeConversation = ref.watch(activeConversationProvider);
    
    // 确保我们有正确的活动会话
    if (activeConversation == null && activeConversationId != null) {
      // 如果activeConversationProvider没有返回会话但有ID，尝试从state中查找
      try {
        final foundConversation = conversationState.firstWhere(
          (conv) => conv.id == activeConversationId
        );
        
        // 输出调试信息
        if (kDebugMode) {
          print('ChatInterface build: 从state中找到活动会话: ${foundConversation.id}');
        }
        
        // 检查状态更新
        _checkForUpdatesAndRebuild(foundConversation);
      } catch (e) {
        if (kDebugMode) {
          print('ChatInterface build: 未找到活动会话: $activeConversationId, 错误: $e');
        }
      }
    } else if (activeConversation != null) {
      // 如果有活动会话，检查更新
      _checkForUpdatesAndRebuild(activeConversation);
      
      // 调试输出
      if (kDebugMode) {
        print('ChatInterface build: 活动会话ID: ${activeConversation.id}');
        print('ChatInterface build: 活动会话消息数: ${activeConversation.messages.length}');
      }
    } else {
      // 没有活动会话，记录日志
      if (kDebugMode) {
        print('ChatInterface build: 没有活动会话');
      }
    }
    
    // 创建唯一的key，确保会话切换和消息数变化时能重建
    final String interfaceKey = activeConversation != null 
        ? 'chat-interface-${activeConversation.id}-${activeConversation.messages.length}'
        : 'chat-interface-none';
    
    return Column(
      key: ValueKey(interfaceKey),
      children: [
        // 聊天历史
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: activeConversation == null
                ? _buildEmptyConversation()
                : _buildMessageList(activeConversation),
          ),
        ),
      ],
    );
  }
  
  /// 构建空会话提示
  Widget _buildEmptyConversation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '没有活动的会话',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startNewConversation,
            style: ElevatedButton.styleFrom(
              backgroundColor: StandardTheme.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('开始新会话'),
          ),
        ],
      ),
    );
  }
  
  /// 构建消息列表
  Widget _buildMessageList(Conversation conversation) {
    // 2025-03-28: 修改 - 优化消息列表构建逻辑，确保UI正确反映最新状态
    
    final messages = conversation.messages;
    
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '没有消息记录',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '开始发送消息吧',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    // 2025-03-28: 修改 - 使用更稳定的listKey策略
    // 添加消息数量到key，确保当消息数量变化时列表能重建
    final listKey = PageStorageKey<String>('message_list_${conversation.id}_${messages.length}');
    
    return ListView.builder(
      key: listKey,
      controller: _scrollController,
      itemCount: messages.length + (_isLoadingMoreMessages ? 1 : 0),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        // 2025-03-28: 修改 - 优化历史消息加载指示器
        if (_isLoadingMoreMessages && index == 0) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
          );
        }
        
        final actualIndex = _isLoadingMoreMessages ? index - 1 : index;
        final message = messages[actualIndex];
        
        // 2025-03-28: 修改 - 为每个消息项添加更稳定的键，确保消息更新时能够正确重建
        return KeyedSubtree(
          key: ValueKey('msg_${message.id}_${message.timestamp.millisecondsSinceEpoch}'),
          child: _buildMessageItem(message),
        );
      },
    );
  }
  
  /// 构建单个消息项
  Widget _buildMessageItem(ChatMessage message) {
    // 根据消息类型构建不同的UI
    if (message.type == MessageType.system) {
      return _buildSystemMessage(message);
    } else if (message.type == MessageType.user) {
      return _buildUserMessage(message);
    } else {
      return _buildAssistantMessage(message);
    }
  }
  
  /// 构建系统消息
  Widget _buildSystemMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建用户消息
  Widget _buildUserMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(left: 48.0, right: 8.0, top: 8.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, message),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: StandardTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: StandardTheme.accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          widget.userAvatar ??
              CircleAvatar(
                backgroundColor: StandardTheme.accentColor.withOpacity(0.3),
                radius: 16,
                child: const Text(
                  '👤',
                  style: TextStyle(fontSize: 14),
                ),
              ),
        ],
      ),
    );
  }
  
  /// 构建助手消息
  Widget _buildAssistantMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 48.0, top: 8.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.assistantAvatar ??
              CircleAvatar(
                backgroundColor: StandardTheme.primaryColor.withOpacity(0.3),
                radius: 16,
                child: const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, message),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isLoading)
                      const TypingIndicator()
                    else if (message.hasError)
                      _buildErrorMessage(message)
                    else if (message.contentType == ContentType.code)
                      _buildCodeMessage(message)
                    else
                      StreamingTextWidget(
                        text: message.text,
                        isComplete: !message.isLoading,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建错误消息
  Widget _buildErrorMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                '出错了',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.errorMessage ?? '未知错误',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建代码消息
  Widget _buildCodeMessage(ChatMessage message) {
    // 解析文本中的代码引用
    final codeReferences = CodeBlockParser.parseCodeReferences(message.text);
    
    // 将代码块从文本中替换为占位符
    final textWithoutCodeBlocks = CodeBlockParser.replaceCodeBlocksWithPlaceholders(message.text);
    
    // 将文本按占位符分割
    final parts = textWithoutCodeBlocks.split('[CODE_BLOCK_PLACEHOLDER]');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 如果有多个文本部分和代码块，交替显示
        for (int i = 0; i < parts.length; i++) 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示文本部分
              if (parts[i].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    parts[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              // 显示代码块
              if (i < (message.codeBlocks?.length ?? 0))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CodeBlockWidget(
                    code: message.codeBlocks![i].code,
                    language: message.codeBlocks![i].language,
                    title: message.codeBlocks![i].title,
                  ),
                ),
              
              // 显示代码引用
              if (i < codeReferences.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CodeReferenceWidget(
                    reference: codeReferences[i],
                  ),
                ),
            ],
          ),
      ],
    );
  }
  
  /// 显示消息选项菜单
  void _showMessageOptions(BuildContext context, ChatMessage message) {
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
            leading: const Icon(Icons.copy, color: Colors.white),
            title: const Text('复制', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _copyMessageToClipboard(message);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('分享', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // 暂不实现分享功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能暂未实现')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(message.id);
            },
          ),
        ],
      ),
    );
  }
} 