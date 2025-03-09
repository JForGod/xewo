import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/symbol_completion_provider.dart';
import 'providers/snippet_completion_provider.dart';

/// 补全项类型
enum CompletionItemKind {
  text,
  method,
  function,
  constructor,
  field,
  variable,
  class_,
  interface,
  module,
  property,
  unit,
  value,
  enum_,
  keyword,
  snippet,
  color,
  file,
  reference,
  folder,
  typeParameter,
}

/// 补全项
class CompletionItem {
  final String label;
  final String? detail;
  final String? documentation;
  final CompletionItemKind kind;
  final String insertText;
  final int? sortText;
  
  CompletionItem({
    required this.label,
    this.detail,
    this.documentation,
    required this.kind,
    String? insertText,
    this.sortText,
  }) : insertText = insertText ?? label;
}

/// 补全上下文
class CompletionContext {
  final String text;
  final int offset;
  final String? filePath;
  final String? fileType;
  
  CompletionContext({
    required this.text,
    required this.offset,
    this.filePath,
    this.fileType,
  });
  
  /// 获取触发补全的字符
  String get triggerCharacter {
    if (offset <= 0) return '';
    return text.substring(offset - 1, offset);
  }
  
  /// 获取当前行文本
  String get currentLine {
    final lines = text.substring(0, offset).split('\n');
    return lines.isEmpty ? '' : lines.last;
  }
  
  /// 获取当前单词
  String get currentWord {
    if (offset <= 0) return '';
    
    int start = offset;
    while (start > 0 && _isIdentifierChar(text[start - 1])) {
      start--;
    }
    
    return text.substring(start, offset);
  }
  
  bool _isIdentifierChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }
  
  /// 获取当前行缩进
  String get currentIndent {
    final line = currentLine;
    final match = RegExp(r'^\s*').firstMatch(line);
    return match?.group(0) ?? '';
  }
}

/// 补全提供者接口
abstract class CompletionProvider {
  /// 获取补全建议
  Future<List<CompletionItem>> getCompletions(CompletionContext context);
  
  /// 是否可以处理此类型的文件
  bool canHandle(String? fileType);
}

/// 关键字补全提供者
class KeywordCompletionProvider implements CompletionProvider {
  final Map<String, List<String>> _keywords;
  
  KeywordCompletionProvider({
    Map<String, List<String>>? keywords,
  }) : _keywords = keywords ?? {
    'dart': [
      'abstract', 'as', 'assert', 'async', 'await',
      'break', 'case', 'catch', 'class', 'const',
      'continue', 'default', 'deferred', 'do',
      'dynamic', 'else', 'enum', 'export', 'extends',
      'extension', 'external', 'factory', 'false',
      'final', 'finally', 'for', 'Function', 'get',
      'hide', 'if', 'implements', 'import', 'in',
      'interface', 'is', 'library', 'mixin', 'new',
      'null', 'on', 'operator', 'part', 'rethrow',
      'return', 'set', 'show', 'static', 'super',
      'switch', 'sync', 'this', 'throw', 'true',
      'try', 'typedef', 'var', 'void', 'while',
      'with', 'yield',
    ],
  };
  
  @override
  bool canHandle(String? fileType) => fileType != null && _keywords.containsKey(fileType);
  
  @override
  Future<List<CompletionItem>> getCompletions(CompletionContext context) async {
    if (context.fileType == null || !_keywords.containsKey(context.fileType!)) {
      return [];
    }
    
    final word = context.currentWord.toLowerCase();
    if (word.isEmpty) return [];
    
    return _keywords[context.fileType!]!
        .where((kw) => kw.toLowerCase().startsWith(word))
        .map((kw) => CompletionItem(
          label: kw,
          kind: CompletionItemKind.keyword,
          sortText: 2, // 关键字排在变量后面
        ))
        .toList();
  }
}

/// 代码补全服务
class CompletionService {
  final List<CompletionProvider> _providers;
  Timer? _debounceTimer;
  
  CompletionService({
    List<CompletionProvider>? providers,
  }) : _providers = providers ?? [
    KeywordCompletionProvider(),
    SymbolCompletionProvider(),
    SnippetCompletionProvider(),
  ];
  
  /// 添加补全提供者
  void addProvider(CompletionProvider provider) {
    _providers.add(provider);
  }
  
  /// 获取补全建议
  Future<List<CompletionItem>> getCompletions(CompletionContext context) async {
    // 取消之前的延迟操作
    _debounceTimer?.cancel();
    
    // 创建新的延迟操作
    final completer = Completer<List<CompletionItem>>();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final results = <CompletionItem>[];
        
        // 并行获取所有提供者的补全结果
        final futures = _providers
            .where((provider) => provider.canHandle(context.fileType))
            .map((provider) => provider.getCompletions(context));
        
        final completions = await Future.wait(futures);
        for (final items in completions) {
          results.addAll(items);
        }
        
        // 按类型和标签排序
        results.sort((a, b) {
          // 首先按sortText排序
          if (a.sortText != null && b.sortText != null) {
            final compare = a.sortText!.compareTo(b.sortText!);
            if (compare != 0) return compare;
          }
          
          // 然后按标签排序
          return a.label.compareTo(b.label);
        });
        
        completer.complete(results);
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    return completer.future;
  }
  
  /// 检查是否应该触发补全
  bool shouldTriggerCompletion(String text, int offset) {
    if (offset <= 0) return false;
    
    // 获取触发字符
    final trigger = text.substring(offset - 1, offset);
    
    // 检查是否是触发字符
    if (trigger == '.' || trigger == '@' || trigger == ':') {
      return true;
    }
    
    // 检查是否正在输入标识符
    if (RegExp(r'[a-zA-Z0-9_]').hasMatch(trigger)) {
      // 获取当前单词
      int start = offset;
      while (start > 0 && RegExp(r'[a-zA-Z0-9_]').hasMatch(text[start - 1])) {
        start--;
      }
      final word = text.substring(start, offset);
      
      // 如果单词长度大于等于2，触发补全
      return word.length >= 2;
    }
    
    return false;
  }
  
  /// 处理补全项的插入
  String applyCompletion(CompletionItem item, String text, int offset) {
    // 获取需要替换的范围
    int start = offset;
    while (start > 0 && RegExp(r'[a-zA-Z0-9_]').hasMatch(text[start - 1])) {
      start--;
    }
    
    // 获取当前行的缩进
    final lines = text.substring(0, start).split('\n');
    final currentIndent = lines.isEmpty ? '' : RegExp(r'^\s*').firstMatch(lines.last)?.group(0) ?? '';
    
    // 处理多行插入文本的缩进
    String insertText = item.insertText;
    if (insertText.contains('\n')) {
      insertText = insertText.replaceAllMapped(
        RegExp(r'\n(?!$)'),
        (match) => '\n$currentIndent  ',
      );
    }
    
    // 替换文本
    return text.replaceRange(start, offset, insertText);
  }
}

/// 代码补全服务提供者
final completionServiceProvider = Provider<CompletionService>((ref) {
  return CompletionService();
}); 