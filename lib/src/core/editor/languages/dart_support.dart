import 'package:flutter/foundation.dart';
import '../language_support_base.dart';

/// Dart语言支持
class DartSupport extends LanguageSupportBase {
  // 简化的正则表达式
  static final RegExp _importRegex = RegExp('import\\s+[\'"]([^\'"]+)[\'"]');
  static final RegExp _exportRegex = RegExp('export\\s+[\'"]([^\'"]+)[\'"]');
  static final RegExp _classRegex = RegExp('class\\s+(\\w+)');
  static final RegExp _functionRegex = RegExp('\\w+\\s+(\\w+)\\s*\\(');
  static final RegExp _variableRegex = RegExp('(var|final|const)\\s+(\\w+)');

  @override
  String getFileExtension() => '.dart';

  @override
  List<String> getSupportedFileExtensions() => ['.dart'];

  @override
  bool canHandle(String fileExtension) => fileExtension.toLowerCase() == '.dart';

  @override
  String getLanguageName() => 'Dart';

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
      ],
      'surroundingPairs': [
        {'open': '{', 'close': '}'},
        {'open': '[', 'close': ']'},
        {'open': '(', 'close': ')'},
        {'open': "'", 'close': "'"},
        {'open': '"', 'close': '"'},
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
    };
  }

  @override
  bool isSourceFile(String fileName) {
    return fileName.toLowerCase().endsWith('.dart');
  }

  @override
  bool isConfigFile(String fileName) {
    final name = fileName.toLowerCase();
    return name == 'pubspec.yaml' || 
           name == 'analysis_options.yaml' || 
           name.endsWith('.iml');
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

  @override
  List<String> getImports(String code) {
    final imports = <String>[];
    
    for (final match in _importRegex.allMatches(code)) {
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
    
    for (final match in _functionRegex.allMatches(code)) {
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
    return name.endsWith('_test.dart') || 
           name.endsWith('.test.dart') || 
           name.endsWith('_spec.dart');
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
  String getTemplateStringDelimiter() => '"""';

  @override
  bool isValidIdentifier(String name) {
    return RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$').hasMatch(name);
  }

  @override
  bool isKeyword(String word) {
    const keywords = {
      'abstract', 'as', 'assert', 'async', 'await', 'break',
      'case', 'catch', 'class', 'const', 'continue', 'covariant',
      'default', 'deferred', 'do', 'dynamic', 'else', 'enum',
      'export', 'extends', 'extension', 'external', 'factory',
      'false', 'final', 'finally', 'for', 'Function', 'get',
      'hide', 'if', 'implements', 'import', 'in', 'interface',
      'is', 'late', 'library', 'mixin', 'new', 'null', 'on',
      'operator', 'part', 'required', 'rethrow', 'return', 'set',
      'show', 'static', 'super', 'switch', 'sync', 'this',
      'throw', 'true', 'try', 'typedef', 'var', 'void', 'while',
      'with', 'yield',
    };
    return keywords.contains(word);
  }

  @override
  bool isOperator(String text) {
    const operators = {
      '+', '-', '*', '/', '%', '++', '--', '=', '+=', '-=',
      '*=', '/=', '%=', '==', '!=', '>', '<', '>=', '<=',
      '&&', '||', '!', '&', '|', '^', '~', '<<', '>>', '>>>=',
      '??', '?.', '..', '...', '?..', '??=', '..=', '?[]=',
      'is', 'is!', 'as', 'as?',
    };
    return operators.contains(text);
  }

  @override
  bool isTypeScript(String code) {
    return false; // Dart不是TypeScript
  }
} 