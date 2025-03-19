// 2025-03-17: 新增 - 定义聊天消息的数据模型

import 'package:flutter/material.dart';

/// 消息类型枚举
enum MessageType {
  /// 用户发送的消息
  user,
  
  /// 助手回复的消息
  assistant,
  
  /// 系统消息
  system,
}

/// 消息内容类型
enum ContentType {
  /// 纯文本
  text,
  
  /// 包含代码块
  code,
  
  /// 图片
  image,
  
  /// 包含多种类型的富文本
  richText,
}

/// 代码块数据
class CodeBlock {
  /// 代码内容
  final String code;
  
  /// 编程语言
  final String language;
  
  /// 代码块标题（可选）
  final String? title;
  
  /// 构造函数
  const CodeBlock({
    required this.code,
    required this.language,
    this.title,
  });
  
  /// 从Json创建
  factory CodeBlock.fromJson(Map<String, dynamic> json) {
    return CodeBlock(
      code: json['code'] as String,
      language: json['language'] as String,
      title: json['title'] as String?,
    );
  }
  
  /// 转换为Json
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'language': language,
      if (title != null) 'title': title,
    };
  }
}

/// 聊天消息模型
class ChatMessage {
  /// 消息唯一ID
  final String id;
  
  /// 消息类型
  final MessageType type;
  
  /// 消息内容类型
  final ContentType contentType;
  
  /// 消息文本内容
  final String text;
  
  /// 代码块列表（如果有）
  final List<CodeBlock>? codeBlocks;
  
  /// 图片URL（如果有）
  final String? imageUrl;
  
  /// 创建时间
  final DateTime timestamp;
  
  /// 是否处于加载状态（用于流式回复）
  final bool isLoading;
  
  /// 是否出错
  final bool hasError;
  
  /// 错误信息
  final String? errorMessage;
  
  /// 构造函数
  const ChatMessage({
    required this.id,
    required this.type,
    required this.contentType,
    required this.text,
    this.codeBlocks,
    this.imageUrl,
    required this.timestamp,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });
  
  /// 创建纯文本用户消息
  factory ChatMessage.userText({
    required String text,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.user,
      contentType: ContentType.text,
      text: text,
      timestamp: DateTime.now(),
    );
  }
  
  /// 创建纯文本助手消息
  factory ChatMessage.assistantText({
    required String text,
    String? id,
    bool isLoading = false,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.assistant,
      contentType: ContentType.text,
      text: text,
      timestamp: DateTime.now(),
      isLoading: isLoading,
    );
  }
  
  /// 创建包含代码块的助手消息
  factory ChatMessage.assistantCode({
    required String text,
    required List<CodeBlock> codeBlocks,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.assistant,
      contentType: ContentType.code,
      text: text,
      codeBlocks: codeBlocks,
      timestamp: DateTime.now(),
    );
  }
  
  /// 创建系统消息
  factory ChatMessage.system({
    required String text,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.system,
      contentType: ContentType.text,
      text: text,
      timestamp: DateTime.now(),
    );
  }
  
  /// 创建加载中的消息
  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      type: MessageType.assistant,
      contentType: ContentType.text,
      text: '正在思考...',
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }
  
  /// 创建错误消息
  factory ChatMessage.error({
    required String errorMessage,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? 'error_${DateTime.now().millisecondsSinceEpoch}',
      type: MessageType.system,
      contentType: ContentType.text,
      text: '出错了',
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
      hasError: true,
    );
  }
  
  /// 从Json创建
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
      ),
      contentType: ContentType.values.firstWhere(
        (e) => e.toString() == 'ContentType.${json['contentType']}',
      ),
      text: json['text'] as String,
      codeBlocks: json['codeBlocks'] != null
          ? (json['codeBlocks'] as List)
              .map((e) => CodeBlock.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      imageUrl: json['imageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
      hasError: json['hasError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
  
  /// 转换为Json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'contentType': contentType.toString().split('.').last,
      'text': text,
      if (codeBlocks != null)
        'codeBlocks': codeBlocks!.map((e) => e.toJson()).toList(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'hasError': hasError,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
  
  /// 复制一个新的消息对象，修改部分属性
  ChatMessage copyWith({
    String? id,
    MessageType? type,
    ContentType? contentType,
    String? text,
    List<CodeBlock>? codeBlocks,
    String? imageUrl,
    DateTime? timestamp,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      contentType: contentType ?? this.contentType,
      text: text ?? this.text,
      codeBlocks: codeBlocks ?? this.codeBlocks,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
} 