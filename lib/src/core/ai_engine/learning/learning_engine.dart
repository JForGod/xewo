import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../knowledge/knowledge_base.dart';
import '../knowledge/graph_manager.dart';
import '../llm/llm_service.dart';
import '../../../services/logging/logging_service.dart';
import '../../../services/error/error_handling_service.dart';
import '../../../services/state_management/state_service.dart';

/// 学习源类型
enum LearningSourceType {
  /// 用户交互
  userInteraction,
  
  /// 文档
  document,
  
  /// 网页内容
  webContent,
  
  /// 应用内操作
  appAction,
  
  /// 系统数据
  systemData,
  
  /// 外部API
  externalApi,
}

/// 学习事件
class LearningEvent {
  /// 事件ID
  final String id;
  
  /// 事件源类型
  final LearningSourceType sourceType;
  
  /// 事件内容
  final String content;
  
  /// 相关标签
  final List<String> tags;
  
  /// 重要性
  final double importance;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 元数据
  final Map<String, dynamic> metadata;
  
  /// 构造函数
  LearningEvent({
    required this.id,
    required this.sourceType,
    required this.content,
    this.tags = const [],
    this.importance = 0.5,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 从Map创建学习事件
  factory LearningEvent.fromMap(Map<String, dynamic> map) {
    return LearningEvent(
      id: map['id'],
      sourceType: LearningSourceType.values.byName(map['sourceType']),
      content: map['content'],
      tags: List<String>.from(map['tags'] ?? []),
      importance: (map['importance'] ?? 0.5) as double,
      timestamp: DateTime.parse(map['timestamp']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceType': sourceType.name,
      'content': content,
      'tags': tags,
      'importance': importance,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// 学习结果
class LearningResult {
  /// 结果状态
  final bool success;
  
  /// 知识ID
  final String? knowledgeId;
  
  /// 学习过程摘要
  final String summary;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  LearningResult({
    required this.success,
    this.knowledgeId,
    required this.summary,
    this.details = const {},
  });
}

/// 学习策略
abstract class LearningStrategy {
  /// 处理学习事件
  Future<LearningResult> processEvent(
    LearningEvent event,
    LLMService llmService,
    KnowledgeBase knowledgeBase,
    [GraphManager? graphManager]
  );
  
  /// 获取策略名称
  String get name;
  
  /// 获取策略描述
  String get description;
  
  /// 获取支持的源类型
  List<LearningSourceType> get supportedSourceTypes;
}

/// 基本提取策略
class BasicExtractionStrategy implements LearningStrategy {
  @override
  Future<LearningResult> processEvent(
    LearningEvent event,
    LLMService llmService,
    KnowledgeBase knowledgeBase,
    [GraphManager? graphManager]
  ) async {
    try {
      // 1. 使用LLM处理内容以提取知识
      final prompt = '''
请分析以下内容，提取关键知识点：
---
${event.content}
---
提取格式:
标题:
知识点:
相关标签: (逗号分隔)
重要性: (0.1到1.0的数值)
''';
      
      final result = await llmService.processInput(
        prompt,
        [],
        LLMProcessingOptions(
          temperature: 0.3,
          maxTokens: 1000,
        ),
      );
      
      if (!result.success) {
        return LearningResult(
          success: false,
          summary: '处理内容失败',
          details: {'error': result.responseText},
        );
      }
      
      // 2. 解析输出
      final response = result.responseText;
      final titleMatch = RegExp(r'标题:(.*?)\n').firstMatch(response);
      final contentMatch = RegExp(r'知识点:(.*?)(?=相关标签:|$)', dotAll: true).firstMatch(response);
      final tagsMatch = RegExp(r'相关标签:(.*?)(?=重要性:|$)').firstMatch(response);
      final importanceMatch = RegExp(r'重要性:(.*?)(?=\n|$)').firstMatch(response);
      
      if (titleMatch == null || contentMatch == null) {
        return LearningResult(
          success: false,
          summary: '解析内容失败',
          details: {'response': response},
        );
      }
      
      final title = titleMatch.group(1)?.trim() ?? '未命名知识';
      final content = contentMatch.group(1)?.trim() ?? '';
      final tagsText = tagsMatch?.group(1)?.trim() ?? '';
      final tags = tagsText.split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
      
      // 添加源类型标签
      tags.add(event.sourceType.name);
      
      // 解析重要性
      double importance = event.importance;
      if (importanceMatch != null) {
        final importanceStr = importanceMatch.group(1)?.trim() ?? '';
        try {
          importance = double.parse(importanceStr);
          importance = importance.clamp(0.1, 1.0);
        } catch (e) {
          print('解析重要性失败: $e');
        }
      }
      
      // 3. 生成嵌入向量
      List<double>? embedding;
      try {
        embedding = await knowledgeBase.generateEmbedding('$title\n$content');
      } catch (e) {
        print('生成嵌入向量失败: $e');
      }
      
      // 4. 创建知识条目
      final knowledge = Knowledge(
        id: '',  // ID将由知识库生成
        title: title,
        content: content,
        tags: tags,
        source: event.sourceType.name,
        importance: importance,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'learning_event_id': event.id,
          'source_type': event.sourceType.name,
          ...event.metadata,
        },
        embedding: embedding,
      );
      
      // 5. 保存到知识库
      final knowledgeId = await knowledgeBase.store(knowledge);
      
      // 6. 如果有图谱管理器，更新知识图谱
      if (graphManager != null) {
        try {
          final node = await graphManager.createNodeFromKnowledge(
            knowledge.copyWith(id: knowledgeId),
          );
          
          // 尝试自动生成与现有知识的关系
          await graphManager.autoGenerateRelationships([knowledgeId]);
        } catch (e) {
          print('更新知识图谱失败: $e');
        }
      }
      
      return LearningResult(
        success: true,
        knowledgeId: knowledgeId,
        summary: '成功从内容中提取知识',
        details: {
          'title': title,
          'tags': tags,
          'importance': importance,
        },
      );
    } catch (e) {
      return LearningResult(
        success: false,
        summary: '处理学习事件时出错',
        details: {'error': e.toString()},
      );
    }
  }
  
  @override
  String get name => '基本提取策略';
  
  @override
  String get description => '从文本内容中提取关键知识点，并保存到知识库中';
  
  @override
  List<LearningSourceType> get supportedSourceTypes => [
    LearningSourceType.userInteraction,
    LearningSourceType.document,
    LearningSourceType.webContent,
  ];
}

/// 交互学习策略
class InteractionLearningStrategy implements LearningStrategy {
  @override
  Future<LearningResult> processEvent(
    LearningEvent event,
    LLMService llmService,
    KnowledgeBase knowledgeBase,
    [GraphManager? graphManager]
  ) async {
    try {
      // 检查是否是用户交互
      if (event.sourceType != LearningSourceType.userInteraction) {
        return LearningResult(
          success: false,
          summary: '事件源类型不是用户交互',
          details: {'sourceType': event.sourceType.name},
        );
      }
      
      // 使用LLM分析用户交互
      final prompt = '''
请分析以下用户交互内容，判断是否包含对用户偏好、习惯或工作方式的重要信息。
如果包含，请提取这些信息：
---
${event.content}
---
分析结果:
是否包含用户偏好/习惯信息: (是/否)
如果是，请提取:
标题:
偏好/习惯描述:
相关标签: (逗号分隔)
重要性: (0.1到1.0的数值)
''';
      
      final result = await llmService.processInput(
        prompt,
        [],
        LLMProcessingOptions(
          temperature: 0.3,
          maxTokens: 1000,
        ),
      );
      
      if (!result.success) {
        return LearningResult(
          success: false,
          summary: '处理用户交互失败',
          details: {'error': result.responseText},
        );
      }
      
      // 解析输出
      final response = result.responseText;
      
      // 检查是否包含用户偏好/习惯信息
      final containsInfoMatch = RegExp(r'是否包含用户偏好/习惯信息:(.*?)(?=\n|$)').firstMatch(response);
      final containsInfo = containsInfoMatch?.group(1)?.trim().toLowerCase() == '是';
      
      if (!containsInfo) {
        return LearningResult(
          success: true,
          summary: '未从交互中发现有用的用户偏好/习惯信息',
          details: {'response': response},
        );
      }
      
      // 解析提取的信息
      final titleMatch = RegExp(r'标题:(.*?)\n').firstMatch(response);
      final descriptionMatch = RegExp(r'偏好/习惯描述:(.*?)(?=相关标签:|$)', dotAll: true).firstMatch(response);
      final tagsMatch = RegExp(r'相关标签:(.*?)(?=重要性:|$)').firstMatch(response);
      final importanceMatch = RegExp(r'重要性:(.*?)(?=\n|$)').firstMatch(response);
      
      if (titleMatch == null || descriptionMatch == null) {
        return LearningResult(
          success: false,
          summary: '解析用户偏好/习惯信息失败',
          details: {'response': response},
        );
      }
      
      final title = titleMatch.group(1)?.trim() ?? '未命名用户偏好';
      final content = descriptionMatch.group(1)?.trim() ?? '';
      final tagsText = tagsMatch?.group(1)?.trim() ?? '';
      final tags = tagsText.split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
      
      // 添加用户偏好标签
      tags.add('用户偏好');
      tags.add('用户习惯');
      tags.add(event.sourceType.name);
      
      // 解析重要性
      double importance = event.importance;
      if (importanceMatch != null) {
        final importanceStr = importanceMatch.group(1)?.trim() ?? '';
        try {
          importance = double.parse(importanceStr);
          importance = importance.clamp(0.1, 1.0);
        } catch (e) {
          print('解析重要性失败: $e');
        }
      }
      
      // 生成嵌入向量
      List<double>? embedding;
      try {
        embedding = await knowledgeBase.generateEmbedding('$title\n$content');
      } catch (e) {
        print('生成嵌入向量失败: $e');
      }
      
      // 创建知识条目
      final knowledge = Knowledge(
        id: '',  // ID将由知识库生成
        title: title,
        content: content,
        tags: tags,
        source: event.sourceType.name,
        importance: importance,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'learning_event_id': event.id,
          'source_type': event.sourceType.name,
          'knowledge_type': '用户偏好',
          ...event.metadata,
        },
        embedding: embedding,
      );
      
      // 保存到知识库
      final knowledgeId = await knowledgeBase.store(knowledge);
      
      // 如果有图谱管理器，更新知识图谱
      if (graphManager != null) {
        try {
          final node = await graphManager.createNodeFromKnowledge(
            knowledge.copyWith(id: knowledgeId),
          );
          
          // 尝试自动生成与现有知识的关系
          await graphManager.autoGenerateRelationships([knowledgeId]);
        } catch (e) {
          print('更新知识图谱失败: $e');
        }
      }
      
      return LearningResult(
        success: true,
        knowledgeId: knowledgeId,
        summary: '成功从用户交互中提取偏好/习惯信息',
        details: {
          'title': title,
          'tags': tags,
          'importance': importance,
        },
      );
    } catch (e) {
      return LearningResult(
        success: false,
        summary: '处理用户交互学习事件时出错',
        details: {'error': e.toString()},
      );
    }
  }
  
  @override
  String get name => '交互学习策略';
  
  @override
  String get description => '从用户交互中学习用户偏好、习惯和工作方式';
  
  @override
  List<LearningSourceType> get supportedSourceTypes => [
    LearningSourceType.userInteraction,
  ];
}

/// 操作学习策略
class ActionLearningStrategy implements LearningStrategy {
  @override
  Future<LearningResult> processEvent(
    LearningEvent event,
    LLMService llmService,
    KnowledgeBase knowledgeBase,
    [GraphManager? graphManager]
  ) async {
    try {
      // 检查是否是应用内操作
      if (event.sourceType != LearningSourceType.appAction) {
        return LearningResult(
          success: false,
          summary: '事件源类型不是应用内操作',
          details: {'sourceType': event.sourceType.name},
        );
      }
      
      // 从元数据中获取操作类型
      final actionType = event.metadata['actionType'] as String?;
      if (actionType == null) {
        return LearningResult(
          success: false,
          summary: '操作类型未指定',
          details: {'metadata': event.metadata},
        );
      }
      
      // 使用LLM分析用户操作
      final prompt = '''
请分析以下用户操作，提取操作模式或偏好：
---
操作类型: $actionType
操作内容: ${event.content}
操作时间: ${event.timestamp}
${event.metadata.entries.map((e) => '${e.key}: ${e.value}').join('\n')}
---
分析结果:
标题:
操作模式/偏好:
相关标签: (逗号分隔)
重要性: (0.1到1.0的数值)
''';
      
      final result = await llmService.processInput(
        prompt,
        [],
        LLMProcessingOptions(
          temperature: 0.3,
          maxTokens: 1000,
        ),
      );
      
      if (!result.success) {
        return LearningResult(
          success: false,
          summary: '处理用户操作失败',
          details: {'error': result.responseText},
        );
      }
      
      // 解析输出
      final response = result.responseText;
      final titleMatch = RegExp(r'标题:(.*?)\n').firstMatch(response);
      final patternMatch = RegExp(r'操作模式/偏好:(.*?)(?=相关标签:|$)', dotAll: true).firstMatch(response);
      final tagsMatch = RegExp(r'相关标签:(.*?)(?=重要性:|$)').firstMatch(response);
      final importanceMatch = RegExp(r'重要性:(.*?)(?=\n|$)').firstMatch(response);
      
      if (titleMatch == null || patternMatch == null) {
        return LearningResult(
          success: false,
          summary: '解析用户操作模式/偏好失败',
          details: {'response': response},
        );
      }
      
      final title = titleMatch.group(1)?.trim() ?? '未命名操作模式';
      final content = patternMatch.group(1)?.trim() ?? '';
      final tagsText = tagsMatch?.group(1)?.trim() ?? '';
      final tags = tagsText.split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
      
      // 添加操作标签
      tags.add('操作模式');
      tags.add(actionType);
      tags.add(event.sourceType.name);
      
      // 解析重要性
      double importance = event.importance;
      if (importanceMatch != null) {
        final importanceStr = importanceMatch.group(1)?.trim() ?? '';
        try {
          importance = double.parse(importanceStr);
          importance = importance.clamp(0.1, 1.0);
        } catch (e) {
          print('解析重要性失败: $e');
        }
      }
      
      // 生成嵌入向量
      List<double>? embedding;
      try {
        embedding = await knowledgeBase.generateEmbedding('$title\n$content');
      } catch (e) {
        print('生成嵌入向量失败: $e');
      }
      
      // 创建知识条目
      final knowledge = Knowledge(
        id: '',  // ID将由知识库生成
        title: title,
        content: content,
        tags: tags,
        source: event.sourceType.name,
        importance: importance,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'learning_event_id': event.id,
          'source_type': event.sourceType.name,
          'action_type': actionType,
          'knowledge_type': '操作模式',
          ...event.metadata,
        },
        embedding: embedding,
      );
      
      // 保存到知识库
      final knowledgeId = await knowledgeBase.store(knowledge);
      
      // 如果有图谱管理器，更新知识图谱
      if (graphManager != null) {
        try {
          final node = await graphManager.createNodeFromKnowledge(
            knowledge.copyWith(id: knowledgeId),
          );
          
          // 尝试自动生成与现有知识的关系
          await graphManager.autoGenerateRelationships([knowledgeId]);
        } catch (e) {
          print('更新知识图谱失败: $e');
        }
      }
      
      return LearningResult(
        success: true,
        knowledgeId: knowledgeId,
        summary: '成功从用户操作中提取操作模式/偏好',
        details: {
          'title': title,
          'tags': tags,
          'importance': importance,
          'actionType': actionType,
        },
      );
    } catch (e) {
      return LearningResult(
        success: false,
        summary: '处理用户操作学习事件时出错',
        details: {'error': e.toString()},
      );
    }
  }
  
  @override
  String get name => '操作学习策略';
  
  @override
  String get description => '从用户应用内操作中学习操作模式和偏好';
  
  @override
  List<LearningSourceType> get supportedSourceTypes => [
    LearningSourceType.appAction,
  ];
}

/// 学习策略工厂
class LearningStrategyFactory {
  /// 策略映射
  final Map<String, LearningStrategy> _strategies = {};
  
  /// 构造函数
  LearningStrategyFactory() {
    // 注册默认策略
    register(BasicExtractionStrategy());
    register(InteractionLearningStrategy());
    register(ActionLearningStrategy());
  }
  
  /// 注册策略
  void register(LearningStrategy strategy) {
    _strategies[strategy.name] = strategy;
  }
  
  /// 获取策略
  LearningStrategy? get(String name) {
    return _strategies[name];
  }
  
  /// 获取适用于源类型的策略
  List<LearningStrategy> getForSourceType(LearningSourceType sourceType) {
    return _strategies.values
        .where((strategy) => strategy.supportedSourceTypes.contains(sourceType))
        .toList();
  }
  
  /// 获取所有策略
  List<LearningStrategy> getAll() {
    return _strategies.values.toList();
  }
}

/// 状态快照类型
enum SnapshotType {
  /// 文件状态
  fileSystem,
  
  /// 开发环境
  devEnvironment,
  
  /// 软件设置
  settings,
  
  /// 任务状态
  taskState,
  
  /// 目录结构
  directoryTree,
  
  /// 完整状态
  fullState,
}

/// 状态快照
class StateSnapshot {
  /// 快照ID
  final String id;
  
  /// 快照类型
  final SnapshotType type;
  
  /// 创建时间
  final DateTime timestamp;
  
  /// 描述
  final String description;
  
  /// 标签
  final List<String> tags;
  
  /// 文件系统状态
  final Map<String, dynamic> fileSystemState;
  
  /// 开发环境状态
  final Map<String, dynamic> devEnvironmentState;
  
  /// 软件设置状态
  final Map<String, dynamic> settingsState;
  
  /// 任务状态
  final Map<String, dynamic> taskState;
  
  /// 目录树状态
  final Map<String, dynamic> directoryTreeState;
  
  /// 是否是自动保存
  final bool isAutoSave;
  
  /// 是否可以运行
  final bool isRunnable;
  
  /// 构造函数
  StateSnapshot({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.description,
    this.tags = const [],
    this.fileSystemState = const {},
    this.devEnvironmentState = const {},
    this.settingsState = const {},
    this.taskState = const {},
    this.directoryTreeState = const {},
    this.isAutoSave = false,
    this.isRunnable = false,
  });
  
  /// 从Map创建快照
  factory StateSnapshot.fromMap(Map<String, dynamic> map) {
    return StateSnapshot(
      id: map['id'] as String,
      type: SnapshotType.values.byName(map['type'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      fileSystemState: Map<String, dynamic>.from(map['fileSystemState'] ?? {}),
      devEnvironmentState: Map<String, dynamic>.from(map['devEnvironmentState'] ?? {}),
      settingsState: Map<String, dynamic>.from(map['settingsState'] ?? {}),
      taskState: Map<String, dynamic>.from(map['taskState'] ?? {}),
      directoryTreeState: Map<String, dynamic>.from(map['directoryTreeState'] ?? {}),
      isAutoSave: map['isAutoSave'] as bool? ?? false,
      isRunnable: map['isRunnable'] as bool? ?? false,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'tags': tags,
      'fileSystemState': fileSystemState,
      'devEnvironmentState': devEnvironmentState,
      'settingsState': settingsState,
      'taskState': taskState,
      'directoryTreeState': directoryTreeState,
      'isAutoSave': isAutoSave,
      'isRunnable': isRunnable,
    };
  }
}

/// 学习引擎配置
class LearningEngineConfig {
  /// 是否启用自动保存
  final bool enableAutoSave;
  
  /// 自动保存间隔（毫秒）
  final int autoSaveInterval;
  
  /// 最大快照数量
  final int maxSnapshots;
  
  /// 快照保留时间（毫秒）
  final int snapshotRetentionTime;
  
  /// 是否启用增量保存
  final bool enableIncrementalSave;
  
  /// 是否压缩快照
  final bool compressSnapshots;
  
  /// 构造函数
  LearningEngineConfig({
    this.enableAutoSave = true,
    this.autoSaveInterval = 5 * 60 * 1000, // 5分钟
    this.maxSnapshots = 100,
    this.snapshotRetentionTime = 30 * 24 * 60 * 60 * 1000, // 30天
    this.enableIncrementalSave = true,
    this.compressSnapshots = true,
  });
  
  /// 从Map创建配置
  factory LearningEngineConfig.fromMap(Map<String, dynamic> map) {
    return LearningEngineConfig(
      enableAutoSave: map['enableAutoSave'] ?? true,
      autoSaveInterval: map['autoSaveInterval'] ?? 5 * 60 * 1000,
      maxSnapshots: map['maxSnapshots'] ?? 100,
      snapshotRetentionTime: map['snapshotRetentionTime'] ?? 30 * 24 * 60 * 60 * 1000,
      enableIncrementalSave: map['enableIncrementalSave'] ?? true,
      compressSnapshots: map['compressSnapshots'] ?? true,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'enableAutoSave': enableAutoSave,
      'autoSaveInterval': autoSaveInterval,
      'maxSnapshots': maxSnapshots,
      'snapshotRetentionTime': snapshotRetentionTime,
      'enableIncrementalSave': enableIncrementalSave,
      'compressSnapshots': compressSnapshots,
    };
  }
}

/// 学习引擎
class LearningEngine {
  /// LLM服务
  final LLMService _llmService;
  
  /// 知识库
  final KnowledgeBase _knowledgeBase;
  
  /// 图谱管理器（可选）
  final GraphManager? _graphManager;
  
  /// 策略工厂
  final LearningStrategyFactory _strategyFactory;
  
  /// 事件控制器
  final StreamController<LearningEvent> _eventController =
      StreamController<LearningEvent>.broadcast();
  
  /// 结果控制器
  final StreamController<LearningResult> _resultController =
      StreamController<LearningResult>.broadcast();
  
  /// 事件流
  Stream<LearningEvent> get events => _eventController.stream;
  
  /// 结果流
  Stream<LearningResult> get results => _resultController.stream;
  
  /// 配置
  LearningEngineConfig _config;
  
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 状态服务
  final StateService _stateService;
  
  /// 快照列表
  final List<StateSnapshot> _snapshots = [];
  
  /// 快照变更流控制器
  final StreamController<StateSnapshot> _snapshotController =
      StreamController<StateSnapshot>.broadcast();
  
  /// 快照变更流
  Stream<StateSnapshot> get snapshotStream => _snapshotController.stream;
  
  /// 定时器
  Timer? _autoSaveTimer;
  
  /// 当前快照索引
  int _currentSnapshotIndex = -1;
  
  /// 构造函数
  LearningEngine({
    required LLMService llmService,
    required KnowledgeBase knowledgeBase,
    GraphManager? graphManager,
    LearningStrategyFactory? strategyFactory,
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required StateService stateService,
    LearningEngineConfig? config,
  })  : _llmService = llmService,
        _knowledgeBase = knowledgeBase,
        _graphManager = graphManager,
        _strategyFactory = strategyFactory ?? LearningStrategyFactory(),
        _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _stateService = stateService,
        _config = config ?? LearningEngineConfig() {
    _initializeEngine();
    // 监听事件并处理
    _eventController.stream.listen(_processEvent);
  }
  
  /// 初始化引擎
  void _initializeEngine() {
    // 启动自动保存
    if (_config.enableAutoSave) {
      _startAutoSave();
    }
    
    // 清理过期快照
    _cleanupSnapshots();
  }
  
  /// 启动自动保存
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(milliseconds: _config.autoSaveInterval),
      (_) => _autoSaveSnapshot(),
    );
  }
  
  /// 自动保存快照
  Future<void> _autoSaveSnapshot() async {
    try {
      // 创建完整状态快照
      final snapshot = await createSnapshot(
        type: SnapshotType.fullState,
        description: '自动保存',
        isAutoSave: true,
      );
      
      _loggingService.info(
        '自动保存快照',
        tags: {
          'snapshot_id': snapshot.id,
          'timestamp': snapshot.timestamp.toIso8601String(),
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.low,
        message: '自动保存快照失败',
      );
    }
  }
  
  /// 清理快照
  void _cleanupSnapshots() {
    final now = DateTime.now();
    final cutoff = now.subtract(
      Duration(milliseconds: _config.snapshotRetentionTime),
    );
    
    // 移除过期快照
    _snapshots.removeWhere((snapshot) =>
        snapshot.timestamp.isBefore(cutoff) && !snapshot.isRunnable);
    
    // 限制快照数量
    if (_snapshots.length > _config.maxSnapshots) {
      _snapshots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _snapshots.removeRange(_config.maxSnapshots, _snapshots.length);
    }
  }
  
  /// 创建快照
  Future<StateSnapshot> createSnapshot({
    required SnapshotType type,
    required String description,
    List<String> tags = const [],
    bool isAutoSave = false,
  }) async {
    try {
      // 生成快照ID
      final id = _generateId();
      
      // 获取当前状态
      final currentState = await _stateService.getCurrentState();
      
      // 检查是否可运行
      final isRunnable = await _checkIsRunnable();
      
      // 创建快照
      final snapshot = StateSnapshot(
        id: id,
        type: type,
        timestamp: DateTime.now(),
        description: description,
        tags: tags,
        fileSystemState: currentState['fileSystem'] ?? {},
        devEnvironmentState: currentState['devEnvironment'] ?? {},
        settingsState: currentState['settings'] ?? {},
        taskState: currentState['task'] ?? {},
        directoryTreeState: currentState['directoryTree'] ?? {},
        isAutoSave: isAutoSave,
        isRunnable: isRunnable,
      );
      
      // 保存快照
      _snapshots.add(snapshot);
      _currentSnapshotIndex = _snapshots.length - 1;
      
      // 发送到流
      _snapshotController.add(snapshot);
      
      // 清理过期快照
      _cleanupSnapshots();
      
      _loggingService.info(
        '创建快照',
        tags: {
          'snapshot_id': snapshot.id,
          'type': snapshot.type.name,
          'description': snapshot.description,
        },
      );
      
      return snapshot;
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '创建快照失败',
      );
      rethrow;
    }
  }
  
  /// 检查是否可运行
  Future<bool> _checkIsRunnable() async {
    try {
      // TODO: 实现运行状态检查
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 恢复到快照
  Future<void> restoreSnapshot(String snapshotId) async {
    try {
      final snapshot = _snapshots.firstWhere(
        (s) => s.id == snapshotId,
        orElse: () => throw Exception('快照不存在'),
      );
      
      // 恢复状态
      await _stateService.restoreState({
        'fileSystem': snapshot.fileSystemState,
        'devEnvironment': snapshot.devEnvironmentState,
        'settings': snapshot.settingsState,
        'task': snapshot.taskState,
        'directoryTree': snapshot.directoryTreeState,
      });
      
      // 更新当前快照索引
      _currentSnapshotIndex = _snapshots.indexOf(snapshot);
      
      _loggingService.info(
        '恢复快照',
        tags: {
          'snapshot_id': snapshot.id,
          'type': snapshot.type.name,
          'description': snapshot.description,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.high,
        message: '恢复快照失败',
      );
      rethrow;
    }
  }
  
  /// 获取快照
  StateSnapshot? getSnapshot(String snapshotId) {
    return _snapshots.firstWhere(
      (s) => s.id == snapshotId,
      orElse: () => null,
    );
  }
  
  /// 获取所有快照
  List<StateSnapshot> getAllSnapshots() {
    return List.unmodifiable(_snapshots);
  }
  
  /// 获取可运行的快照
  List<StateSnapshot> getRunnableSnapshots() {
    return _snapshots.where((s) => s.isRunnable).toList();
  }
  
  /// 获取特定类型的快照
  List<StateSnapshot> getSnapshotsByType(SnapshotType type) {
    return _snapshots.where((s) => s.type == type).toList();
  }
  
  /// 删除快照
  Future<void> deleteSnapshot(String snapshotId) async {
    try {
      final index = _snapshots.indexWhere((s) => s.id == snapshotId);
      if (index != -1) {
        _snapshots.removeAt(index);
        if (_currentSnapshotIndex >= index) {
          _currentSnapshotIndex--;
        }
      }
      
      _loggingService.info(
        '删除快照',
        tags: {
          'snapshot_id': snapshotId,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '删除快照失败',
      );
      rethrow;
    }
  }
  
  /// 撤销到上一个快照
  Future<void> undo() async {
    if (_currentSnapshotIndex > 0) {
      await restoreSnapshot(_snapshots[_currentSnapshotIndex - 1].id);
    }
  }
  
  /// 重做到下一个快照
  Future<void> redo() async {
    if (_currentSnapshotIndex < _snapshots.length - 1) {
      await restoreSnapshot(_snapshots[_currentSnapshotIndex + 1].id);
    }
  }
  
  /// 生成快照ID
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = utf8.encode('$now$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 16);
  }
  
  /// 更新配置
  void updateConfig(LearningEngineConfig config) {
    _config = config;
    _initializeEngine();
  }
  
  /// 获取当前配置
  LearningEngineConfig getConfig() {
    return _config;
  }
  
  /// 提交学习事件
  void submitEvent(LearningEvent event) {
    _eventController.add(event);
  }
  
  /// 处理学习事件
  Future<void> _processEvent(LearningEvent event) async {
    // 获取适用的策略
    final strategies = _strategyFactory.getForSourceType(event.sourceType);
    
    if (strategies.isEmpty) {
      final result = LearningResult(
        success: false,
        summary: '没有适用于源类型${event.sourceType.name}的学习策略',
        details: {},
      );
      _resultController.add(result);
      return;
    }
    
    // 选择第一个适用的策略
    final strategy = strategies.first;
    
    // 处理事件
    final result = await strategy.processEvent(
      event,
      _llmService,
      _knowledgeBase,
      _graphManager,
    );
    
    // 发布结果
    _resultController.add(result);
  }
  
  /// 主动学习
  Future<LearningResult> learnFromContent(
    String content, {
    LearningSourceType sourceType = LearningSourceType.document,
    List<String> tags = const [],
    double importance = 0.5,
    Map<String, dynamic> metadata = const {},
    String? strategyName,
  }) async {
    // 创建学习事件
    final event = LearningEvent(
      id: 'learn_${DateTime.now().millisecondsSinceEpoch}',
      sourceType: sourceType,
      content: content,
      tags: tags,
      importance: importance,
      metadata: metadata,
    );
    
    // 选择策略
    LearningStrategy? strategy;
    if (strategyName != null) {
      strategy = _strategyFactory.get(strategyName);
    }
    
    if (strategy == null) {
      final strategies = _strategyFactory.getForSourceType(sourceType);
      if (strategies.isEmpty) {
        return LearningResult(
          success: false,
          summary: '没有适用于源类型${sourceType.name}的学习策略',
          details: {},
        );
      }
      strategy = strategies.first;
    }
    
    // 处理事件
    final result = await strategy.processEvent(
      event,
      _llmService,
      _knowledgeBase,
      _graphManager,
    );
    
    return result;
  }
  
  /// 关闭引擎
  Future<void> close() async {
    await _eventController.close();
    await _resultController.close();
    await _snapshotController.close();
  }
}

/// 学习引擎提供者
final learningEngineProvider = Provider<LearningEngine>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  final knowledgeBase = ref.watch(knowledgeBaseProvider);
  final graphManager = ref.watch(graphManagerProvider);
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  final stateService = ref.watch(stateServiceProvider);
  
  final engine = LearningEngine(
    llmService: llmService,
    knowledgeBase: knowledgeBase,
    graphManager: graphManager,
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    stateService: stateService,
  );
  
  ref.onDispose(() {
    engine.close();
  });
  
  return engine;
});

/// LLM服务提供者（需要在应用中定义）
final llmServiceProvider = Provider<LLMService>((ref) {
  // 这需要在应用中实现
  throw UnimplementedError('需要提供LLM服务');
});

/// 快照流提供者
final snapshotStreamProvider = StreamProvider<StateSnapshot>((ref) {
  final engine = ref.watch(learningEngineProvider);
  return engine.snapshotStream;
}); 