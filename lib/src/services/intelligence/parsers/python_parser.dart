import 'language_parser.dart';
import '../../core/logger_service.dart';
import '../context_awareness_service.dart';

/// Python语言解析器
class PythonParser implements LanguageParser {
  final _logger = LoggerService();
  
  // 导入正则表达式
  final RegExp _importRegex = RegExp(
    r'(?:from\s+(\w+(?:\.\w+)*)\s+)?import\s+(\w+(?:\s*,\s*\w+)*)'
  );
  
  // 类定义正则表达式
  final RegExp _classRegex = RegExp(
    r'class\s+(\w+)(?:\(([^)]+)\))?:'
  );
  
  // 函数定义正则表达式
  final RegExp _functionRegex = RegExp(
    r'def\s+(\w+)\s*\([^)]*\)\s*(?:->\s*[^:]+)?:'
  );
  
  // 变量定义正则表达式
  final RegExp _variableRegex = RegExp(
    r'(\w+)\s*(?::\s*[^=]+)?\s*=\s*[^=]'
  );

  @override
  Future<List<ContextInfo>> parseImports(String code) async {
    final imports = <ContextInfo>[];
    
    final matches = _importRegex.allMatches(code);
    for (final match in matches) {
      final fromModule = match.group(1);
      final importNames = match.group(2);
      
      if (importNames != null) {
        final names = importNames.split(',').map((n) => n.trim());
        for (final name in names) {
          imports.add(ContextInfo(
            id: 'import_${DateTime.now().millisecondsSinceEpoch}',
            type: ContextType.import,
            name: fromModule != null ? '$fromModule.$name' : name,
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
    }
    
    return imports;
  }

  @override
  Future<List<ContextInfo>> parseClasses(String code) async {
    final classes = <ContextInfo>[];
    
    final matches = _classRegex.allMatches(code);
    for (final match in matches) {
      final className = match.group(1);
      final baseClasses = match.group(2);
      
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
            'baseClasses': baseClasses?.split(',').map((s) => s.trim()).toList(),
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

/// 行信息
class _LineInfo {
  final int line;
  final int column;
  
  _LineInfo(this.line, this.column);
}

/// Math工具类
class Math {
  static int max(int a, int b) => a > b ? a : b;
} 