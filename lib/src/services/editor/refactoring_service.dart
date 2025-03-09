import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/intelligence/context_awareness_service.dart';
import 'dart:async';

/// 重构操作类型
enum RefactoringType {
  /// 重命名
  rename,
  
  /// 提取方法
  extractMethod,
  
  /// 提取变量
  extractVariable,
  
  /// 内联变量
  inlineVariable,
  
  /// 移动
  move,
  
  /// 修改签名
  changeSignature,
}

/// 重构操作结果
class RefactoringResult {
  /// 是否成功
  final bool success;
  
  /// 错误信息
  final String? errorMessage;
  
  /// 修改后的代码
  final String? newCode;
  
  /// 新的光标位置
  final int? newCursorPosition;
  
  /// 构造函数
  const RefactoringResult({
    required this.success,
    this.errorMessage,
    this.newCode,
    this.newCursorPosition,
  });
  
  /// 创建成功结果
  factory RefactoringResult.success(String newCode, [int? newCursorPosition]) {
    return RefactoringResult(
      success: true,
      newCode: newCode,
      newCursorPosition: newCursorPosition,
    );
  }
  
  /// 创建失败结果
  factory RefactoringResult.failure(String errorMessage) {
    return RefactoringResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// 代码重构服务
class RefactoringService {
  final LoggerService _logger;
  final ContextAwarenessService _contextAwareness;
  
  /// 构造函数
  RefactoringService(this._logger, this._contextAwareness);
  
  /// 执行重命名操作
  Future<RefactoringResult> rename(
    String code,
    int cursorPosition,
    String newName,
    String language,
    String filePath,
  ) async {
    try {
      // 获取光标位置的标识符
      final identifier = _getIdentifierAtPosition(code, cursorPosition);
      if (identifier == null) {
        return const RefactoringResult(
          success: false,
          errorMessage: '光标位置没有找到标识符',
        );
      }
      
      // 替换所有匹配的标识符
      final newCode = _replaceAllIdentifiers(code, identifier, newName);
      
      return RefactoringResult(
        success: true,
        newCode: newCode,
        newCursorPosition: cursorPosition,
      );
    } catch (e) {
      return RefactoringResult(
        success: false,
        errorMessage: '重命名失败: $e',
      );
    }
  }
  
  /// 执行提取方法操作
  Future<RefactoringResult> extractMethod(
    String code,
    int startPosition,
    int endPosition,
    String methodName,
    String language,
    String filePath,
  ) async {
    try {
      // 获取选中的代码
      final selectedCode = code.substring(startPosition, endPosition);
      if (selectedCode.isEmpty) {
        return const RefactoringResult(
          success: false,
          errorMessage: '没有选中代码',
        );
      }
      
      // 获取缩进
      final indentation = _getIndentation(code, startPosition);
      
      // 创建方法
      final methodCode = _createMethod(selectedCode, methodName, language, indentation);
      
      // 替换选中的代码
      final beforeSelection = code.substring(0, startPosition);
      final afterSelection = code.substring(endPosition);
      
      // 查找合适的插入位置
      final insertPosition = _findMethodInsertPosition(code, endPosition);
      
      // 插入方法并替换选中的代码
      final newCode = beforeSelection +
                     '$methodName()' +
                     afterSelection.substring(0, insertPosition - endPosition) +
                     '\n\n$methodCode\n' +
                     afterSelection.substring(insertPosition - endPosition);
      
      return RefactoringResult(
        success: true,
        newCode: newCode,
        newCursorPosition: startPosition + methodName.length + 2,
      );
    } catch (e) {
      return RefactoringResult(
        success: false,
        errorMessage: '提取方法失败: $e',
      );
    }
  }
  
  /// 执行提取变量操作
  Future<RefactoringResult> extractVariable(
    String code,
    int startPosition,
    int endPosition,
    String variableName,
    String language,
    String filePath,
  ) async {
    try {
      // 获取选中的代码
      final selectedCode = code.substring(startPosition, endPosition);
      if (selectedCode.isEmpty) {
        return const RefactoringResult(
          success: false,
          errorMessage: '没有选中代码',
        );
      }
      
      // 获取缩进
      final indentation = _getIndentation(code, startPosition);
      
      // 创建变量声明
      final variableDeclaration = _createVariableDeclaration(
        selectedCode,
        variableName,
        language,
        indentation,
      );
      
      // 替换选中的代码
      final beforeSelection = code.substring(0, startPosition);
      final afterSelection = code.substring(endPosition);
      
      // 查找行的开始位置
      final lineStart = code.lastIndexOf('\n', startPosition) + 1;
      
      // 插入变量声明并替换选中的代码
      final newCode = beforeSelection.substring(0, lineStart) +
                     '$variableDeclaration\n$indentation' +
                     beforeSelection.substring(lineStart) +
                     variableName +
                     afterSelection;
      
      return RefactoringResult(
        success: true,
        newCode: newCode,
        newCursorPosition: startPosition + variableName.length,
      );
    } catch (e) {
      return RefactoringResult(
        success: false,
        errorMessage: '提取变量失败: $e',
      );
    }
  }
  
  /// 执行内联变量操作
  Future<RefactoringResult> inlineVariable(
    String code,
    int cursorPosition,
    String language,
    String filePath,
  ) async {
    try {
      // 获取光标位置的变量
      final variable = _getVariableAtPosition(code, cursorPosition);
      if (variable == null) {
        return const RefactoringResult(
          success: false,
          errorMessage: '光标位置没有找到变量',
        );
      }
      
      // 获取变量的值
      final variableValue = _getVariableValue(code, variable);
      if (variableValue == null) {
        return const RefactoringResult(
          success: false,
          errorMessage: '无法确定变量的值',
        );
      }
      
      // 替换所有变量引用
      final newCode = _replaceAllVariableReferences(code, variable, variableValue);
      
      // 删除变量声明
      final declarationRange = _findVariableDeclaration(code, variable);
      if (declarationRange != null) {
        final beforeDeclaration = newCode.substring(0, declarationRange.start);
        final afterDeclaration = newCode.substring(declarationRange.end);
        final finalCode = beforeDeclaration + afterDeclaration;
        
        return RefactoringResult(
          success: true,
          newCode: finalCode,
          newCursorPosition: cursorPosition - (declarationRange.end - declarationRange.start),
        );
      }
      
      return RefactoringResult(
        success: true,
        newCode: newCode,
        newCursorPosition: cursorPosition,
      );
    } catch (e) {
      return RefactoringResult(
        success: false,
        errorMessage: '内联变量失败: $e',
      );
    }
  }
  
  /// 获取光标位置的标识符
  String? _getIdentifierAtPosition(String code, int position) {
    if (position < 0 || position >= code.length) {
      return null;
    }
    
    // 向左查找标识符的开始
    int start = position;
    while (start > 0 && _isIdentifierChar(code[start - 1])) {
      start--;
    }
    
    // 向右查找标识符的结束
    int end = position;
    while (end < code.length && _isIdentifierChar(code[end])) {
      end++;
    }
    
    if (start == end) {
      return null;
    }
    
    return code.substring(start, end);
  }
  
  /// 判断字符是否为标识符字符
  bool _isIdentifierChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }
  
  /// 替换所有标识符
  String _replaceAllIdentifiers(String code, String oldName, String newName) {
    // 使用正则表达式替换所有完整的标识符
    final regex = RegExp('\\b$oldName\\b');
    return code.replaceAll(regex, newName);
  }
  
  /// 获取缩进
  String _getIndentation(String code, int position) {
    final lineStart = code.lastIndexOf('\n', position) + 1;
    final linePrefix = code.substring(lineStart, position);
    final match = RegExp(r'^\s*').firstMatch(linePrefix);
    return match?.group(0) ?? '';
  }
  
  /// 创建方法
  String _createMethod(String code, String methodName, String language, String indentation) {
    switch (language.toLowerCase()) {
      case 'dart':
        return '${indentation}void $methodName() {\n$indentation  $code\n$indentation}';
      case 'javascript':
      case 'js':
        return '${indentation}function $methodName() {\n$indentation  $code\n$indentation}';
      case 'python':
      case 'py':
        return '${indentation}def $methodName():\n$indentation    $code';
      default:
        return '${indentation}void $methodName() {\n$indentation  $code\n$indentation}';
    }
  }
  
  /// 查找方法插入位置
  int _findMethodInsertPosition(String code, int position) {
    // 查找下一个类或方法的结束位置
    final match = RegExp(r'(class|function|void|def)\s+\w+').firstMatch(code.substring(position));
    if (match != null) {
      return position + match.start;
    }
    
    // 如果没有找到，则返回代码结束位置
    return code.length;
  }
  
  /// 创建变量声明
  String _createVariableDeclaration(String expression, String variableName, String language, String indentation) {
    switch (language.toLowerCase()) {
      case 'dart':
        return '${indentation}final $variableName = $expression;';
      case 'javascript':
      case 'js':
        return '${indentation}const $variableName = $expression;';
      case 'python':
      case 'py':
        return '${indentation}$variableName = $expression';
      default:
        return '${indentation}var $variableName = $expression;';
    }
  }
  
  /// 获取光标位置的变量
  String? _getVariableAtPosition(String code, int position) {
    return _getIdentifierAtPosition(code, position);
  }
  
  /// 获取变量的值
  String? _getVariableValue(String code, String variable) {
    // 查找变量声明
    final regex = RegExp('(var|let|const|final)\\s+$variable\\s*=\\s*([^;]+);');
    final match = regex.firstMatch(code);
    if (match != null && match.groupCount >= 2) {
      return match.group(2)?.trim();
    }
    return null;
  }
  
  /// 替换所有变量引用
  String _replaceAllVariableReferences(String code, String variable, String value) {
    return _replaceAllIdentifiers(code, variable, value);
  }
  
  /// 查找变量声明
  _Range? _findVariableDeclaration(String code, String variable) {
    // 查找变量声明
    final regex = RegExp('(var|let|const|final)\\s+$variable\\s*=\\s*[^;]+;');
    final match = regex.firstMatch(code);
    if (match != null) {
      return _Range(match.start, match.end);
    }
    return null;
  }
}

/// 范围
class _Range {
  final int start;
  final int end;
  
  const _Range(this.start, this.end);
}

/// 代码重构服务提供者
final refactoringServiceProvider = Provider<RefactoringService>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final contextAwareness = ref.watch(contextAwarenessServiceProvider);
  return RefactoringService(logger, contextAwareness);
}); 