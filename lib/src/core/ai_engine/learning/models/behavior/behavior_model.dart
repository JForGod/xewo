import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:xewo/src/core/ai_engine/learning/learning_engine.dart';
import 'package:xewo/src/core/ai_engine/learning/strategies/reinforcement/reinforcement_learning_strategy.dart';

/// 行为类型枚举
enum BehaviorType {
  /// 命令行为
  command,
  
  /// 查询行为
  query,
  
  /// 创建行为
  creation,
  
  /// 编辑行为
  edit,
  
  /// 浏览行为
  browse,
  
  /// 学习行为
  learning,
  
  /// 社交行为
  social,
  
  /// 其他行为
  other,
}

/// 行为上下文
class BehaviorContext {
  /// 时间戳
  final DateTime timestamp;
  
  /// 应用状态
  final Map<String, dynamic> appState;
  
  /// 用户状态
  final Map<String, dynamic> userState;
  
  /// 环境状态
  final Map<String, dynamic> environmentState;
  
  /// 创建行为上下文
  BehaviorContext({
    DateTime? timestamp,
    Map<String, dynamic>? appState,
    Map<String, dynamic>? userState,
    Map<String, dynamic>? environmentState,
  }) : 
    timestamp = timestamp ?? DateTime.now(),
    appState = appState ?? {},
    userState = userState ?? {},
    environmentState = environmentState ?? {};
  
  /// 从JSON创建行为上下文
  factory BehaviorContext.fromJson(Map<String, dynamic> json) {
    return BehaviorContext(
      timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'] as String) 
        : DateTime.now(),
      appState: json['appState'] as Map<String, dynamic>? ?? {},
      userState: json['userState'] as Map<String, dynamic>? ?? {},
      environmentState: json['environmentState'] as Map<String, dynamic>? ?? {},
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'appState': appState,
      'userState': userState,
      'environmentState': environmentState,
    };
  }
  
  /// 复制并修改
  BehaviorContext copyWith({
    DateTime? timestamp,
    Map<String, dynamic>? appState,
    Map<String, dynamic>? userState,
    Map<String, dynamic>? environmentState,
  }) {
    return BehaviorContext(
      timestamp: timestamp ?? this.timestamp,
      appState: appState ?? Map<String, dynamic>.from(this.appState),
      userState: userState ?? Map<String, dynamic>.from(this.userState),
      environmentState: environmentState ?? Map<String, dynamic>.from(this.environmentState),
    );
  }
}

/// 行为记录
class BehaviorRecord {
  /// 唯一标识符
  final String id;
  
  /// 行为类型
  final BehaviorType type;
  
  /// 行为内容
  final String content;
  
  /// 行为上下文
  final BehaviorContext context;
  
  /// 行为结果
  final Map<String, dynamic> result;
  
  /// 反馈分数
  final double? feedbackScore;
  
  /// 创建行为记录
  BehaviorRecord({
    String? id,
    required this.type,
    required this.content,
    BehaviorContext? context,
    Map<String, dynamic>? result,
    this.feedbackScore,
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    context = context ?? BehaviorContext(),
    result = result ?? {};
  
  /// 从JSON创建行为记录
  factory BehaviorRecord.fromJson(Map<String, dynamic> json) {
    return BehaviorRecord(
      id: json['id'] as String,
      type: BehaviorType.values.firstWhere(
        (e) => e.toString() == 'BehaviorType.${json['type']}',
        orElse: () => BehaviorType.other,
      ),
      content: json['content'] as String,
      context: json['context'] != null 
        ? BehaviorContext.fromJson(json['context'] as Map<String, dynamic>) 
        : BehaviorContext(),
      result: json['result'] as Map<String, dynamic>? ?? {},
      feedbackScore: json['feedbackScore'] as double?,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'context': context.toJson(),
      'result': result,
      'feedbackScore': feedbackScore,
    };
  }
  
  /// 复制并修改
  BehaviorRecord copyWith({
    String? id,
    BehaviorType? type,
    String? content,
    BehaviorContext? context,
    Map<String, dynamic>? result,
    double? feedbackScore,
  }) {
    return BehaviorRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      context: context ?? this.context,
      result: result ?? Map<String, dynamic>.from(this.result),
      feedbackScore: feedbackScore ?? this.feedbackScore,
    );
  }
}

/// 行为模式
class BehaviorPattern {
  /// 唯一标识符
  final String id;
  
  /// 模式名称
  final String name;
  
  /// 模式描述
  final String description;
  
  /// 行为类型
  final List<BehaviorType> types;
  
  /// 模式特征
  final Map<String, dynamic> features;
  
  /// 置信度
  final double confidence;
  
  /// 创建行为模式
  BehaviorPattern({
    String? id,
    required this.name,
    required this.description,
    required this.types,
    required this.features,
    this.confidence = 0.0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  /// 从JSON创建行为模式
  factory BehaviorPattern.fromJson(Map<String, dynamic> json) {
    return BehaviorPattern(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      types: (json['types'] as List<dynamic>).map((e) => 
        BehaviorType.values.firstWhere(
          (type) => type.toString() == 'BehaviorType.${e}',
          orElse: () => BehaviorType.other,
        )
      ).toList(),
      features: json['features'] as Map<String, dynamic>,
      confidence: json['confidence'] as double? ?? 0.0,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'types': types.map((e) => e.toString().split('.').last).toList(),
      'features': features,
      'confidence': confidence,
    };
  }
  
  /// 复制并修改
  BehaviorPattern copyWith({
    String? id,
    String? name,
    String? description,
    List<BehaviorType>? types,
    Map<String, dynamic>? features,
    double? confidence,
  }) {
    return BehaviorPattern(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      types: types ?? List<BehaviorType>.from(this.types),
      features: features ?? Map<String, dynamic>.from(this.features),
      confidence: confidence ?? this.confidence,
    );
  }
}

/// 行为模型接口
abstract class BehaviorModel {
  /// 初始化模型
  Future<void> initialize();
  
  /// 记录行为
  Future<void> recordBehavior(BehaviorRecord record);
  
  /// 获取行为历史
  Future<List<BehaviorRecord>> getBehaviorHistory({
    DateTime? startTime,
    DateTime? endTime,
    List<BehaviorType>? types,
    int? limit,
  });
  
  /// 识别行为模式
  Future<List<BehaviorPattern>> recognizePatterns(List<BehaviorRecord> records);
  
  /// 预测下一个行为
  Future<BehaviorPrediction> predictNextBehavior(List<BehaviorRecord> history);
  
  /// 获取用户偏好
  Future<Map<String, dynamic>> getUserPreferences();
  
  /// 更新模型
  Future<void> updateModel();
  
  /// 保存模型
  Future<void> saveModel(String path);
  
  /// 加载模型
  Future<void> loadModel(String path);
}

/// 行为预测结果
class BehaviorPrediction {
  /// 预测的行为类型
  final BehaviorType type;
  
  /// 预测的行为内容
  final String? content;
  
  /// 预测的置信度
  final double confidence;
  
  /// 可能的行为列表
  final List<Map<String, dynamic>> alternatives;
  
  /// 创建行为预测
  BehaviorPrediction({
    required this.type,
    this.content,
    required this.confidence,
    List<Map<String, dynamic>>? alternatives,
  }) : alternatives = alternatives ?? [];
  
  /// 从JSON创建行为预测
  factory BehaviorPrediction.fromJson(Map<String, dynamic> json) {
    return BehaviorPrediction(
      type: BehaviorType.values.firstWhere(
        (e) => e.toString() == 'BehaviorType.${json['type']}',
        orElse: () => BehaviorType.other,
      ),
      content: json['content'] as String?,
      confidence: json['confidence'] as double,
      alternatives: (json['alternatives'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'content': content,
      'confidence': confidence,
      'alternatives': alternatives,
    };
  }
}

/// 基于强化学习的行为模型实现
class RLBehaviorModel implements BehaviorModel {
  /// 行为历史
  final List<BehaviorRecord> _behaviorHistory = [];
  
  /// 行为模式
  final List<BehaviorPattern> _patterns = [];
  
  /// 用户偏好
  final Map<String, dynamic> _userPreferences = {};
  
  /// 强化学习策略
  final ReinforcementLearningStrategy _rlStrategy;
  
  /// 随机数生成器
  final math.Random _random = math.Random();
  
  /// 创建基于强化学习的行为模型
  RLBehaviorModel({
    ReinforcementLearningStrategy? rlStrategy,
  }) : _rlStrategy = rlStrategy ?? QLearningStrategy(
    availableActions: BehaviorType.values.map((e) => e.toString()).toList(),
  );
  
  @override
  Future<void> initialize() async {
    // 初始化强化学习策略
    await _rlStrategy.initialize();
    
    // 清空历史和模式
    _behaviorHistory.clear();
    _patterns.clear();
    _userPreferences.clear();
  }
  
  @override
  Future<void> recordBehavior(BehaviorRecord record) async {
    // 添加到历史
    _behaviorHistory.add(record);
    
    // 如果有反馈分数，则更新强化学习模型
    if (record.feedbackScore != null) {
      final state = _extractStateFromContext(record.context);
      final action = record.type.toString();
      
      await _rlStrategy.receiveReward(
        record.feedbackScore!,
        state,
        action,
      );
    }
    
    // 更新用户偏好
    _updateUserPreferences(record);
  }
  
  @override
  Future<List<BehaviorRecord>> getBehaviorHistory({
    DateTime? startTime,
    DateTime? endTime,
    List<BehaviorType>? types,
    int? limit,
  }) async {
    // 过滤历史记录
    List<BehaviorRecord> filteredHistory = List.from(_behaviorHistory);
    
    // 按时间过滤
    if (startTime != null) {
      filteredHistory = filteredHistory.where(
        (record) => record.context.timestamp.isAfter(startTime)
      ).toList();
    }
    
    if (endTime != null) {
      filteredHistory = filteredHistory.where(
        (record) => record.context.timestamp.isBefore(endTime)
      ).toList();
    }
    
    // 按类型过滤
    if (types != null && types.isNotEmpty) {
      filteredHistory = filteredHistory.where(
        (record) => types.contains(record.type)
      ).toList();
    }
    
    // 按时间排序
    filteredHistory.sort(
      (a, b) => a.context.timestamp.compareTo(b.context.timestamp)
    );
    
    // 限制数量
    if (limit != null && limit > 0 && filteredHistory.length > limit) {
      filteredHistory = filteredHistory.sublist(
        filteredHistory.length - limit
      );
    }
    
    return filteredHistory;
  }
  
  @override
  Future<List<BehaviorPattern>> recognizePatterns(List<BehaviorRecord> records) async {
    if (records.isEmpty) {
      return [];
    }
    
    // 简单模式识别：按行为类型分组并计算频率
    final typeFrequency = <BehaviorType, int>{};
    for (final record in records) {
      typeFrequency[record.type] = (typeFrequency[record.type] ?? 0) + 1;
    }
    
    // 识别序列模式
    final sequencePatterns = _recognizeSequencePatterns(records);
    
    // 识别时间模式
    final timePatterns = _recognizeTimePatterns(records);
    
    // 合并所有模式
    final List<BehaviorPattern> patterns = [];
    
    // 添加频率模式
    typeFrequency.forEach((type, frequency) {
      if (frequency > 1) {  // 至少出现两次
        patterns.add(BehaviorPattern(
          name: '${type.toString().split('.').last}频率模式',
          description: '用户经常执行${type.toString().split('.').last}类型的行为',
          types: [type],
          features: {
            'frequency': frequency,
            'ratio': frequency / records.length,
          },
          confidence: frequency / records.length,
        ));
      }
    });
    
    // 添加序列和时间模式
    patterns.addAll(sequencePatterns);
    patterns.addAll(timePatterns);
    
    // 按置信度排序
    patterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return patterns;
  }
  
  @override
  Future<BehaviorPrediction> predictNextBehavior(List<BehaviorRecord> history) async {
    if (history.isEmpty) {
      // 如果没有历史记录，返回随机预测
      return BehaviorPrediction(
        type: BehaviorType.values[_random.nextInt(BehaviorType.values.length)],
        confidence: 0.1,
      );
    }
    
    // 获取最后一条记录的上下文作为当前状态
    final lastRecord = history.last;
    final currentState = _extractStateFromContext(lastRecord.context);
    
    // 使用强化学习策略预测下一个行为
    final actionStr = await _rlStrategy.selectAction(currentState);
    final predictedType = BehaviorType.values.firstWhere(
      (type) => type.toString() == actionStr,
      orElse: () => BehaviorType.other,
    );
    
    // 生成备选行为
    final alternatives = <Map<String, dynamic>>[];
    for (final type in BehaviorType.values) {
      if (type != predictedType) {
        alternatives.add({
          'type': type.toString().split('.').last,
          'confidence': 0.1 + _random.nextDouble() * 0.3,
        });
      }
    }
    
    // 按置信度排序
    alternatives.sort((a, b) => 
      (b['confidence'] as double).compareTo(a['confidence'] as double)
    );
    
    // 只保留前3个备选
    if (alternatives.length > 3) {
      alternatives.removeRange(3, alternatives.length);
    }
    
    return BehaviorPrediction(
      type: predictedType,
      confidence: 0.5 + _random.nextDouble() * 0.4,  // 模拟置信度
      alternatives: alternatives,
    );
  }
  
  @override
  Future<Map<String, dynamic>> getUserPreferences() async {
    return Map<String, dynamic>.from(_userPreferences);
  }
  
  @override
  Future<void> updateModel() async {
    // 在实际应用中，这里应该重新训练模型
    print('更新行为模型');
  }
  
  @override
  Future<void> saveModel(String path) async {
    // 在实际应用中，这里应该将模型保存到文件
    print('保存行为模型到: $path');
    
    // 保存强化学习策略
    await _rlStrategy.saveModel('$path.rl');
  }
  
  @override
  Future<void> loadModel(String path) async {
    // 在实际应用中，这里应该从文件加载模型
    print('从 $path 加载行为模型');
    
    // 加载强化学习策略
    await _rlStrategy.loadModel('$path.rl');
  }
  
  /// 从上下文提取状态
  Map<String, dynamic> _extractStateFromContext(BehaviorContext context) {
    // 简化版本，只使用部分上下文信息
    return {
      'appState': context.appState,
      'userState': context.userState,
      'hour': context.timestamp.hour,
      'weekday': context.timestamp.weekday,
    };
  }
  
  /// 更新用户偏好
  void _updateUserPreferences(BehaviorRecord record) {
    // 更新行为类型偏好
    final typeKey = 'behavior_type_${record.type.toString().split('.').last}';
    _userPreferences[typeKey] = (_userPreferences[typeKey] as int? ?? 0) + 1;
    
    // 更新时间偏好
    final hourKey = 'hour_${record.context.timestamp.hour}';
    _userPreferences[hourKey] = (_userPreferences[hourKey] as int? ?? 0) + 1;
    
    final weekdayKey = 'weekday_${record.context.timestamp.weekday}';
    _userPreferences[weekdayKey] = (_userPreferences[weekdayKey] as int? ?? 0) + 1;
    
    // 更新内容相关偏好
    if (record.content.isNotEmpty) {
      // 简单的关键词提取
      final keywords = record.content.toLowerCase().split(' ')
        .where((word) => word.length > 3)  // 只考虑长度大于3的单词
        .toList();
      
      for (final keyword in keywords) {
        final keywordKey = 'keyword_$keyword';
        _userPreferences[keywordKey] = (_userPreferences[keywordKey] as int? ?? 0) + 1;
      }
    }
  }
  
  /// 识别序列模式
  List<BehaviorPattern> _recognizeSequencePatterns(List<BehaviorRecord> records) {
    if (records.length < 3) {
      return [];  // 至少需要3条记录才能识别序列模式
    }
    
    final patterns = <BehaviorPattern>[];
    final sequences = <List<BehaviorType>, int>{};
    
    // 查找长度为2的序列
    for (int i = 0; i < records.length - 1; i++) {
      final sequence = [records[i].type, records[i + 1].type];
      sequences[sequence] = (sequences[sequence] ?? 0) + 1;
    }
    
    // 查找长度为3的序列
    for (int i = 0; i < records.length - 2; i++) {
      final sequence = [records[i].type, records[i + 1].type, records[i + 2].type];
      sequences[sequence] = (sequences[sequence] ?? 0) + 1;
    }
    
    // 创建模式
    sequences.forEach((sequence, count) {
      if (count > 1) {  // 至少出现两次
        final sequenceStr = sequence.map((type) => type.toString().split('.').last).join(' -> ');
        patterns.add(BehaviorPattern(
          name: '序列模式: $sequenceStr',
          description: '用户经常执行序列: $sequenceStr',
          types: List<BehaviorType>.from(sequence),
          features: {
            'sequence': sequenceStr,
            'count': count,
            'ratio': count / (records.length - sequence.length + 1),
          },
          confidence: count / (records.length - sequence.length + 1),
        ));
      }
    });
    
    return patterns;
  }
  
  /// 识别时间模式
  List<BehaviorPattern> _recognizeTimePatterns(List<BehaviorRecord> records) {
    final patterns = <BehaviorPattern>[];
    final hourDistribution = <int, Map<BehaviorType, int>>{};
    final weekdayDistribution = <int, Map<BehaviorType, int>>{};
    
    // 统计每小时和每星期几的行为分布
    for (final record in records) {
      final hour = record.context.timestamp.hour;
      final weekday = record.context.timestamp.weekday;
      
      hourDistribution[hour] ??= {};
      hourDistribution[hour]![record.type] = 
        (hourDistribution[hour]![record.type] ?? 0) + 1;
      
      weekdayDistribution[weekday] ??= {};
      weekdayDistribution[weekday]![record.type] = 
        (weekdayDistribution[weekday]![record.type] ?? 0) + 1;
    }
    
    // 创建小时模式
    hourDistribution.forEach((hour, typeCount) {
      typeCount.forEach((type, count) {
        if (count > 1) {  // 至少出现两次
          final hourStr = hour.toString().padLeft(2, '0');
          patterns.add(BehaviorPattern(
            name: '时间模式: $hourStr:00',
            description: '用户在 $hourStr:00 时经常执行 ${type.toString().split('.').last} 行为',
            types: [type],
            features: {
              'hour': hour,
              'count': count,
              'ratio': count / records.where((r) => r.context.timestamp.hour == hour).length,
            },
            confidence: count / records.where((r) => r.context.timestamp.hour == hour).length,
          ));
        }
      });
    });
    
    // 创建星期几模式
    weekdayDistribution.forEach((weekday, typeCount) {
      typeCount.forEach((type, count) {
        if (count > 1) {  // 至少出现两次
          final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
          final weekdayStr = weekdayNames[weekday - 1];
          patterns.add(BehaviorPattern(
            name: '星期模式: $weekdayStr',
            description: '用户在 $weekdayStr 经常执行 ${type.toString().split('.').last} 行为',
            types: [type],
            features: {
              'weekday': weekday,
              'count': count,
              'ratio': count / records.where((r) => r.context.timestamp.weekday == weekday).length,
            },
            confidence: count / records.where((r) => r.context.timestamp.weekday == weekday).length,
          ));
        }
      });
    });
    
    return patterns;
  }
}

/// 行为模型工厂
class BehaviorModelFactory {
  /// 创建行为模型
  static BehaviorModel createModel(
    String type, {
    Map<String, dynamic> config = const {},
  }) {
    switch (type.toLowerCase()) {
      case 'rl':
        final rlStrategyType = config['rlStrategyType'] as String? ?? 'qlearning';
        final rlStrategyConfig = config['rlStrategyConfig'] as Map<String, dynamic>? ?? {};
        
        // 创建强化学习策略
        final rlStrategy = ReinforcementLearningStrategyFactory.createStrategy(
          rlStrategyType,
          config: rlStrategyConfig,
        );
        
        return RLBehaviorModel(rlStrategy: rlStrategy);
      default:
        throw ArgumentError('不支持的行为模型类型: $type');
    }
  }
} 