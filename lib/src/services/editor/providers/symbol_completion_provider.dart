import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;
import '../completion_service.dart';

/// 符号补全提供者
class SymbolCompletionProvider implements CompletionProvider {
  AnalysisContextCollection? _collection;
  String? _sdkPath;
  
  SymbolCompletionProvider() {
    _initSdkPath();
  }
  
  void _initSdkPath() {
    try {
      // 从环境变量获取Flutter SDK路径
      final flutterHome = Platform.environment['FLUTTER_ROOT'];
      if (flutterHome != null) {
        _sdkPath = path.join(flutterHome, 'bin', 'cache', 'dart-sdk');
        return;
      }
      
      // 如果环境变量不存在，尝试从Flutter命令获取
      final flutterCommand = Platform.isWindows ? 'flutter.bat' : 'flutter';
      final result = Process.runSync(flutterCommand, ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'Flutter \d+\.\d+\.\d+').firstMatch(output);
        if (match != null) {
          // 使用Flutter命令所在目录的父目录作为SDK路径
          final flutterPath = Process.runSync('where', [flutterCommand]).stdout.toString().trim();
          final flutterHome = path.dirname(path.dirname(flutterPath));
          _sdkPath = path.join(flutterHome, 'bin', 'cache', 'dart-sdk');
        }
      }
    } catch (e) {
      print('获取Flutter SDK路径失败: $e');
    }
  }
  
  @override
  bool canHandle(String? fileType) => fileType == 'dart';
  
  @override
  Future<List<CompletionItem>> getCompletions(CompletionContext context) async {
    if (context.filePath == null || _sdkPath == null) return [];
    
    try {
      // 确保使用绝对路径
      final absolutePath = path.isAbsolute(context.filePath!)
          ? context.filePath!
          : path.normalize(path.join(Directory.current.path, context.filePath!));
      
      // 初始化分析上下文
      _collection ??= AnalysisContextCollection(
        includedPaths: [absolutePath],
        sdkPath: _sdkPath,
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );
      
      final analysisContext = _collection!.contextFor(absolutePath);
      final session = analysisContext.currentSession;
      
      // 获取解析结果
      final parseResult = await session.getResolvedUnit(absolutePath);
      if (parseResult is! ResolvedUnitResult) return [];
      
      final unit = parseResult.unit;
      final offset = context.offset;
      
      // 收集可见的符号
      final symbols = <CompletionItem>[];
      
      // 收集本地变量和参数
      final visitor = _SymbolVisitor(symbols);
      unit.accept(visitor);
      
      // 收集类成员
      for (final type in unit.declaredElement!.library.exportNamespace.definedNames.values) {
        if (type is ClassElement) {
          // 添加方法
          for (final method in type.methods) {
            symbols.add(CompletionItem(
              label: method.name,
              kind: CompletionItemKind.method,
              detail: method.type.toString(),
              documentation: method.documentationComment,
              sortText: 2,
            ));
          }
          
          // 添加字段
          for (final field in type.fields) {
            symbols.add(CompletionItem(
              label: field.name,
              kind: CompletionItemKind.field,
              detail: field.type.toString(),
              documentation: field.documentationComment,
              sortText: 2,
            ));
          }
        }
      }
      
      // 过滤并排序结果
      final prefix = context.currentWord.toLowerCase();
      return symbols
          .where((item) => item.label.toLowerCase().startsWith(prefix))
          .toList()
        ..sort((a, b) {
          // 首先按sortText排序
          final sortCompare = (a.sortText ?? 0).compareTo(b.sortText ?? 0);
          if (sortCompare != 0) return sortCompare;
          
          // 然后按标签排序
          return a.label.compareTo(b.label);
        });
        
    } catch (e) {
      print('符号补全错误: $e');
      return [];
    }
  }
}

/// 符号访问器
class _SymbolVisitor extends RecursiveAstVisitor<void> {
  final List<CompletionItem> symbols;
  
  _SymbolVisitor(this.symbols);
  
  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final element = node.declaredElement;
    if (element != null) {
      symbols.add(CompletionItem(
        label: element.name,
        kind: CompletionItemKind.variable,
        detail: element.type.toString(),
        sortText: 1, // 本地变量优先
      ));
    }
    super.visitVariableDeclaration(node);
  }
  
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.staticElement;
    if (element is VariableElement) {
      symbols.add(CompletionItem(
        label: element.name,
        kind: CompletionItemKind.variable,
        detail: element.type.toString(),
        sortText: 1,
      ));
    }
    super.visitSimpleIdentifier(node);
  }
} 