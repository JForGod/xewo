import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../logging/logging_service.dart';
import '../error/error_handling_service.dart';

/// 配置类型
enum ConfigType {
  /// 系统配置
  system,
  
  /// 用户配置
  user,
  
  /// 应用配置
  app,
  
  /// 安全配置
  security,
  
  /// 网络配置
  network,
  
  /// 存储配置
  storage,
  
  /// 通知配置
  notification,
  
  /// 其他配置
  other,
}

/// 配置值类型
enum ConfigValueType {
  /// 字符串
  string,
  
  /// 整数
  integer,
  
  /// 浮点数
  double,
  
  /// 布尔值
  boolean,
  
  /// 列表
  list,
  
  /// 映射
  map,
}

/// 配置项
class ConfigItem {
  /// 配置键
  final String key;
  
  /// 配置类型
  final ConfigType type;
  
  /// 值类型
  final ConfigValueType valueType;
  
  /// 值
  final dynamic value;
  
  /// 默认值
  final dynamic defaultValue;
  
  /// 描述
  final String description;
  
  /// 是否必需
  final bool isRequired;
  
  /// 是否只读
  final bool isReadOnly;
  
  /// 是否加密
  final bool isEncrypted;
  
  /// 验证规则
  final Map<String, dynamic> validationRules;
  
  /// 标签
  final List<String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  ConfigItem({
    required this.key,
    required this.type,
    required this.valueType,
    required this.value,
    this.defaultValue,
    required this.description,
    this.isRequired = false,
    this.isReadOnly = false,
    this.isEncrypted = false,
    this.validationRules = const {},
    this.tags = const [],
    this.details = const {},
  });
  
  /// 从Map创建配置项
  factory ConfigItem.fromMap(Map<String, dynamic> map) {
    return ConfigItem(
      key: map['key'] as String,
      type: ConfigType.values.byName(map['type'] as String),
      valueType: ConfigValueType.values.byName(map['valueType'] as String),
      value: map['value'],
      defaultValue: map['defaultValue'],
      description: map['description'] as String,
      isRequired: map['isRequired'] as bool? ?? false,
      isReadOnly: map['isReadOnly'] as bool? ?? false,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
      validationRules: Map<String, dynamic>.from(map['validationRules'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'type': type.name,
      'valueType': valueType.name,
      'value': value,
      'defaultValue': defaultValue,
      'description': description,
      'isRequired': isRequired,
      'isReadOnly': isReadOnly,
      'isEncrypted': isEncrypted,
      'validationRules': validationRules,
      'tags': tags,
      'details': details,
    };
  }
  
  /// 验证值
  bool validate() {
    if (isRequired && value == null) {
      return false;
    }
    
    if (value == null) {
      return true;
    }
    
    // 类型检查
    switch (valueType) {
      case ConfigValueType.string:
        if (value is! String) {
          return false;
        }
        break;
      case ConfigValueType.integer:
        if (value is! int) {
          return false;
        }
        break;
      case ConfigValueType.double:
        if (value is! double) {
          return false;
        }
        break;
      case ConfigValueType.boolean:
        if (value is! bool) {
          return false;
        }
        break;
      case ConfigValueType.list:
        if (value is! List) {
          return false;
        }
        break;
      case ConfigValueType.map:
        if (value is! Map) {
          return false;
        }
        break;
    }
    
    // 验证规则检查
    if (validationRules.containsKey('min') &&
        value is num &&
        value < validationRules['min']) {
      return false;
    }
    
    if (validationRules.containsKey('max') &&
        value is num &&
        value > validationRules['max']) {
      return false;
    }
    
    if (validationRules.containsKey('minLength') &&
        value is String &&
        value.length < validationRules['minLength']) {
      return false;
    }
    
    if (validationRules.containsKey('maxLength') &&
        value is String &&
        value.length > validationRules['maxLength']) {
      return false;
    }
    
    if (validationRules.containsKey('pattern') &&
        value is String &&
        !RegExp(validationRules['pattern']).hasMatch(value)) {
      return false;
    }
    
    return true;
  }
}

/// 配置组
class ConfigGroup {
  /// 组ID
  final String id;
  
  /// 组名称
  final String name;
  
  /// 组描述
  final String description;
  
  /// 配置类型
  final ConfigType type;
  
  /// 配置项列表
  final Map<String, ConfigItem> items;
  
  /// 标签
  final List<String> tags;
  
  /// 详细信息
  final Map<String, dynamic> details;
  
  /// 构造函数
  ConfigGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.items = const {},
    this.tags = const [],
    this.details = const {},
  });
  
  /// 从Map创建配置组
  factory ConfigGroup.fromMap(Map<String, dynamic> map) {
    return ConfigGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      type: ConfigType.values.byName(map['type'] as String),
      items: (map['items'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ConfigItem.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      tags: List<String>.from(map['tags'] ?? []),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'items': items.map((key, value) => MapEntry(key, value.toMap())),
      'tags': tags,
      'details': details,
    };
  }
}

/// 配置管理服务
class ConfigManagementService {
  /// 日志服务
  final LoggingService _loggingService;
  
  /// 错误处理服务
  final ErrorHandlingService _errorHandlingService;
  
  /// 配置文件路径
  final String _configPath;
  
  /// 配置组映射
  final Map<String, ConfigGroup> _groups = {};
  
  /// 配置变更流控制器
  final StreamController<ConfigItem> _changeController =
      StreamController<ConfigItem>.broadcast();
  
  /// 配置变更流
  Stream<ConfigItem> get changeStream => _changeController.stream;
  
  /// 构造函数
  ConfigManagementService({
    required LoggingService loggingService,
    required ErrorHandlingService errorHandlingService,
    required String configPath,
  })  : _loggingService = loggingService,
        _errorHandlingService = errorHandlingService,
        _configPath = configPath {
    _initializeService();
  }
  
  /// 初始化服务
  Future<void> _initializeService() async {
    try {
      // 确保配置目录存在
      final directory = Directory(path.dirname(_configPath));
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      
      // 加载配置
      await loadConfig();
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.high,
        message: '初始化配置服务失败',
      );
    }
  }
  
  /// 加载配置
  Future<void> loadConfig() async {
    try {
      final file = File(_configPath);
      if (!file.existsSync()) {
        return;
      }
      
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      
      _groups.clear();
      data.forEach((key, value) {
        _groups[key] = ConfigGroup.fromMap(value as Map<String, dynamic>);
      });
      
      _loggingService.info('加载配置成功');
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.high,
        message: '加载配置失败',
      );
    }
  }
  
  /// 保存配置
  Future<void> saveConfig() async {
    try {
      final file = File(_configPath);
      final data = _groups.map((key, value) => MapEntry(key, value.toMap()));
      
      await file.writeAsString(
        json.encode(data),
        flush: true,
      );
      
      _loggingService.info('保存配置成功');
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.high,
        message: '保存配置失败',
      );
    }
  }
  
  /// 添加配置组
  void addGroup(ConfigGroup group) {
    _groups[group.id] = group;
  }
  
  /// 移除配置组
  void removeGroup(String groupId) {
    _groups.remove(groupId);
  }
  
  /// 更新配置组
  void updateGroup(ConfigGroup group) {
    _groups[group.id] = group;
  }
  
  /// 获取配置组
  ConfigGroup? getGroup(String groupId) {
    return _groups[groupId];
  }
  
  /// 获取所有配置组
  List<ConfigGroup> getAllGroups() {
    return List.unmodifiable(_groups.values);
  }
  
  /// 获取配置项
  ConfigItem? getItem(String groupId, String key) {
    return _groups[groupId]?.items[key];
  }
  
  /// 设置配置项
  Future<void> setItem(String groupId, ConfigItem item) async {
    try {
      final group = _groups[groupId];
      if (group == null) {
        throw Exception('配置组不存在');
      }
      
      if (item.isReadOnly) {
        throw Exception('配置项只读');
      }
      
      if (!item.validate()) {
        throw Exception('配置项验证失败');
      }
      
      group.items[item.key] = item;
      
      // 发送变更通知
      _changeController.add(item);
      
      // 保存配置
      await saveConfig();
      
      _loggingService.info(
        '更新配置项',
        tags: {
          'group_id': groupId,
          'key': item.key,
          'value': item.value.toString(),
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '设置配置项失败',
      );
      rethrow;
    }
  }
  
  /// 重置配置项
  Future<void> resetItem(String groupId, String key) async {
    try {
      final item = getItem(groupId, key);
      if (item == null) {
        return;
      }
      
      if (item.isReadOnly) {
        throw Exception('配置项只读');
      }
      
      if (item.defaultValue == null) {
        throw Exception('配置项没有默认值');
      }
      
      final resetItem = ConfigItem(
        key: item.key,
        type: item.type,
        valueType: item.valueType,
        value: item.defaultValue,
        defaultValue: item.defaultValue,
        description: item.description,
        isRequired: item.isRequired,
        isReadOnly: item.isReadOnly,
        isEncrypted: item.isEncrypted,
        validationRules: item.validationRules,
        tags: item.tags,
        details: item.details,
      );
      
      await setItem(groupId, resetItem);
      
      _loggingService.info(
        '重置配置项',
        tags: {
          'group_id': groupId,
          'key': key,
        },
      );
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '重置配置项失败',
      );
      rethrow;
    }
  }
  
  /// 导出配置
  Future<String> exportConfig() async {
    try {
      final data = _groups.map((key, value) => MapEntry(key, value.toMap()));
      return json.encode(data);
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.medium,
        message: '导出配置失败',
      );
      rethrow;
    }
  }
  
  /// 导入配置
  Future<void> importConfig(String data) async {
    try {
      final map = json.decode(data) as Map<String, dynamic>;
      
      _groups.clear();
      map.forEach((key, value) {
        _groups[key] = ConfigGroup.fromMap(value as Map<String, dynamic>);
      });
      
      await saveConfig();
      
      _loggingService.info('导入配置成功');
    } catch (e, s) {
      await _errorHandlingService.handleError(
        e,
        s,
        type: ErrorType.system,
        severity: ErrorSeverity.high,
        message: '导入配置失败',
      );
      rethrow;
    }
  }
  
  /// 关闭服务
  Future<void> dispose() async {
    await _changeController.close();
  }
}

/// 配置管理服务提供者
final configManagementServiceProvider = Provider<ConfigManagementService>((ref) {
  final loggingService = ref.watch(loggingServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);
  
  final service = ConfigManagementService(
    loggingService: loggingService,
    errorHandlingService: errorHandlingService,
    configPath: 'config/app_config.json',
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 配置变更流提供者
final configChangeStreamProvider = StreamProvider<ConfigItem>((ref) {
  final service = ref.watch(configManagementServiceProvider);
  return service.changeStream;
}); 