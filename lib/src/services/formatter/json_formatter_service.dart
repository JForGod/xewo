import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// JSON格式化服务
class JsonFormatterService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  JsonFormatterService(this._logger, this._settings);
  
  /// 格式化JSON
  Future<String> formatJson(String json) async {
    try {
      // 解析JSON
      final object = jsonDecode(json);
      
      // 获取缩进设置
      final indentSize = _settings.getIntValue('editor.json.formatter.indentSize', 2);
      
      // 格式化JSON
      return JsonEncoder.withIndent(' ' * indentSize).convert(object);
    } catch (e, stackTrace) {
      _logger.error('JSON格式化失败', e, stackTrace);
      return json; // 出错时返回原始JSON
    }
  }
  
  /// 验证JSON是否有效
  bool isValidJson(String json) {
    try {
      jsonDecode(json);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取JSON验证错误信息
  String? getJsonValidationError(String json) {
    try {
      jsonDecode(json);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  
  /// 压缩JSON（移除所有空白）
  String minifyJson(String json) {
    try {
      final object = jsonDecode(json);
      return jsonEncode(object);
    } catch (e, stackTrace) {
      _logger.error('JSON压缩失败', e, stackTrace);
      return json;
    }
  }
  
  /// 将对象转换为格式化的JSON
  String objectToFormattedJson(dynamic object) {
    try {
      final indentSize = _settings.getIntValue('editor.json.formatter.indentSize', 2);
      return JsonEncoder.withIndent(' ' * indentSize).convert(object);
    } catch (e, stackTrace) {
      _logger.error('对象转JSON失败', e, stackTrace);
      return object.toString();
    }
  }
}

/// JSON格式化服务提供者
final jsonFormatterServiceProvider = Provider<JsonFormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return JsonFormatterService(logger, settings);
}); 