// 2025-03-17: 新增 - 对话会话模型
// 2025-03-20: 修改 - 添加收藏字段

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'chat_message.dart';

/// 对话会话类型
enum ConversationType {
  /// 普通对话
  general,
  
  /// 代码相关对话
  coding,
  
  /// 学习相关对话
  learning,
  
  /// 咨询帮助对话
  help,
  
  /// 监护模式对话
  guardian,
  
  /// 专业模式对话
  pro,
}

/// 对话会话状态
enum ConversationStatus {
  /// 初始状态
  initial,
  
  /// 进行中
  active,
  
  /// 已暂停
  paused,
  
  /// 已完成
  completed,
  
  /// 出错
  error,
}

/// 对话会话模型
class Conversation {
  /// 会话唯一ID
  final String id;
  
  /// 会话标题
  final String title;
  
  /// 会话类型
  final ConversationType type;
  
  /// 会话状态
  final ConversationStatus status;
  
  /// 消息列表
  final List<ChatMessage> messages;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后更新时间
  final DateTime updatedAt;
  
  /// 会话上下文数据
  final Map<String, dynamic> contextData;
  
  /// 是否已保存
  final bool isSaved;
  
  /// 是否已收藏
  final bool isFavorite;
  
  /// 构造函数
  const Conversation({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.contextData = const {},
    this.isSaved = false,
    this.isFavorite = false,
  });
  
  /// 创建新会话
  factory Conversation.create({
    String? id,
    required String title,
    ConversationType type = ConversationType.general,
    List<ChatMessage>? initialMessages,
    Map<String, dynamic>? contextData,
    bool isFavorite = false,
  }) {
    final now = DateTime.now();
    
    // 如果没有初始消息，添加一个系统问候消息
    final messages = initialMessages ?? [
      ChatMessage.system(text: '新的对话已开始。有什么可以帮助你的？'),
    ];
    
    return Conversation(
      id: id ?? now.millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      status: ConversationStatus.initial,
      messages: messages,
      createdAt: now,
      updatedAt: now,
      contextData: contextData ?? {},
      isFavorite: isFavorite,
    );
  }
  
  /// 从Json创建
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ConversationType.values.firstWhere(
        (e) => e.toString() == 'ConversationType.${json['type']}',
        orElse: () => ConversationType.general,
      ),
      status: ConversationStatus.values.firstWhere(
        (e) => e.toString() == 'ConversationStatus.${json['status']}',
        orElse: () => ConversationStatus.initial,
      ),
      messages: (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      contextData: json['contextData'] as Map<String, dynamic>? ?? {},
      isSaved: json['isSaved'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
  
  /// 转换为Json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'messages': messages.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'contextData': contextData,
      'isSaved': isSaved,
      'isFavorite': isFavorite,
    };
  }
  
  /// 复制并更新会话
  Conversation copyWith({
    String? id,
    String? title,
    ConversationType? type,
    ConversationStatus? status,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? contextData,
    bool? isSaved,
    bool? isFavorite,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contextData: contextData ?? this.contextData,
      isSaved: isSaved ?? this.isSaved,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
  
  /// 添加新消息并返回新的会话对象
  Conversation addMessage(ChatMessage message) {
    final newMessages = [...messages, message];
    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
      status: message.hasError ? ConversationStatus.error : ConversationStatus.active,
    );
  }
  
  /// 添加用户文本消息
  Conversation addUserMessage(String text) {
    final message = ChatMessage.userText(text: text);
    return addMessage(message);
  }
  
  /// 添加助手文本消息
  Conversation addAssistantMessage(String text) {
    final message = ChatMessage.assistantText(text: text);
    return addMessage(message);
  }
  
  /// 添加助手代码消息
  Conversation addAssistantCodeMessage(String text, List<CodeBlock> codeBlocks) {
    final message = ChatMessage.assistantCode(
      text: text,
      codeBlocks: codeBlocks,
    );
    return addMessage(message);
  }
  
  /// 更新最后一条消息
  Conversation updateLastMessage(ChatMessage updatedMessage) {
    if (messages.isEmpty) {
      return addMessage(updatedMessage);
    }
    
    final newMessages = [...messages];
    newMessages[newMessages.length - 1] = updatedMessage;
    
    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 获取最后一条消息
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
  
  /// 更新会话状态
  Conversation updateStatus(ConversationStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 标记为已保存
  Conversation markAsSaved() {
    return copyWith(isSaved: true);
  }
  
  /// 获取最后一条用户消息
  ChatMessage? get lastUserMessage {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].type == MessageType.user) {
        return messages[i];
      }
    }
    return null;
  }
  
  /// 获取最后一条助手消息
  ChatMessage? get lastAssistantMessage {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].type == MessageType.assistant) {
        return messages[i];
      }
    }
    return null;
  }
  
  /// 清除所有错误消息
  Conversation clearErrorMessages() {
    final newMessages = messages.where((m) => !m.hasError).toList();
    return copyWith(
      messages: newMessages,
      status: ConversationStatus.active,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 更新上下文数据
  Conversation updateContextData(Map<String, dynamic> newData) {
    final mergedData = {...contextData, ...newData};
    return copyWith(
      contextData: mergedData,
      updatedAt: DateTime.now(),
    );
  }
} 