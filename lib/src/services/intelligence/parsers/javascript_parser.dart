import '../context_awareness_service.dart';
import 'language_parser.dart';
import '../../core/logger_service.dart';

/// JavaScript/TypeScript语言解析器
class JavaScriptParser extends LanguageParser {
  final _logger = LoggerService();
  
  // 简化的正则表达式
  static final RegExp _importRegex = RegExp('import.*from\\s+[\'"]([^\'"]+)[\'"]');
  static final RegExp _requireRegex = RegExp('require\\([\'"]([^\'"]+)[\'"]\\)');
  static final RegExp _exportRegex = RegExp('export.*?(\\w+)');
  static final RegExp _classRegex = RegExp('class\\s+(\\w+)');
  static final RegExp _functionRegex = RegExp('function\\s+(\\w+)');
  static final RegExp _arrowFunctionRegex = RegExp('const\\s+(\\w+)\\s*=.*=>');
  static final RegExp _variableRegex = RegExp('(var|let|const)\\s+(\\w+)');

  @override
  List<String> findImports(String code) {
    final imports = <String>[];
    
    for (final match in _importRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        imports.add(match.group(1)!);
      }
    }
    
    for (final match in _requireRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        imports.add(match.group(1)!);
      }
    }
    
    return imports;
  }

  @override
  List<String> findClasses(String code) {
    final classes = <String>[];
    
    for (final match in _classRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        classes.add(match.group(1)!);
      }
    }
    
    return classes;
  }

  @override
  List<String> findFunctions(String code) {
    final functions = <String>[];
    
    for (final match in _functionRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        functions.add(match.group(1)!);
      }
    }
    
    for (final match in _arrowFunctionRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        functions.add(match.group(1)!);
      }
    }
    
    return functions;
  }

  @override
  List<String> findVariables(String code) {
    final variables = <String>[];
    
    for (final match in _variableRegex.allMatches(code)) {
      if (match.groupCount >= 2 && match.group(2) != null) {
        variables.add(match.group(2)!);
      }
    }
    
    return variables;
  }

  @override
  List<String> findExports(String code) {
    final exports = <String>[];
    
    for (final match in _exportRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        exports.add(match.group(1)!);
      }
    }
    
    return exports;
  }

  @override
  List<String> findDependencies(String code) {
    return findImports(code);
  }

  @override
  List<String> findDeclarations(String code) {
    final declarations = <String>[];
    
    declarations.addAll(findClasses(code));
    declarations.addAll(findFunctions(code));
    declarations.addAll(findVariables(code));
    
    return declarations;
  }

  @override
  bool isTestFile(String fileName) {
    return fileName.toLowerCase().contains('test') || 
           fileName.toLowerCase().contains('spec');
  }

  @override
  bool isConfigFile(String fileName) {
    return fileName.toLowerCase().endsWith('.json') || 
           fileName.toLowerCase().endsWith('.config.js');
  }

  @override
  bool isSourceFile(String fileName) {
    return fileName.toLowerCase().endsWith('.js') || 
           fileName.toLowerCase().endsWith('.jsx') || 
           fileName.toLowerCase().endsWith('.ts') || 
           fileName.toLowerCase().endsWith('.tsx');
  }

  @override
  String getLanguageName() {
    return 'JavaScript';
  }

  @override
  List<String> getSupportedFileExtensions() {
    return ['.js', '.jsx', '.ts', '.tsx'];
  }

  @override
  Future<List<ContextInfo>> parseImports(String code) async {
    final imports = <ContextInfo>[];
    
    // 解析ES6导入
    final es6Matches = _importRegex.allMatches(code);
    for (final match in es6Matches) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        final importPath = match.group(1)!;
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
    
    // 解析CommonJS require
    final requireMatches = _requireRegex.allMatches(code);
    for (final match in requireMatches) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        final importPath = match.group(1)!;
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
      if (match.groupCount >= 1 && match.group(1) != null) {
        final className = match.group(1)!;
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
            'isTypeScript': _isTypeScript(code),
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
    
    // 解析普通函数
    final functionMatches = _functionRegex.allMatches(code);
    for (final match in functionMatches) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        final functionName = match.group(1)!;
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
          metadata: {
            'isTypeScript': _isTypeScript(code),
          },
          analyzedAt: DateTime.now(),
        ));
      }
    }
    
    // 解析箭头函数
    final arrowMatches = _arrowFunctionRegex.allMatches(code);
    for (final match in arrowMatches) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        final functionName = match.group(1)!;
        functions.add(ContextInfo(
          id: 'arrow_function_${DateTime.now().millisecondsSinceEpoch}',
          type: ContextType.function,
          name: functionName,
          range: ContextRange(
            start: match.start,
            end: match.end,
            line: _getLineNumber(code, match.start),
            column: _getColumnNumber(code, match.start),
          ),
          metadata: {
            'isArrowFunction': true,
            'isTypeScript': _isTypeScript(code),
          },
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
      if (match.groupCount >= 2 && match.group(2) != null) {
        final variableName = match.group(2)!;
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
          metadata: {
            'isTypeScript': _isTypeScript(code),
          },
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

  /// 检查是否为TypeScript代码
  bool _isTypeScript(String code) {
    return code.contains(':') || // 类型注解
           code.contains('interface') || // 接口定义
           code.contains('enum') || // 枚举定义
           code.contains('<') || // 泛型
           code.contains('>'); // 泛型
  }
} 