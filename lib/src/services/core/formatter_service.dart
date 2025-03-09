import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/formatter/dart_formatter_service.dart';
import 'package:xewo/src/services/formatter/json_formatter_service.dart';
import 'package:xewo/src/services/formatter/cpp_formatter_service.dart';

/// 代码格式化服务
class FormatterService {
  final LoggerService _logger;
  final DartFormatterService _dartFormatter;
  final JsonFormatterService _jsonFormatter;
  final CppFormatterService _cppFormatter;
  
  /// 构造函数
  FormatterService(
    this._logger,
    this._dartFormatter,
    this._jsonFormatter,
    this._cppFormatter,
  );
  
  /// 格式化代码
  Future<String> formatCode(String code, String fileType) async {
    try {
      switch (fileType.toLowerCase()) {
        case 'dart':
          return await _dartFormatter.formatCode(code);
        case 'json':
          return await _jsonFormatter.formatJson(code);
        case 'cpp':
        case 'cc':
        case 'cxx':
        case 'h':
        case 'hpp':
        case 'hxx':
          return await _cppFormatter.formatCode(code);
        default:
          _logger.warning('不支持的文件类型: $fileType');
          return code;
      }
    } catch (e, stackTrace) {
      _logger.error('格式化代码失败', e, stackTrace);
      return code;
    }
  }
  
  /// 根据文件类型选择格式化方法
  Future<String> formatByFileType(String code, String filePath) async {
    final fileExtension = filePath.split('.').last.toLowerCase();
    return formatCode(code, fileExtension);
  }
}

/// 格式化服务提供者
final formatterServiceProvider = Provider<FormatterService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final dartFormatter = ref.watch(dartFormatterServiceProvider);
  final jsonFormatter = ref.watch(jsonFormatterServiceProvider);
  final cppFormatter = ref.watch(cppFormatterServiceProvider);
  
  return FormatterService(
    logger,
    dartFormatter,
    jsonFormatter,
    cppFormatter,
  );
}); 