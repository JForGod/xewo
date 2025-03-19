// 2025-03-20: 新增 - 代码块解析器工具类

import '../models/chat_message.dart';
import 'package:flutter/foundation.dart';

/// 代码块解析器
/// 
/// 用于从AI回复中识别和提取代码块
class CodeBlockParser {
  /// 解析包含代码块的文本
  /// 
  /// 返回解析后的文本和提取的代码块列表
  static List<CodeBlock> parseCodeBlocks(String text) {
    final List<CodeBlock> codeBlocks = [];
    
    // 匹配Markdown风格的代码块（```language\ncode```）
    final RegExp markdownRegex = RegExp(
      r'```([a-zA-Z0-9_+-]*)?\s*\n([\s\S]*?)\n```',
      multiLine: true,
    );
    
    // 查找所有匹配项
    final matches = markdownRegex.allMatches(text);
    
    for (final match in matches) {
      final language = match.group(1)?.trim() ?? '';
      final code = match.group(2) ?? '';
      
      // 尝试从代码中提取标题（如果第一行是注释）
      String title = '';
      final codeLines = code.split('\n');
      if (codeLines.isNotEmpty) {
        final firstLine = codeLines[0].trim();
        if (firstLine.startsWith('//') || 
            firstLine.startsWith('#') || 
            firstLine.startsWith('/*') || 
            firstLine.startsWith('<!--')) {
          title = firstLine.replaceAll(RegExp(r'^[/#\s\*<!--]*'), '').trim();
          title = title.replaceAll(RegExp(r'[\*]*-->$'), '').trim();
        }
      }
      
      codeBlocks.add(
        CodeBlock(
          language: language.isNotEmpty ? language : _guessLanguage(code),
          code: code,
          title: title,
        ),
      );
    }
    
    return codeBlocks;
  }
  
  /// 将文本中的代码块替换为占位符
  /// 
  /// 返回替换后的文本
  static String replaceCodeBlocksWithPlaceholders(String text) {
    return text.replaceAllMapped(
      RegExp(r'```([a-zA-Z0-9_+-]*)?\s*\n([\s\S]*?)\n```', multiLine: true),
      (match) => '[CODE_BLOCK_PLACEHOLDER]',
    );
  }
  
  /// 尝试根据代码内容猜测编程语言
  static String _guessLanguage(String code) {
    // 简单的语言检测逻辑
    if (code.contains('import React') || code.contains('className=') || code.contains('export default')) {
      return 'javascript';
    } else if (code.contains('<html') || code.contains('<!DOCTYPE html') || code.contains('</div>')) {
      return 'html';
    } else if (code.contains('import Flutter') || code.contains('Widget build') || code.contains('extends StatelessWidget')) {
      return 'dart';
    } else if (code.contains('func ') && code.contains('fmt.') && code.contains('{')) {
      return 'go';
    } else if (code.contains('def ') && code.contains(':') && !code.contains('{')) {
      return 'python';
    } else if (code.contains('public class ') || code.contains('private ') || code.contains('System.out.println')) {
      return 'java';
    } else if (code.contains('#include') || code.contains('int main')) {
      return 'cpp';
    } else if (code.contains('using System;') || code.contains('namespace ') || code.contains('public class ')) {
      return 'csharp';
    }
    
    return 'text';
  }
  
  /// 解析代码引用（例如行号引用）
  static List<CodeReference> parseCodeReferences(String text) {
    final List<CodeReference> references = [];
    
    // 匹配代码引用模式 (例如: ```12:15:path/to/file.ext)
    final RegExp referenceRegex = RegExp(
      r'```(\d+):(\d+):([^\n]+)\s*\n([\s\S]*?)\n```',
      multiLine: true,
    );
    
    // 查找所有匹配项
    final matches = referenceRegex.allMatches(text);
    
    for (final match in matches) {
      final startLine = int.parse(match.group(1) ?? '0');
      final endLine = int.parse(match.group(2) ?? '0');
      final filePath = match.group(3) ?? '';
      final code = match.group(4) ?? '';
      
      references.add(
        CodeReference(
          startLine: startLine,
          endLine: endLine,
          filePath: filePath,
          code: code,
        ),
      );
    }
    
    return references;
  }
}

/// 代码引用
class CodeReference {
  /// 起始行
  final int startLine;
  
  /// 结束行
  final int endLine;
  
  /// 文件路径
  final String filePath;
  
  /// 代码内容
  final String code;
  
  /// 构造函数
  const CodeReference({
    required this.startLine,
    required this.endLine,
    required this.filePath,
    required this.code,
  });
  
  @override
  String toString() {
    return 'CodeReference($startLine:$endLine:$filePath)';
  }
} 