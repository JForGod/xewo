import 'language_parser.dart';
import '../../core/logger_service.dart';
import '../context_awareness_service.dart';

/// C++语言解析器
class CppParser implements LanguageParser {
  final _logger = LoggerService();
  
  // 导入正则表达式
  final RegExp _includeRegex = RegExp(
    r'#include\s*[<"]([^>"]+)[>"]'
  );
  
  // 类定义正则表达式
  final RegExp _classRegex = RegExp(
    r'(?:class|struct)\s+(\w+)(?:\s*:\s*(?:public|protected|private)\s+(\w+))?'
  );
  
  // 函数定义正则表达式
  final RegExp _functionRegex = RegExp(
    r'(?:\w+\s+)*(\w+)\s*\([^)]*\)\s*(?:const)?\s*(?:override)?\s*(?:=\s*0)?'
  );
  
  // 变量定义正则表达式
  final RegExp _variableRegex = RegExp(
    r'(?:static\s+)?(?:const\s+)?(?:\w+\s+)+(\w+)(?:\s*=\s*[^;]+)?;'
  );

  @override
  Future<List<ContextInfo>> parseImports(String code) async {
    final imports = <ContextInfo>[];
    
    final matches = _includeRegex.allMatches(code);
    for (final match in matches) {
      final importPath = match.group(1);
      if (importPath != null) {
        imports.add(ContextInfo(
          id: 'import_${DateTime.now().millisecondsSinceEpoch}',
          type: ContextType.import,
          name: importPath,
          range: ContextRange(
            start: match.start,
            end: match.end,
            line: _getLineNumber(code, match.start),
            column: _getColumnNumber(code, match.start),
          ),
          analyzedAt: DateTime.now(),
        ));
      }
    }
    
    return imports;
  }

  @override
  Future<List<ContextInfo>> parseClasses(String code) async {
    final classes = <ContextInfo>[];
    
    final matches = _classRegex.allMatches(code);
    for (final match in matches) {
      final className = match.group(1);
      final baseClass = match.group(2);
      
      if (className != null) {
        classes.add(ContextInfo(
          id: 'class_${DateTime.now().millisecondsSinceEpoch}',
          type: ContextType.class_,
          name: className,
          range: ContextRange(
            start: match.start,
            end: match.end,
            line: _getLineNumber(code, match.start),
            column: _getColumnNumber(code, match.start),
          ),
          metadata: {
            'baseClass': baseClass,
          },
          analyzedAt: DateTime.now(),
        ));
      }
    }
    
    return classes;
  }

  @override
  Future<List<ContextInfo>> parseFunctions(String code) async {
    final functions = <ContextInfo>[];
    
    final matches = _functionRegex.allMatches(code);
    for (final match in matches) {
      final functionName = match.group(1);
      if (functionName != null) {
        functions.add(ContextInfo(
          id: 'function_${DateTime.now().millisecondsSinceEpoch}',
          type: ContextType.function,
          name: functionName,
          range: ContextRange(
            start: match.start,
            end: match.end,
            line: _getLineNumber(code, match.start),
            column: _getColumnNumber(code, match.start),
          ),
          analyzedAt: DateTime.now(),
        ));
      }
    }
    
    return functions;
  }

  @override
  Future<List<ContextInfo>> parseVariables(String code) async {
    final variables = <ContextInfo>[];
    
    final matches = _variableRegex.allMatches(code);
    for (final match in matches) {
      final variableName = match.group(1);
      if (variableName != null) {
        variables.add(ContextInfo(
          id: 'variable_${DateTime.now().millisecondsSinceEpoch}',
          type: ContextType.variable,
          name: variableName,
          range: ContextRange(
            start: match.start,
            end: match.end,
            line: _getLineNumber(code, match.start),
            column: _getColumnNumber(code, match.start),
          ),
          analyzedAt: DateTime.now(),
        ));
      }
    }
    
    return variables;
  }

  /// 获取行号
  int _getLineNumber(String code, int offset) {
    return code.substring(0, offset).split('\n').length;
  }

  /// 获取列号
  int _getColumnNumber(String code, int offset) {
    final lines = code.substring(0, offset).split('\n');
    return lines.isEmpty ? 1 : lines.last.length + 1;
  }
} 