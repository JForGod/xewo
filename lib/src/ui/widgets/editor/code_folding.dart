import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 代码折叠区域
class FoldingRegion {
  final int startLine;
  final int endLine;
  final String placeholder;
  bool isFolded;

  FoldingRegion({
    required this.startLine,
    required this.endLine,
    required this.placeholder,
    this.isFolded = false,
  });
}

/// 代码折叠管理器
class CodeFoldingManager {
  final List<FoldingRegion> regions = [];

  /// 分析代码并找出可折叠区域
  void analyzeFoldingRegions(String code, String language) {
    regions.clear();
    final lines = code.split('\n');
    
    switch (language.toLowerCase()) {
      case 'dart':
        _analyzeDartCode(lines);
        break;
      case 'json':
        _analyzeJsonCode(lines);
        break;
      case 'yaml':
        _analyzeYamlCode(lines);
        break;
      case 'javascript':
      case 'js':
        _analyzeJavaScriptFoldingRegions(code);
        break;
      case 'typescript':
      case 'ts':
        _analyzeTypeScriptFoldingRegions(code);
        break;
      case 'python':
      case 'py':
        _analyzePythonFoldingRegions(code);
        break;
      case 'html':
        _analyzeHtmlFoldingRegions(code);
        break;
      case 'css':
        _analyzeCssFoldingRegions(code);
        break;
      case 'markdown':
      case 'md':
        _analyzeMarkdownFoldingRegions(code);
        break;
      default:
        _analyzeGenericCode(lines);
    }
  }

  /// 分析Dart代码的可折叠区域
  void _analyzeDartCode(List<String> lines) {
    int braceCount = 0;
    int? startLine;
    String? blockType;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 检测类定义
      if (line.startsWith('class ') || line.startsWith('abstract class ')) {
        startLine = i;
        blockType = 'class';
        continue;
      }

      // 检测函数定义
      if (RegExp(r'^\w+\s+\w+\([^)]*\)\s*{').hasMatch(line)) {
        startLine = i;
        blockType = 'function';
        continue;
      }

      // 计算花括号
      braceCount += '{'.allMatches(line).length;
      braceCount -= '}'.allMatches(line).length;

      // 检测块结束
      if (braceCount == 0 && startLine != null) {
        if (i > startLine + 1) { // 至少包含一行
          String placeholder = '...';
          if (blockType == 'class') {
            placeholder = '// 类定义...';
          } else if (blockType == 'function') {
            placeholder = '// 函数体...';
          }
          
          regions.add(FoldingRegion(
            startLine: startLine + 1,
            endLine: i,
            placeholder: placeholder,
          ));
        }
        startLine = null;
        blockType = null;
      }
    }
  }

  /// 分析JSON代码的可折叠区域
  void _analyzeJsonCode(List<String> lines) {
    int braceCount = 0;
    int bracketCount = 0;
    int? startLine;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 计算花括号和方括号
      braceCount += '{'.allMatches(line).length;
      braceCount -= '}'.allMatches(line).length;
      bracketCount += '['.allMatches(line).length;
      bracketCount -= ']'.allMatches(line).length;

      if (startLine == null && (line.endsWith('{') || line.endsWith('['))) {
        startLine = i;
        continue;
      }

      if (startLine != null && braceCount == 0 && bracketCount == 0) {
        if (i > startLine + 1) {
          regions.add(FoldingRegion(
            startLine: startLine + 1,
            endLine: i,
            placeholder: '// ...',
          ));
        }
        startLine = null;
      }
    }
  }

  /// 分析YAML代码的可折叠区域
  void _analyzeYamlCode(List<String> lines) {
    int? startLine;
    int currentIndent = 0;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      // 计算缩进级别
      final indent = line.length - line.trimLeft().length;
      
      if (startLine == null) {
        if (line.endsWith(':')) {
          startLine = i;
          currentIndent = indent;
        }
        continue;
      }

      // 如果遇到更小的缩进，说明当前块结束
      if (indent <= currentIndent) {
        if (i > startLine + 1) {
          regions.add(FoldingRegion(
            startLine: startLine + 1,
            endLine: i - 1,
            placeholder: '// ...',
          ));
        }
        startLine = null;
      }
    }
  }

  /// 分析通用代码的可折叠区域
  void _analyzeGenericCode(List<String> lines) {
    int? startLine;
    int emptyLines = 0;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        emptyLines++;
        if (emptyLines >= 2 && startLine != null) {
          if (i - startLine > 3) {
            regions.add(FoldingRegion(
              startLine: startLine,
              endLine: i - 1,
              placeholder: '// ...',
            ));
          }
          startLine = null;
          emptyLines = 0;
        }
      } else {
        if (startLine == null) {
          startLine = i;
        }
        emptyLines = 0;
      }
    }
  }

  /// 切换折叠状态
  void toggleFold(int line) {
    for (final region in regions) {
      if (line >= region.startLine && line <= region.endLine) {
        region.isFolded = !region.isFolded;
        break;
      }
    }
  }

  /// 获取指定行的折叠状态
  bool isLineFolded(int line) {
    for (final region in regions) {
      if (region.isFolded && line > region.startLine && line <= region.endLine) {
        return true;
      }
    }
    return false;
  }

  /// 获取折叠后的行
  String getFoldedLine(int line) {
    for (final region in regions) {
      if (region.isFolded && line == region.startLine) {
        return region.placeholder;
      }
    }
    return '';
  }

  /// 展开所有折叠
  void expandAll() {
    for (final region in regions) {
      region.isFolded = false;
    }
  }

  /// 折叠所有可折叠区域
  void foldAll() {
    for (final region in regions) {
      region.isFolded = true;
    }
  }

  /// 分析JavaScript代码的可折叠区域
  void _analyzeJavaScriptFoldingRegions(String text) {
    final lines = text.split('\n');
    int braceCount = 0;
    int? startLine;
    String? blockType;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 检测类定义
      if (line.startsWith('class ')) {
        startLine = i;
        blockType = 'class';
        continue;
      }

      // 检测函数定义
      if (RegExp(r'(function\s+\w+\s*\([^)]*\)|const\s+\w+\s*=\s*\([^)]*\)\s*=>|const\s+\w+\s*=\s*function\s*\([^)]*\)|\w+\s*\([^)]*\)\s*{)').hasMatch(line)) {
        startLine = i;
        blockType = 'function';
        continue;
      }

      // 计算花括号
      braceCount += '{'.allMatches(line).length;
      braceCount -= '}'.allMatches(line).length;

      // 检测块结束
      if (braceCount == 0 && startLine != null) {
        if (i > startLine + 1) { // 至少包含一行
          String placeholder = '...';
          if (blockType == 'class') {
            placeholder = '// 类定义...';
          } else if (blockType == 'function') {
            placeholder = '// 函数体...';
          }
          
          regions.add(FoldingRegion(
            startLine: startLine + 1,
            endLine: i,
            placeholder: placeholder,
          ));
        }
        startLine = null;
        blockType = null;
      }
    }
  }

  /// 分析TypeScript代码的可折叠区域
  void _analyzeTypeScriptFoldingRegions(String text) {
    final lines = text.split('\n');
    int braceCount = 0;
    int? startLine;
    String? blockType;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 检测接口定义
      if (line.startsWith('interface ') || line.startsWith('type ')) {
        startLine = i;
        blockType = 'interface';
        continue;
      }

      // 检测类定义
      if (line.startsWith('class ') || line.startsWith('abstract class ')) {
        startLine = i;
        blockType = 'class';
        continue;
      }

      // 检测函数定义
      if (RegExp(r'(function\s+\w+\s*\([^)]*\)|const\s+\w+\s*=\s*\([^)]*\)\s*=>|const\s+\w+\s*=\s*function\s*\([^)]*\)|\w+\s*\([^)]*\)\s*{|\w+\s*\([^)]*\)\s*:\s*\w+)').hasMatch(line)) {
        startLine = i;
        blockType = 'function';
        continue;
      }

      // 计算花括号
      braceCount += '{'.allMatches(line).length;
      braceCount -= '}'.allMatches(line).length;

      // 检测块结束
      if (braceCount == 0 && startLine != null) {
        if (i > startLine + 1) { // 至少包含一行
          String placeholder = '...';
          if (blockType == 'class') {
            placeholder = '// 类定义...';
          } else if (blockType == 'function') {
            placeholder = '// 函数体...';
          } else if (blockType == 'interface') {
            placeholder = '// 接口定义...';
          }
          
          regions.add(FoldingRegion(
            startLine: startLine + 1,
            endLine: i,
            placeholder: placeholder,
          ));
        }
        startLine = null;
        blockType = null;
      }
    }
  }

  /// 分析Python代码的可折叠区域
  void _analyzePythonFoldingRegions(String text) {
    final lines = text.split('\n');
    int? startLine;
    int currentIndent = 0;
    String? blockType;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      // 计算缩进级别
      final indent = line.length - line.trimLeft().length;
      final trimmedLine = line.trim();
      
      // 检测类定义
      if (trimmedLine.startsWith('class ')) {
        startLine = i;
        currentIndent = indent;
        blockType = 'class';
        continue;
      }
      
      // 检测函数定义
      if (trimmedLine.startsWith('def ')) {
        startLine = i;
        currentIndent = indent;
        blockType = 'function';
        continue;
      }
      
      // 如果有开始行，并且当前行的缩进小于等于开始行的缩进，说明块结束
      if (startLine != null && indent <= currentIndent && i > startLine + 1) {
        String placeholder = '...';
        if (blockType == 'class') {
          placeholder = '# 类定义...';
        } else if (blockType == 'function') {
          placeholder = '# 函数体...';
        }
        
        regions.add(FoldingRegion(
          startLine: startLine + 1,
          endLine: i - 1,
          placeholder: placeholder,
        ));
        
        startLine = null;
        blockType = null;
      }
    }
    
    // 处理文件末尾的块
    if (startLine != null && lines.length > startLine + 1) {
      String placeholder = '...';
      if (blockType == 'class') {
        placeholder = '# 类定义...';
      } else if (blockType == 'function') {
        placeholder = '# 函数体...';
      }
      
      regions.add(FoldingRegion(
        startLine: startLine + 1,
        endLine: lines.length - 1,
        placeholder: placeholder,
      ));
    }
  }

  /// 分析HTML代码的可折叠区域
  void _analyzeHtmlFoldingRegions(String text) {
    final lines = text.split('\n');
    final List<int> openTagLines = [];
    final List<String> openTags = [];
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 查找开始标签
      final openMatches = RegExp(r'<(\w+)[^>]*>').allMatches(line);
      for (final match in openMatches) {
        final tagName = match.group(1);
        if (tagName != null && !['br', 'hr', 'img', 'input', 'link', 'meta'].contains(tagName.toLowerCase())) {
          openTags.add(tagName);
          openTagLines.add(i);
        }
      }
      
      // 查找结束标签
      final closeMatches = RegExp(r'</(\w+)>').allMatches(line);
      for (final match in closeMatches) {
        final tagName = match.group(1);
        if (tagName != null && openTags.isNotEmpty && openTags.last == tagName) {
          final startLine = openTagLines.last;
          openTags.removeLast();
          openTagLines.removeLast();
          
          if (i > startLine + 1) {
            regions.add(FoldingRegion(
              startLine: startLine + 1,
              endLine: i - 1,
              placeholder: '<!-- $tagName 内容 -->',
            ));
          }
        }
      }
    }
  }

  /// 分析CSS代码的可折叠区域
  void _analyzeCssFoldingRegions(String text) {
    final lines = text.split('\n');
    int? startLine;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.contains('{') && startLine == null) {
        startLine = i;
      } else if (line.contains('}') && startLine != null) {
        if (i > startLine + 1) {
          regions.add(FoldingRegion(
            startLine: startLine + 1,
            endLine: i - 1,
            placeholder: '/* 样式属性... */',
          ));
        }
        startLine = null;
      }
    }
  }

  /// 分析Markdown代码的可折叠区域
  void _analyzeMarkdownFoldingRegions(String text) {
    final lines = text.split('\n');
    int? startLine;
    int currentLevel = 0;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测标题
      final headerMatch = RegExp(r'^(#{1,6})\s').firstMatch(line);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        
        // 如果有开始行，并且当前标题级别小于等于开始标题级别，说明上一个区域结束
        if (startLine != null && level <= currentLevel) {
          if (i > startLine + 1) {
            regions.add(FoldingRegion(
              startLine: startLine + 1,
              endLine: i - 1,
              placeholder: '<!-- 内容... -->',
            ));
          }
          startLine = i;
          currentLevel = level;
        } else if (startLine == null) {
          startLine = i;
          currentLevel = level;
        }
      }
    }
    
    // 处理文件末尾的区域
    if (startLine != null && lines.length > startLine + 1) {
      regions.add(FoldingRegion(
        startLine: startLine + 1,
        endLine: lines.length - 1,
        placeholder: '<!-- 内容... -->',
      ));
    }
  }
}

/// 折叠指示器组件
class FoldingIndicator extends StatelessWidget {
  final FoldingRegion region;
  final VoidCallback onTap;
  
  const FoldingIndicator({
    Key? key,
    required this.region,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            region.isFolded ? Icons.add : Icons.remove,
            size: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// 折叠占位符组件
class FoldingPlaceholder extends StatelessWidget {
  final FoldingRegion region;
  final VoidCallback onTap;
  
  const FoldingPlaceholder({
    Key? key,
    required this.region,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.unfold_more,
                size: 12,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                region.placeholder,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 代码折叠状态
class FoldingState {
  /// 折叠的区域
  final Map<int, int> foldedRegions; // key: 开始行, value: 结束行
  
  /// 构造函数
  const FoldingState({
    this.foldedRegions = const {},
  });
  
  /// 创建副本
  FoldingState copyWith({
    Map<int, int>? foldedRegions,
  }) {
    return FoldingState(
      foldedRegions: foldedRegions ?? this.foldedRegions,
    );
  }
}

/// 代码折叠状态提供者
final foldingProvider = StateNotifierProvider<FoldingNotifier, FoldingState>((ref) {
  return FoldingNotifier();
});

/// 代码折叠状态管理器
class FoldingNotifier extends StateNotifier<FoldingState> {
  FoldingNotifier() : super(const FoldingState());
  
  /// 切换折叠状态
  void toggleFold(int startLine, int endLine) {
    final foldedRegions = Map<int, int>.from(state.foldedRegions);
    
    if (foldedRegions.containsKey(startLine)) {
      foldedRegions.remove(startLine);
    } else {
      foldedRegions[startLine] = endLine;
    }
    
    state = state.copyWith(foldedRegions: foldedRegions);
  }
  
  /// 展开所有
  void unfoldAll() {
    state = const FoldingState();
  }
  
  /// 折叠所有可折叠区域
  void foldAll(List<FoldingRegion> regions) {
    final foldedRegions = <int, int>{};
    for (final region in regions) {
      foldedRegions[region.startLine] = region.endLine;
    }
    state = state.copyWith(foldedRegions: foldedRegions);
  }
} 