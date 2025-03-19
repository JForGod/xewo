import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../datasources/local/chat_local_datasource.dart';
import '../datasources/remote/chat_remote_datasource.dart';
import '../../../../core/services/logging/logging_service.dart';
import '../../../../core/services/error/error_handling_service.dart';

/// 聊天仓库实现
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource _localDataSource;
  final ChatRemoteDataSource? _remoteDataSource;
  final LoggingService _loggingService;
  final ErrorHandlingService _errorHandlingService;
  
  /// 消息流控制器映射表
  final Map<String, StreamController<ChatMessage>> _messageControllers = {};
  
  /// 构造函数
  ChatRepositoryImpl({
    required ChatLocalDataSource localDataSource,
    ChatRemoteDataSource? remoteDataSource,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService;
  
  @override
  // 2025-03-16 + 获取特定会话功能
  Future<Conversation?> getConversation(String id) async {
    try {
      // 先尝试从本地获取
      final localConversation = await _localDataSource.getConversation(id);
      
      // 如果本地没有且远程数据源可用，尝试从远程获取
      if (localConversation == null && _remoteDataSource != null) {
        final remoteConversation = await _remoteDataSource!.getConversation(id);
        
        // 如果远程有，保存到本地
        if (remoteConversation != null) {
          await _localDataSource.saveConversation(remoteConversation);
          return remoteConversation;
        }
      }
      
      return localConversation;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取会话失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 获取所有会话功能
  Future<List<Conversation>> getAllConversations() async {
    try {
      // 获取本地会话
      final localConversations = await _localDataSource.getAllConversations();
      
      // 如果远程数据源可用，同步远程会话
      if (_remoteDataSource != null) {
        try {
          final remoteConversations = await _remoteDataSource!.getAllConversations();
          
          // 合并本地和远程会话
          await _mergeConversations(localConversations, remoteConversations);
          
          // 重新获取本地会话（现在包含同步后的数据）
          return await _localDataSource.getAllConversations();
        } catch (e) {
          _loggingService.warning('同步远程会话失败', tags: {'error': e.toString()});
          // 如果远程同步失败，仍返回本地数据
        }
      }
      
      return localConversations;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取所有会话失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 创建新会话功能
  Future<Conversation> createConversation({
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 创建新的会话对象
      final conversation = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messageCount: 0,
        lastMessagePreview: '',
        tags: [],
        metadata: metadata ?? {},
      );
      
      // 保存到本地
      await _localDataSource.saveConversation(conversation);
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveConversation(conversation);
        } catch (e) {
          _loggingService.warning('保存会话到远程失败', tags: {'error': e.toString()});
        }
      }
      
      return conversation;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '创建会话失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 更新会话信息功能
  Future<void> updateConversation(Conversation conversation) async {
    try {
      // 更新本地数据
      await _localDataSource.saveConversation(conversation.copyWith(
        updatedAt: DateTime.now(),
      ));
      
      // 如果远程数据源可用，也更新远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveConversation(conversation);
        } catch (e) {
          _loggingService.warning('更新远程会话失败', tags: {'error': e.toString()});
        }
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '更新会话失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 删除会话功能
  Future<void> deleteConversation(String id) async {
    try {
      // 删除本地数据
      await _localDataSource.deleteConversation(id);
      
      // 如果远程数据源可用，也删除远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.deleteConversation(id);
        } catch (e) {
          _loggingService.warning('删除远程会话失败', tags: {'error': e.toString()});
        }
      }
      
      // 关闭对应的消息流控制器
      if (_messageControllers.containsKey(id)) {
        await _messageControllers[id]!.close();
        _messageControllers.remove(id);
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '删除会话失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 添加消息功能
  Future<void> addMessage(String conversationId, ChatMessage message) async {
    try {
      // 获取会话
      final conversation = await getConversation(conversationId);
      if (conversation == null) throw Exception('会话不存在');
      
      // 保存消息到本地
      await _localDataSource.saveMessage(conversationId, message);
      
      // 更新会话信息
      await updateConversation(conversation.copyWith(
        messageCount: conversation.messageCount + 1,
        lastMessagePreview: message.content.length > 50
            ? '${message.content.substring(0, 47)}...'
            : message.content,
        updatedAt: DateTime.now(),
      ));
      
      // 如果远程数据源可用，也保存到远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveMessage(conversationId, message);
        } catch (e) {
          _loggingService.warning('保存消息到远程失败', tags: {'error': e.toString()});
        }
      }
      
      // 发送到消息流
      _addMessageToStream(conversationId, message);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '添加消息失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 更新消息功能
  Future<void> updateMessage(String conversationId, ChatMessage message) async {
    try {
      // 保存更新的消息到本地
      await _localDataSource.saveMessage(conversationId, message);
      
      // 如果远程数据源可用，也更新远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.saveMessage(conversationId, message);
        } catch (e) {
          _loggingService.warning('更新远程消息失败', tags: {'error': e.toString()});
        }
      }
      
      // 发送到消息流
      _addMessageToStream(conversationId, message);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '更新消息失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 删除消息功能
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      // 删除本地消息
      await _localDataSource.deleteMessage(conversationId, messageId);
      
      // 如果远程数据源可用，也删除远程
      if (_remoteDataSource != null) {
        try {
          await _remoteDataSource!.deleteMessage(conversationId, messageId);
        } catch (e) {
          _loggingService.warning('删除远程消息失败', tags: {'error': e.toString()});
        }
      }
      
      // 更新会话信息
      final conversation = await getConversation(conversationId);
      if (conversation != null) {
        final messages = await getMessages(conversationId, limit: 1);
        final lastMessagePreview = messages.isNotEmpty
            ? (messages[0].content.length > 50
                ? '${messages[0].content.substring(0, 47)}...'
                : messages[0].content)
            : '';
            
        await updateConversation(conversation.copyWith(
          messageCount: conversation.messageCount - 1,
          lastMessagePreview: lastMessagePreview,
        ));
      }
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '删除消息失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 获取会话消息功能
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
    DateTime? before,
    DateTime? after,
  }) async {
    try {
      // 从本地获取消息
      final localMessages = await _localDataSource.getMessages(
        conversationId,
        limit: limit,
        offset: offset,
        before: before,
        after: after,
      );
      
      // 如果远程数据源可用且本地消息较少，尝试从远程获取
      if (_remoteDataSource != null && 
          (localMessages.isEmpty || (limit != null && localMessages.length < limit))) {
        try {
          final remoteMessages = await _remoteDataSource!.getMessages(
            conversationId,
            limit: limit,
            offset: offset,
            before: before,
            after: after,
          );
          
          // 保存远程消息到本地
          for (final message in remoteMessages) {
            if (!localMessages.any((m) => m.id == message.id)) {
              await _localDataSource.saveMessage(conversationId, message);
            }
          }
          
          // 重新获取本地消息
          return await _localDataSource.getMessages(
            conversationId,
            limit: limit,
            offset: offset,
            before: before,
            after: after,
          );
        } catch (e) {
          _loggingService.warning('获取远程消息失败', tags: {'error': e.toString()});
          // 如果远程获取失败，仍返回本地数据
        }
      }
      
      return localMessages;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '获取消息失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 搜索消息功能
  Future<List<ChatMessage>> searchMessages(
    String query, {
    String? conversationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // 从本地搜索消息
      final localResults = await _localDataSource.searchMessages(
        query,
        conversationId: conversationId,
        startDate: startDate,
        endDate: endDate,
      );
      
      // 如果远程数据源可用，也从远程搜索
      if (_remoteDataSource != null) {
        try {
          final remoteResults = await _remoteDataSource!.searchMessages(
            query,
            conversationId: conversationId,
            startDate: startDate,
            endDate: endDate,
          );
          
          // 合并结果并去重
          final allResults = [...localResults];
          for (final message in remoteResults) {
            if (!allResults.any((m) => m.id == message.id)) {
              allResults.add(message);
              
              // 保存到本地以便将来查询
              if (conversationId != null) {
                await _localDataSource.saveMessage(conversationId, message);
              } else {
                // 如果没有会话ID，需要先确定消息所属的会话
                final messageConversation = remoteResults
                    .firstWhere((m) => m.id == message.id)
                    .metadata['conversation_id'] as String?;
                    
                if (messageConversation != null) {
                  await _localDataSource.saveMessage(messageConversation, message);
                }
              }
            }
          }
          
          return allResults;
        } catch (e) {
          _loggingService.warning('搜索远程消息失败', tags: {'error': e.toString()});
          // 如果远程搜索失败，仍返回本地结果
        }
      }
      
      return localResults;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '搜索消息失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 获取消息流功能
  Stream<ChatMessage> getMessageStream(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      // 为每个会话创建一个单独的流控制器
      _messageControllers[conversationId] = StreamController<ChatMessage>.broadcast();
      
      // 初始加载最近的消息到流
      _initializeMessageStream(conversationId);
    }
    
    return _messageControllers[conversationId]!.stream;
  }
  
  @override
  // 2025-03-16 + 设置会话标签功能
  Future<void> setConversationTags(String conversationId, List<String> tags) async {
    try {
      // 获取会话
      final conversation = await getConversation(conversationId);
      if (conversation == null) throw Exception('会话不存在');
      
      // 更新标签
      final updatedConversation = conversation.copyWith(tags: tags);
      
      // 保存更新后的会话
      await updateConversation(updatedConversation);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '设置会话标签失败',
      );
      rethrow;
    }
  }
  
  @override
  // 2025-03-16 + 设置消息标记功能
  Future<void> markMessage(
    String conversationId,
    String messageId,
    MessageMarkType type,
    bool value,
  ) async {
    try {
      // 获取消息
      final messages = await getMessages(
        conversationId,
        limit: 1,
        offset: 0,
      );
      
      final message = messages.firstWhere(
        (m) => m.id == messageId,
        orElse: () => throw Exception('消息不存在'),
      );
      
      // 更新消息标记
      final metadata = Map<String, dynamic>.from(message.metadata);
      metadata['marks'] = metadata['marks'] ?? <String, bool>{};
      (metadata['marks'] as Map<String, bool>)[type.toString()] = value;
      
      // 创建更新后的消息
      final updatedMessage = message.copyWith(metadata: metadata);
      
      // 保存更新后的消息
      await updateMessage(conversationId, updatedMessage);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.database,
        severity: ErrorSeverity.medium,
        message: '标记消息失败',
      );
      rethrow;
    }
  }
  
  // 2025-03-16 + 合并会话功能
  Future<void> _mergeConversations(
    List<Conversation> localConversations, 
    List<Conversation> remoteConversations,
  ) async {
    try {
      // 创建本地会话ID的集合，用于快速查找
      final localIds = localConversations.map((c) => c.id).toSet();
      
      // 遍历远程会话
      for (final remoteConversation in remoteConversations) {
        // 本地不存在的会话，添加到本地
        if (!localIds.contains(remoteConversation.id)) {
          await _localDataSource.saveConversation(remoteConversation);
          
        } else {
          // 本地已存在的会话，比较更新时间
          final localConversation = localConversations.firstWhere(
            (c) => c.id == remoteConversation.id,
          );
          
          // 远程版本更新，则更新本地
          if (remoteConversation.updatedAt.isAfter(localConversation.updatedAt)) {
            await _localDataSource.saveConversation(remoteConversation);
          }
        }
      }
    } catch (e) {
      _loggingService.error('合并会话失败', tags: {'error': e.toString()});
    }
  }
  
  // 2025-03-16 + 初始化消息流功能
  Future<void> _initializeMessageStream(String conversationId) async {
    try {
      // 获取最近的消息
      final recentMessages = await getMessages(
        conversationId,
        limit: 20,
      );
      
      // 按时间排序
      recentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // 将消息添加到流
      for (final message in recentMessages) {
        _messageControllers[conversationId]?.add(message);
      }
    } catch (e) {
      _loggingService.error('初始化消息流失败', tags: {
        'error': e.toString(),
        'conversation_id': conversationId,
      });
    }
  }
  
  // 2025-03-16 + 添加消息到流功能
  void _addMessageToStream(String conversationId, ChatMessage message) {
    if (_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId]!.add(message);
    }
  }
  
  // 2025-03-16 + 释放资源功能
  Future<void> dispose() async {
    // 关闭所有流控制器
    for (final controller in _messageControllers.values) {
      await controller.close();
    }
    _messageControllers.clear();
  }
}

/// 聊天仓库提供者
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final localDataSource = ref.watch(chatLocalDataSourceProvider);
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final repository = ChatRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
  );
  
  ref.onDispose(() {
    if (repository is ChatRepositoryImpl) {
      repository.dispose();
    }
  });
  
  return repository;
});
