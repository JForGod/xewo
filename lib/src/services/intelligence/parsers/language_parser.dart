import '../context_awareness_service.dart';

/// 语言解析器接口
abstract class LanguageParser {
  /// 解析导入语句
  Future<List<ContextInfo>> parseImports(String code);
  
  /// 解析类定义
  Future<List<ContextInfo>> parseClasses(String code);
  
  /// 解析函数定义
  Future<List<ContextInfo>> parseFunctions(String code);
  
  /// 解析变量定义
  Future<List<ContextInfo>> parseVariables(String code);
} 