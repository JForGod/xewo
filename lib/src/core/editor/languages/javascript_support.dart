import 'package:flutter/foundation.dart';
import '../language_support_base.dart';

/// JavaScript语言支持
class JavaScriptSupport extends LanguageSupportBase {
  // 简化的正则表达式
  static final RegExp _importRegex = RegExp('import.*from\\s+[\'"]([^\'"]+)[\'"]');
  static final RegExp _requireRegex = RegExp('require\\([\'"]([^\'"]+)[\'"]\\)');
  static final RegExp _exportRegex = RegExp('export.*?(\\w+)');
  static final RegExp _classRegex = RegExp('class\\s+(\\w+)');
  static final RegExp _functionRegex = RegExp('function\\s+(\\w+)');
  static final RegExp _arrowFunctionRegex = RegExp('const\\s+(\\w+)\\s*=.*=>');
  static final RegExp _variableRegex = RegExp('(var|let|const)\\s+(\\w+)');

  @override
  String getFileExtension() => '.js';

  @override
  List<String> getSupportedFileExtensions() => ['.js', '.jsx', '.ts', '.tsx'];

  @override
  bool canHandle(String fileExtension) {
    final ext = fileExtension.toLowerCase();
    return ext == '.js' || ext == '.jsx' || ext == '.ts' || ext == '.tsx';
  }

  @override
  String getLanguageName() => 'JavaScript';

  @override
  Map<String, dynamic> getLanguageConfiguration() {
    return {
      'comments': {
        'lineComment': '//',
        'blockComment': ['/*', '*/'],
      },
      'brackets': [
        ['{', '}'],
        ['[', ']'],
        ['(', ')'],
      ],
      'autoClosingPairs': [
        {'open': '{', 'close': '}'},
        {'open': '[', 'close': ']'},
        {'open': '(', 'close': ')'},
        {'open': "'", 'close': "'"},
        {'open': '"', 'close': '"'},
        {'open': '`', 'close': '`'},
      ],
      'surroundingPairs': [
        {'open': '{', 'close': '}'},
        {'open': '[', 'close': ']'},
        {'open': '(', 'close': ')'},
        {'open': "'", 'close': "'"},
        {'open': '"', 'close': '"'},
        {'open': '`', 'close': '`'},
      ],
    };
  }

  @override
  Map<String, dynamic> getTokenColors() {
    return {
      'keywords': {
        'foreground': '#569CD6',
        'fontStyle': 'bold',
      },
      'strings': {
        'foreground': '#CE9178',
      },
      'numbers': {
        'foreground': '#B5CEA8',
      },
      'comments': {
        'foreground': '#6A9955',
        'fontStyle': 'italic',
      },
      'functions': {
        'foreground': '#DCDCAA',
      },
      'classes': {
        'foreground': '#4EC9B0',
      },
      'variables': {
        'foreground': '#9CDCFE',
      },
      'types': {
        'foreground': '#4EC9B0',
      },
      'jsx': {
        'tags': {
          'foreground': '#569CD6',
        },
        'attributes': {
          'foreground': '#9CDCFE',
        },
      },
    };
  }

  @override
  bool isSourceFile(String fileName) {
    final ext = fileName.toLowerCase();
    return ext.endsWith('.js') || 
           ext.endsWith('.jsx') || 
           ext.endsWith('.ts') || 
           ext.endsWith('.tsx');
  }

  @override
  bool isConfigFile(String fileName) {
    final name = fileName.toLowerCase();
    return name == 'package.json' || 
           name == 'tsconfig.json' || 
           name.endsWith('.jsconfig.json') || 
           name.endsWith('.babelrc');
  }

  @override
  List<String> getImports(String code) {
    final imports = <String>[];
    
    // ES6 imports
    for (final match in _importRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        imports.add(match.group(1)!);
      }
    }
    
    // CommonJS requires
    for (final match in _requireRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        imports.add(match.group(1)!);
      }
    }
    
    return imports;
  }

  @override
  List<String> getExports(String code) {
    final exports = <String>[];
    
    for (final match in _exportRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        exports.add(match.group(1)!);
      }
    }
    
    return exports;
  }

  @override
  List<String> getClasses(String code) {
    final classes = <String>[];
    
    for (final match in _classRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        classes.add(match.group(1)!);
      }
    }
    
    return classes;
  }

  @override
  List<String> getFunctions(String code) {
    final functions = <String>[];
    
    // 普通函数
    for (final match in _functionRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        functions.add(match.group(1)!);
      }
    }
    
    // 箭头函数
    for (final match in _arrowFunctionRegex.allMatches(code)) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        functions.add(match.group(1)!);
      }
    }
    
    return functions;
  }

  @override
  List<String> getVariables(String code) {
    final variables = <String>[];
    
    for (final match in _variableRegex.allMatches(code)) {
      if (match.groupCount >= 2 && match.group(2) != null) {
        variables.add(match.group(2)!);
      }
    }
    
    return variables;
  }

  @override
  bool isTestFile(String fileName) {
    final name = fileName.toLowerCase();
    return name.endsWith('.test.js') || 
           name.endsWith('.spec.js') || 
           name.endsWith('.test.ts') || 
           name.endsWith('.spec.ts');
  }

  @override
  String getCommentStart() => '//';

  @override
  String getCommentEnd() => '';

  @override
  String getBlockCommentStart() => '/*';

  @override
  String getBlockCommentEnd() => '*/';

  @override
  String getLineCommentStart() => '//';

  @override
  String getStringDelimiter() => '"';

  @override
  String getAlternativeStringDelimiter() => "'";

  @override
  String getTemplateStringDelimiter() => '`';

  @override
  bool isValidIdentifier(String name) {
    return RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$').hasMatch(name);
  }

  @override
  bool isKeyword(String word) {
    const keywords = {
      'break', 'case', 'catch', 'class', 'const', 'continue',
      'debugger', 'default', 'delete', 'do', 'else', 'export',
      'extends', 'finally', 'for', 'function', 'if', 'import',
      'in', 'instanceof', 'new', 'return', 'super', 'switch',
      'this', 'throw', 'try', 'typeof', 'var', 'void', 'while',
      'with', 'yield', 'enum', 'implements', 'interface',
      'let', 'package', 'private', 'protected', 'public',
      'static', 'await', 'abstract', 'boolean', 'byte', 'char',
      'double', 'final', 'float', 'goto', 'int', 'long', 'native',
      'short', 'synchronized', 'throws', 'transient', 'volatile',
    };
    return keywords.contains(word);
  }

  @override
  bool isOperator(String text) {
    const operators = {
      '+', '-', '*', '/', '%', '++', '--', '=', '+=', '-=',
      '*=', '/=', '%=', '==', '===', '!=', '!==', '>', '<',
      '>=', '<=', '&&', '||', '!', '&', '|', '^', '~', '<<',
      '>>', '>>>', '<<=', '>>=', '>>>=', '?', ':', '??', '?.',
      '...', '=>', 'instanceof', 'in', 'typeof', 'void', 'delete',
    };
    return operators.contains(text);
  }

  @override
  bool isTypeScript(String code) {
    return code.contains(':') || // 类型注解
           code.contains('interface') || // 接口定义
           code.contains('enum') || // 枚举定义
           code.contains('<') || // 泛型
           code.contains('>'); // 泛型
  }

  @override
  String highlightCode(String code) {
    // 实现代码高亮逻辑
    return code;
  }

  @override
  List<String> getCompletionSuggestions(String code, int offset) {
    // 实现代码补全建议逻辑
    return [];
  }

  @override
  List<String> getSnippets() {
    // 返回常用代码片段
    return [];
  }

  @override
  String getAutoIndent(String code, int lineNumber) {
    // 实现自动缩进逻辑
    return '';
  }
} 