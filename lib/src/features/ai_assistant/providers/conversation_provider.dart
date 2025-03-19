// 2025-03-17: 新增 - 对话状态管理提供者
// 2025-03-18: 修改 - 使用LLM服务提供者替代模拟实现
// 2025-03-20: 修改 - 添加代码块解析和消息管理功能
// 2025-03-20: 修改 - 添加导出/导入和会话搜索功能

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

import '../domain/models/chat_message.dart';
import '../domain/models/conversation.dart';
import '../domain/utils/code_block_parser.dart';
import '../../../core/ai_engine/llm/llm_service.dart';
import '../../../core/ai_engine/llm/llm_service_provider.dart';
import '../../../state/providers/shared_preferences_provider.dart';

/// 聊天会话存储异常
class ConversationStorageException implements Exception {
  final String message;
  final Object? error;

  ConversationStorageException(this.message, [this.error]);

  @override
  String toString() => 'ConversationStorageException: $message${error != null ? ' - $error' : ''}';
}

/// 对话状态提供者
class ConversationNotifier extends StateNotifier<List<Conversation>> {
  final SharedPreferences _prefs;
  final Ref _ref;
  static const String _storageKey = 'ai_assistant_conversations';
  static const String _lastActiveConversationIdKey = 'ai_assistant_last_active_conversation_id';
  
  String? _activeConversationId;  // 当前活动会话ID
  
  /// 当前活动会话ID
  String? get activeConversationId => _activeConversationId;
  
  /// 构造函数
  ConversationNotifier(this._prefs, this._ref) : super([]) {
    _loadConversations();
  }
  
  /// 加载保存的会话
  Future<void> _loadConversations() async {
    try {
      final String? jsonStr = _prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        return;
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
      final List<Conversation> conversations = jsonList
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
      
      state = conversations;
      
      // 设置最后一个会话为活动会话（如果有）
      if (conversations.isNotEmpty) {
        _activeConversationId = conversations.last.id;
      }
      
      if (kDebugMode) {
        print('已加载 ${conversations.length} 个会话');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('加载会话失败: $e');
        print('堆栈跟踪: $stackTrace');
      }
      throw ConversationStorageException('加载会话失败', e);
    }
  }
  
  /// 保存会话到持久化存储
  Future<void> _saveConversations() async {
    try {
      final jsonList = state.map((conv) => conv.toJson()).toList();
      final jsonStr = jsonEncode(jsonList);
      await _prefs.setString(_storageKey, jsonStr);
      
      if (kDebugMode) {
        print('已保存 ${state.length} 个会话');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('保存会话失败: $e');
        print('堆栈跟踪: $stackTrace');
      }
      throw ConversationStorageException('保存会话失败', e);
    }
  }
  
  /// 创建新会话
  Future<Conversation> createConversation({
    required String title,
    ConversationType type = ConversationType.general,
    List<ChatMessage>? initialMessages,
    Map<String, dynamic>? contextData,
  }) async {
    final conversation = Conversation.create(
      title: title,
      type: type,
      initialMessages: initialMessages,
      contextData: contextData,
    );
    
    final newState = [...state, conversation];
    state = newState;
    _activeConversationId = conversation.id;
    
    await _saveConversations();
    return conversation;
  }
  
  /// 获取当前活动会话
  Conversation? get activeConversation {
    // 如果没有活动会话ID，返回null
    if (_activeConversationId == null) {
      return null;
    }
    
    try {
      // 查找活动会话
      return state.firstWhere(
        (conv) => conv.id == _activeConversationId,
      );
    } catch (e) {
      // 如果找不到活动会话，重置活动会话ID并返回null
      if (kDebugMode) {
        print('ConversationProvider: 找不到活动会话 $_activeConversationId，重置活动会话ID');
      }
      _activeConversationId = null;
      return null;
    }
  }
  
  /// 设置活动会话
  Future<void> setActiveConversation(String conversationId) async {
    // 2025-03-28: 修改 - 全面增强会话切换逻辑，提高稳定性和错误处理
    
    try {
      // 验证会话ID
      if (conversationId.isEmpty) {
        throw ConversationStorageException('会话ID不能为空');
      }
      
      // 确认会话存在
      final conversationIndex = state.indexWhere((conv) => conv.id == conversationId);
      if (conversationIndex == -1) {
        throw ConversationStorageException('会话不存在: $conversationId');
      }
      
      // 获取目标会话对象
      final targetConversation = state[conversationIndex];
      
      // 如果已经是当前活动会话，不需要执行任何操作
      if (_activeConversationId == conversationId) {
        if (kDebugMode) {
          print('ConversationProvider: 已经是当前活动会话，无需切换');
        }
        return;
      }
      
      // 保存旧的活动会话ID（用于日志记录和可能的回滚）
      final previousActiveId = _activeConversationId;
      
      // 设置新的活动会话ID
      _activeConversationId = conversationId;
      
      if (kDebugMode) {
        print('ConversationProvider: 切换活动会话从 $previousActiveId 到 $conversationId (${targetConversation.title})');
      }
      
      // 确保UI得到通知 - 创建一个新的状态列表
      final newState = List<Conversation>.from(state);
      
      // 更新目标会话的最后访问时间
      final updatedTargetConversation = targetConversation.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // 更新状态
      newState[conversationIndex] = updatedTargetConversation;
      state = newState;
      
      // 保存最后活动的会话ID
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastActiveConversationIdKey, conversationId);
        
        if (kDebugMode) {
          print('ConversationProvider: 已保存最后活动会话ID: $conversationId');
        }
      } catch (storageError) {
        // 即使保存失败，也不影响会话切换，但记录错误
        if (kDebugMode) {
          print('ConversationProvider: 保存最后活动会话ID失败: $storageError');
        }
      }
      
      // 保存会话状态
      await _saveConversations();
      
    } catch (e) {
      if (kDebugMode) {
        print('ConversationProvider: 切换会话失败: $e');
      }
      // 重新抛出异常，让上层处理
      rethrow;
    }
  }
  
  /// 添加用户消息到活动会话
  Future<void> addUserMessage(String text) async {
    if (_activeConversationId == null) {
      // 如果没有活动会话，创建一个新的
      await createConversation(
        title: '新会话',
        initialMessages: [ChatMessage.userText(text: text)],
      );
      return;
    }
    
    final conversation = activeConversation;
    if (conversation == null) return;
    
    final updatedConversation = conversation.addUserMessage(text);
    _updateConversation(updatedConversation);
    
    await _saveConversations();
  }
  
  /// 发送消息到LLM并获取回复
  Future<void> sendMessageToLLM(String userText) async {
    // 2025-03-24: 修改 - 重构发送消息逻辑，确保状态更新能立即触发UI刷新
    
    if (kDebugMode) {
      print('开始发送消息: $userText');
    }
    
    // 先添加用户消息
    await addUserMessage(userText);
    
    // 获取当前会话
    var conversation = activeConversation;
    if (conversation == null) {
      if (kDebugMode) {
        print('错误: 无活动会话');
      }
      return;
    }
    
    try {
      // 创建一个唯一的消息ID
      final messageId = const Uuid().v4();
      
      // 添加Loading状态消息
      final loadingMessage = ChatMessage(
        id: messageId,
        type: MessageType.assistant,
        contentType: ContentType.text,
        text: '',
        isLoading: true,
        timestamp: DateTime.now(),
      );
      
      // 先添加加载中消息，立即更新UI
      final conversationWithLoading = conversation.addMessage(loadingMessage);
      _forceUpdateConversation(conversationWithLoading);
      await _saveConversations();
      
      if (kDebugMode) {
        print('添加加载中消息，ID: $messageId');
      }
      
      // 发送请求
      final llmNotifier = _ref.read(llmServiceProvider.notifier);
      final response = await llmNotifier.processRequest(userText);
      
      // 重新获取最新的会话状态
      conversation = activeConversation;
      if (conversation == null) {
        if (kDebugMode) {
          print('错误: 发送请求后无活动会话');
        }
        return;
      }
      
      // 解析内容
      final codeBlocks = CodeBlockParser.parseCodeBlocks(response);
      final codeReferences = CodeBlockParser.parseCodeReferences(response);
      
      // 检测内容类型
      ContentType contentType = ContentType.text;
      if (codeBlocks.isNotEmpty || codeReferences.isNotEmpty) {
        contentType = ContentType.code;
      }
      
      // 查找之前添加的加载中消息
      final loadingMessageIndex = conversation.messages.indexWhere(
        (msg) => msg.id == messageId && msg.isLoading
      );
      
      if (loadingMessageIndex == -1) {
        if (kDebugMode) {
          print('警告: 未找到加载中消息，添加新消息');
        }
        
        // 如果找不到加载中消息，直接添加新消息
        final newMessage = ChatMessage(
          id: const Uuid().v4(),
          type: MessageType.assistant,
          text: response,
          contentType: contentType,
          codeBlocks: codeBlocks,
          timestamp: DateTime.now(),
        );
        
        final updatedConversation = conversation.addMessage(newMessage);
        _forceUpdateConversation(updatedConversation);
      } else {
        // 更新加载中消息
        if (kDebugMode) {
          print('更新加载中消息为完成状态');
        }
        
        final newMessages = List<ChatMessage>.from(conversation.messages);
        newMessages[loadingMessageIndex] = ChatMessage(
          id: messageId,
          type: MessageType.assistant,
          text: response,
          contentType: contentType,
          codeBlocks: codeBlocks,
          timestamp: DateTime.now(),
        );
        
        final updatedConversation = conversation.copyWith(
          messages: newMessages,
          updatedAt: DateTime.now(),
        );
        
        _forceUpdateConversation(updatedConversation);
      }
      
      await _saveConversations();
      
    } catch (e) {
      if (kDebugMode) {
        print('发送消息失败: $e');
      }
      
      // 重新获取最新会话状态
      conversation = activeConversation;
      if (conversation == null) return;
      
      // 查找加载中的消息并将其标记为错误
      final loadingMessage = conversation.messages.lastWhereOrNull(
        (msg) => msg.isLoading && msg.type == MessageType.assistant
      );
      
      if (loadingMessage != null) {
        // 将加载中消息替换为错误消息
        final errorMessage = ChatMessage.error(
          errorMessage: '获取回复失败: $e',
          id: loadingMessage.id,
        );
        
        final newMessages = List<ChatMessage>.from(conversation.messages);
        final index = newMessages.indexWhere((msg) => msg.id == loadingMessage.id);
        
        if (index != -1) {
          newMessages[index] = errorMessage;
          
          final errorConversation = conversation.copyWith(
            messages: newMessages,
            updatedAt: DateTime.now(),
          );
          
          _forceUpdateConversation(errorConversation);
          await _saveConversations();
        }
      }
    }
  }
  
  /// 强制更新会话并触发UI刷新
  void _forceUpdateConversation(Conversation updatedConversation) {
    // 2025-03-24: 添加 - 强制更新会话的方法，确保状态变更能立即反映到UI
    final newState = state.map((conv) {
      if (conv.id == updatedConversation.id) {
        // 返回全新的对象，确保状态变更能被检测到
        return Conversation(
          id: updatedConversation.id,
          title: updatedConversation.title,
          type: updatedConversation.type,
          status: updatedConversation.status,
          messages: List<ChatMessage>.from(updatedConversation.messages),
          createdAt: updatedConversation.createdAt,
          updatedAt: DateTime.now(), // 使用当前时间，确保时间戳不同
          contextData: Map<String, dynamic>.from(updatedConversation.contextData),
          isSaved: updatedConversation.isSaved,
          isFavorite: updatedConversation.isFavorite,
        );
      }
      return conv;
    }).toList();
    
    // 更新状态，触发UI更新
    state = newState;
  }
  
  /// 更新指定会话
  void _updateConversation(Conversation updatedConversation) {
    // 2025-03-24: 修改 - 优化会话更新逻辑，确保状态变更能触发UI更新
    
    // 创建新的状态列表，避免引用问题
    final newState = state.map((conv) {
      if (conv.id == updatedConversation.id) {
        // 返回更新后的会话，确保创建新对象
        return Conversation(
          id: updatedConversation.id,
          title: updatedConversation.title,
          type: updatedConversation.type,
          status: updatedConversation.status,
          messages: List.from(updatedConversation.messages),
          createdAt: updatedConversation.createdAt,
          updatedAt: DateTime.now(), // 始终更新时间戳，确保状态变更能被检测到
          contextData: Map.from(updatedConversation.contextData),
          isSaved: updatedConversation.isSaved,
          isFavorite: updatedConversation.isFavorite,
        );
      }
      return conv;
    }).toList();
    
    // 更新状态
    state = newState;
    
    // 如果是当前活动会话，确保_activeConversationId正确设置
    if (_activeConversationId == updatedConversation.id) {
      // 重新触发活动会话的更新
      _activeConversationId = updatedConversation.id;
    }
  }
  
  /// 添加系统消息到当前活动会话
  Future<void> addSystemMessage(String text) async {
    if (_activeConversationId == null) {
      throw ConversationStorageException('没有活动会话');
    }
    
    final conversation = activeConversation;
    if (conversation == null) return;
    
    final systemMessage = ChatMessage(
      id: const Uuid().v4(),
      type: MessageType.system,
      contentType: ContentType.text,
      text: text,
      timestamp: DateTime.now(),
    );
    
    final updatedConversation = conversation.addMessage(systemMessage);
    _updateConversation(updatedConversation);
    
    await _saveConversations();
  }
  
  /// 清空指定会话的所有消息
  Future<void> clearConversationMessages(String conversationId) async {
    final conversationIndex = state.indexWhere((conv) => conv.id == conversationId);
    if (conversationIndex == -1) {
      throw ConversationStorageException('会话不存在: $conversationId');
    }
    
    final conversation = state[conversationIndex];
    final updatedConversation = conversation.copyWith(messages: []);
    
    final newState = List<Conversation>.from(state);
    newState[conversationIndex] = updatedConversation;
    state = newState;
    
    await _saveConversations();
  }
  
  /// 删除指定消息
  Future<void> deleteMessage(String conversationId, String messageId) async {
    final conversation = state.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => throw ConversationStorageException('会话不存在: $conversationId'),
    );
    
    // 过滤掉要删除的消息
    final updatedMessages = conversation.messages
        .where((message) => message.id != messageId)
        .toList();
    
    // 创建更新后的会话
    final updatedConversation = conversation.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    
    _updateConversation(updatedConversation);
    await _saveConversations();
  }
  
  /// 删除会话
  Future<void> deleteConversation(String conversationId) async {
    final newState = state.where((conv) => conv.id != conversationId).toList();
    state = newState;
    
    // 如果删除的是当前活动会话，将最新的会话设为活动会话
    if (_activeConversationId == conversationId) {
      _activeConversationId = newState.isNotEmpty ? newState.last.id : null;
    }
    
    await _saveConversations();
  }
  
  /// 清除所有会话
  Future<void> clearAllConversations() async {
    state = [];
    _activeConversationId = null;
    await _saveConversations();
  }
  
  /// 重命名会话
  Future<void> renameConversation(String conversationId, String newTitle) async {
    final conversation = state.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => null as Conversation,
    );
    
    if (conversation == null) {
      throw ConversationStorageException('会话不存在: $conversationId');
    }
    
    final updatedConversation = conversation.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    
    _updateConversation(updatedConversation);
    await _saveConversations();
  }
  
  /// 获取指定会话
  Conversation? getConversation(String conversationId) {
    return state.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => null as Conversation,
    );
  }
  
  /// 获取最近会话列表（最新的n个会话）
  List<Conversation> getRecentConversations(int limit) {
    final sortedConversations = [...state];
    sortedConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return sortedConversations.take(limit).toList();
  }
  
  /// 根据类型获取会话列表
  List<Conversation> getConversationsByType(ConversationType type) {
    return state.where((conv) => conv.type == type).toList();
  }
  
  /// 根据关键词搜索会话
  List<Conversation> searchConversations(String keyword) {
    if (keyword.isEmpty) return state;
    
    final searchTerm = keyword.toLowerCase();
    return state.where((conv) {
      // 搜索标题
      if (conv.title.toLowerCase().contains(searchTerm)) {
        return true;
      }
      
      // 搜索消息内容
      for (final message in conv.messages) {
        if (message.text.toLowerCase().contains(searchTerm)) {
          return true;
        }
      }
      
      return false;
    }).toList();
  }
  
  /// 标记会话为喜欢/收藏
  Future<void> toggleFavoriteConversation(String conversationId) async {
    final conversation = getConversation(conversationId);
    if (conversation == null) {
      throw ConversationStorageException('会话不存在: $conversationId');
    }
    
    final updatedConversation = conversation.copyWith(
      isFavorite: !conversation.isFavorite,
      updatedAt: DateTime.now(),
    );
    
    // 使用_forceUpdateConversation而不是_updateConversation，确保UI立即更新
    _forceUpdateConversation(updatedConversation);
    
    // 输出调试信息
    if (kDebugMode) {
      print('会话收藏状态已更新: ${conversation.title}, isFavorite: ${!conversation.isFavorite}');
    }
    
    await _saveConversations();
  }
  
  /// 导出会话到JSON文件
  Future<String> exportConversation(String conversationId) async {
    try {
      final conversation = getConversation(conversationId);
      if (conversation == null) {
        throw ConversationStorageException('会话不存在: $conversationId');
      }
      
      final conversationJson = conversation.toJson();
      final jsonStr = jsonEncode(conversationJson);
      
      // 获取应用文档目录
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${conversation.title.replaceAll(RegExp(r'[^\w]'), '_')}_$timestamp.json';
      final filePath = '${dir.path}/conversations/$fileName';
      
      // 确保目录存在
      final conversationsDir = Directory('${dir.path}/conversations');
      if (!await conversationsDir.exists()) {
        await conversationsDir.create(recursive: true);
      }
      
      // 写入文件
      final file = File(filePath);
      await file.writeAsString(jsonStr);
      
      if (kDebugMode) {
        print('会话已导出到: $filePath');
      }
      
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('导出会话失败: $e');
      }
      rethrow;
    }
  }
  
  /// 导入会话从JSON文件
  Future<Conversation> importConversation(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ConversationStorageException('文件不存在: $filePath');
      }
      
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final importedConversation = Conversation.fromJson(json);
      
      // 检查是否已存在相同ID的会话
      final existingIndex = state.indexWhere((conv) => conv.id == importedConversation.id);
      if (existingIndex >= 0) {
        // 为导入的会话生成新ID，并更新时间戳
        final uuid = Uuid();
        final newConversation = importedConversation.copyWith(
          id: uuid.v4(),
          title: '${importedConversation.title} (导入)',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        state = [...state, newConversation];
        _activeConversationId = newConversation.id;
      } else {
        state = [...state, importedConversation];
        _activeConversationId = importedConversation.id;
      }
      
      await _saveConversations();
      
      if (kDebugMode) {
        print('会话已导入: ${importedConversation.title}');
      }
      
      return getConversation(_activeConversationId!)!;
    } catch (e) {
      if (kDebugMode) {
        print('导入会话失败: $e');
      }
      rethrow;
    }
  }
  
  /// 获取收藏的会话
  List<Conversation> getFavoriteConversations() {
    return state.where((conv) => conv.isFavorite).toList();
  }
  
  /// 按类型获取最近的会话
  List<Conversation> getRecentConversationsByType(ConversationType type, {int limit = 10}) {
    final filteredConversations = state
        .where((conv) => conv.type == type)
        .toList();
    
    filteredConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return filteredConversations.take(limit).toList();
  }
  
  /// 更新会话标题
  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    // 2025-03-25: 新增 - 添加更新会话标题功能
    
    // 确认会话存在
    final conversationIndex = state.indexWhere((conv) => conv.id == conversationId);
    if (conversationIndex == -1) {
      throw ConversationStorageException('会话不存在: $conversationId');
    }
    
    // 获取当前会话
    final conversation = state[conversationIndex];
    
    // 创建更新后的会话
    final updatedConversation = conversation.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    
    // 更新状态
    final newState = List<Conversation>.from(state);
    newState[conversationIndex] = updatedConversation;
    state = newState;
    
    // 持久化保存
    await _saveConversations();
    
    if (kDebugMode) {
      print('ConversationProvider: 会话标题已更新为: $newTitle');
    }
  }
}

/// 对话提供者
final conversationProvider = StateNotifierProvider<ConversationNotifier, List<Conversation>>((ref) {
  // 使用已经初始化的SharedPreferences
  final prefs = ref.watch(sharedPreferencesProvider);
  return ConversationNotifier(prefs, ref);
});

/// 活动会话提供者
final activeConversationProvider = Provider<Conversation?>((ref) {
  // 2025-03-28: 修改 - 增强活动会话提供逻辑，确保能正确提供当前活动会话
  
  // 监听整个会话列表，当列表变化时重新评估
  final conversations = ref.watch(conversationProvider);
  
  // 获取活动会话ID
  final notifier = ref.watch(conversationProvider.notifier);
  final activeId = notifier.activeConversationId;
  
  if (activeId == null) {
    if (kDebugMode) {
      print('activeConversationProvider: 没有活动会话ID');
    }
    return null;
  }
  
  try {
    // 查找活动会话
    final activeConversation = conversations.firstWhere(
      (conv) => conv.id == activeId,
    );
    
    if (kDebugMode) {
      print('activeConversationProvider: 找到活动会话 ${activeConversation.id} (${activeConversation.title})');
    }
    
    return activeConversation;
  } catch (e) {
    // 如果找不到活动会话，记录错误
    if (kDebugMode) {
      print('activeConversationProvider: 无法找到活动会话 $activeId, 错误: $e');
    }
    
    // 通知ConversationNotifier重置活动会话ID
    // 注意：这里不能直接调用notifier方法，因为可能导致循环依赖
    // 只能返回null，让上层处理
    return null;
  }
});

/// 最近会话提供者
final recentConversationsProvider = Provider<List<Conversation>>((ref) {
  final notifier = ref.watch(conversationProvider.notifier);
  return notifier.getRecentConversations(5);
}); 