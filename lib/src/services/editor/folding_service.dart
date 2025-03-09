import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/providers/shared_preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 折叠区域
class FoldingRegion {
  final int startLine;
  final int endLine;
  final String kind;
  final String? placeholder;
  bool isCollapsed;
  String? originalText;
  
  FoldingRegion({
    required this.startLine,
    required this.endLine,
    required this.kind,
    this.placeholder,
    this.isCollapsed = false,
    this.originalText,
  });
  
  Map<String, dynamic> toJson() => {
    'startLine': startLine,
    'endLine': endLine,
    'kind': kind,
    'placeholder': placeholder,
    'isCollapsed': isCollapsed,
    'originalText': originalText,
  };
  
  factory FoldingRegion.fromJson(Map<String, dynamic> json) => FoldingRegion(
    startLine: json['startLine'] as int,
    endLine: json['endLine'] as int,
    kind: json['kind'] as String,
    placeholder: json['placeholder'] as String?,
    isCollapsed: json['isCollapsed'] as bool,
    originalText: json['originalText'] as String?,
  );
}

/// 折叠提供者接口
abstract class FoldingProvider {
  /// 获取折叠区域
  List<FoldingRegion> getFoldingRegions(String text);
  
  /// 是否可以处理此类型的文件
  bool canHandle(String? fileType);
}

/// Dart折叠提供者
class DartFoldingProvider implements FoldingProvider {
  @override
  bool canHandle(String? fileType) => fileType == 'dart';
  
  @override
  List<FoldingRegion> getFoldingRegions(String text) {
    final regions = <FoldingRegion>[];
    final lines = text.split('\n');
    
    // 跟踪大括号层级
    final braceStack = <int>[];
    
    // 跟踪注释块
    bool inCommentBlock = false;
    int commentBlockStart = -1;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 处理注释块
      if (line.startsWith('/*') && !line.endsWith('*/')) {
        inCommentBlock = true;
        commentBlockStart = i;
      } else if (line.endsWith('*/') && inCommentBlock) {
        inCommentBlock = false;
        if (i > commentBlockStart) {
          regions.add(FoldingRegion(
            startLine: commentBlockStart,
            endLine: i,
            kind: 'comment',
            placeholder: '/* ... */',
          ));
        }
      }
      
      // 处理大括号
      if (!inCommentBlock) {
        // 计算当前行的大括号数量
        final openCount = '{'.allMatches(line).length;
        final closeCount = '}'.allMatches(line).length;
        
        // 处理开括号
        for (int j = 0; j < openCount; j++) {
          braceStack.add(i);
        }
        
        // 处理闭括号
        for (int j = 0; j < closeCount; j++) {
          if (braceStack.isNotEmpty) {
            final start = braceStack.removeLast();
            if (i > start) {
              // 获取代码块的第一行用作占位符
              final firstLine = lines[start].trim();
              final placeholder = firstLine.length > 30
                  ? '${firstLine.substring(0, 27)}...'
                  : firstLine;
              
              regions.add(FoldingRegion(
                startLine: start,
                endLine: i,
                kind: 'brace',
                placeholder: '$placeholder ...',
              ));
            }
          }
        }
      }
    }
    
    return regions;
  }
}

/// 代码折叠服务
class FoldingService {
  final List<FoldingProvider> _providers;
  final SharedPreferences _prefs;
  final Map<String, List<FoldingRegion>> _foldingCache = {};
  
  FoldingService({
    List<FoldingProvider>? providers,
    required SharedPreferences prefs,
  }) : _providers = providers ?? [DartFoldingProvider()],
       _prefs = prefs;
  
  /// 添加折叠提供者
  void addProvider(FoldingProvider provider) {
    _providers.add(provider);
  }
  
  /// 获取折叠区域
  List<FoldingRegion> getFoldingRegions(String text, {String? fileType, String? filePath}) {
    if (filePath != null && _foldingCache.containsKey(filePath)) {
      return _foldingCache[filePath]!;
    }
    
    final regions = <FoldingRegion>[];
    
    for (final provider in _providers) {
      if (provider.canHandle(fileType)) {
        regions.addAll(provider.getFoldingRegions(text));
      }
    }
    
    // 按起始行排序
    regions.sort((a, b) => a.startLine.compareTo(b.startLine));
    
    // 恢复保存的折叠状态
    if (filePath != null) {
      _restoreFoldingState(regions, filePath);
      _foldingCache[filePath] = regions;
    }
    
    return regions;
  }
  
  /// 切换折叠状态
  void toggleFolding(FoldingRegion region, String text, String? filePath) {
    region.isCollapsed = !region.isCollapsed;
    
    if (region.isCollapsed) {
      // 保存原始文本以便展开时恢复
      final lines = text.split('\n');
      final regionText = lines.sublist(region.startLine, region.endLine + 1).join('\n');
      region.originalText = regionText;
    }
    
    if (filePath != null) {
      _saveFoldingState(filePath);
    }
  }
  
  /// 展开所有区域
  void expandAll(List<FoldingRegion> regions, String? filePath) {
    for (final region in regions) {
      region.isCollapsed = false;
    }
    
    if (filePath != null) {
      _saveFoldingState(filePath);
    }
  }
  
  /// 折叠所有区域
  void collapseAll(List<FoldingRegion> regions, String text, String? filePath) {
    final lines = text.split('\n');
    
    for (final region in regions) {
      if (!region.isCollapsed) {
        region.isCollapsed = true;
        final regionText = lines.sublist(region.startLine, region.endLine + 1).join('\n');
        region.originalText = regionText;
      }
    }
    
    if (filePath != null) {
      _saveFoldingState(filePath);
    }
  }
  
  /// 获取展开后的文本
  String getExpandedText(FoldingRegion region) {
    return region.originalText ?? '';
  }
  
  /// 保存折叠状态
  void _saveFoldingState(String filePath) {
    if (!_foldingCache.containsKey(filePath)) return;
    
    final regions = _foldingCache[filePath]!;
    final jsonList = regions.map((r) => r.toJson()).toList();
    _prefs.setString('folding_$filePath', jsonEncode(jsonList));
  }
  
  /// 恢复折叠状态
  void _restoreFoldingState(List<FoldingRegion> regions, String filePath) {
    final jsonStr = _prefs.getString('folding_$filePath');
    if (jsonStr == null) return;
    
    try {
      final jsonList = jsonDecode(jsonStr) as List;
      final savedRegions = jsonList.map((j) => FoldingRegion.fromJson(j as Map<String, dynamic>)).toList();
      
      // 将保存的状态应用到新的折叠区域
      for (final region in regions) {
        final savedRegion = savedRegions.firstWhere(
          (r) => r.startLine == region.startLine && r.endLine == region.endLine,
          orElse: () => region,
        );
        region.isCollapsed = savedRegion.isCollapsed;
        region.originalText = savedRegion.originalText;
      }
    } catch (e) {
      print('Error restoring folding state: $e');
    }
  }
  
  /// 清除文件的折叠缓存
  void clearCache(String filePath) {
    _foldingCache.remove(filePath);
    _prefs.remove('folding_$filePath');
  }
}

/// 折叠服务提供者
final foldingServiceProvider = Provider<FoldingService>((ref) {
  throw UnimplementedError('foldingServiceProvider 未初始化');
}); 