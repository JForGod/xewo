import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/file/file_service.dart';
import '../../services/file/file_tree_service.dart';

/// 编辑器状态
class EditorState {
  final List<String> openFiles;
  final int activeFileIndex;
  final bool showFileTree;
  final bool showLineNumbers;
  final bool showMinimap;
  final double fileTreeWidth;
  final String? currentDirectoryPath;
  final String? currentFilePath;
  final List<String> recentProjects;
  final String text;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool isModified;

  const EditorState({
    this.openFiles = const [],
    this.activeFileIndex = -1,
    this.showFileTree = true,
    this.showLineNumbers = true,
    this.showMinimap = true,
    this.fileTreeWidth = 200,
    this.currentDirectoryPath,
    this.currentFilePath,
    this.recentProjects = const [],
    this.text = '',
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.isModified = false,
  });

  EditorState copyWith({
    List<String>? openFiles,
    int? activeFileIndex,
    bool? showFileTree,
    bool? showLineNumbers,
    bool? showMinimap,
    double? fileTreeWidth,
    String? currentDirectoryPath,
    String? currentFilePath,
    List<String>? recentProjects,
    String? text,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? isModified,
  }) {
    return EditorState(
      openFiles: openFiles ?? this.openFiles,
      activeFileIndex: activeFileIndex ?? this.activeFileIndex,
      showFileTree: showFileTree ?? this.showFileTree,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      showMinimap: showMinimap ?? this.showMinimap,
      fileTreeWidth: fileTreeWidth ?? this.fileTreeWidth,
      currentDirectoryPath: currentDirectoryPath ?? this.currentDirectoryPath,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      recentProjects: recentProjects ?? this.recentProjects,
      text: text ?? this.text,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isModified: isModified ?? this.isModified,
    );
  }
}

/// 编辑器状态提供者
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

/// 编辑器状态通知器
class EditorNotifier extends StateNotifier<EditorState> {
  final FileService _fileService;
  static const String _prefKey = 'editor_state';
  
  EditorNotifier([FileService? fileService]) 
    : _fileService = fileService ?? FileService(),
      super(const EditorState()) {
    // 初始化时尝试从持久化存储恢复状态
    _restoreState();
  }
  
  // 从持久化存储恢复状态
  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_prefKey);
      
      if (stateJson != null && stateJson.isNotEmpty) {
        final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
        
        // 恢复打开的文件列表
        final openFiles = (stateMap['openFiles'] as List<dynamic>?)?.cast<String>() ?? [];
        final activeFileIndex = stateMap['activeFileIndex'] as int? ?? -1;
        final showFileTree = stateMap['showFileTree'] as bool? ?? true;
        final fileTreeWidth = (stateMap['fileTreeWidth'] as num?)?.toDouble() ?? 200.0;
        final showLineNumbers = stateMap['showLineNumbers'] as bool? ?? true;
        final showMinimap = stateMap['showMinimap'] as bool? ?? true;
        final currentDirectoryPath = stateMap['currentDirectoryPath'] as String?;
        final currentFilePath = stateMap['currentFilePath'] as String?;
        final recentProjects = (stateMap['recentProjects'] as List<dynamic>?)?.cast<String>() ?? [];
        
        // 更新状态
        state = state.copyWith(
          openFiles: openFiles,
          activeFileIndex: activeFileIndex,
          showFileTree: showFileTree,
          fileTreeWidth: fileTreeWidth,
          showLineNumbers: showLineNumbers,
          showMinimap: showMinimap,
          currentDirectoryPath: currentDirectoryPath,
          currentFilePath: currentFilePath,
          recentProjects: recentProjects,
        );
        
        if (kDebugMode) {
          print('编辑器状态已恢复: ${openFiles.length} 个文件, 活动文件索引: $activeFileIndex, 当前目录: $currentDirectoryPath');
        }
        
        // 如果有当前目录，尝试加载文件树
        if (currentDirectoryPath != null && currentDirectoryPath.isNotEmpty) {
          try {
            final fileTreeService = FileTreeService();
            await fileTreeService.loadDirectory(currentDirectoryPath);
          } catch (e) {
            if (kDebugMode) {
              print('恢复文件树失败: $e');
            }
          }
        }
        
        // 如果有活动文件，尝试加载它
        if (activeFileIndex >= 0 && activeFileIndex < openFiles.length) {
          loadFile(openFiles[activeFileIndex]);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('恢复编辑器状态失败: $e');
      }
    }
  }
  
  /// 加载文件
  Future<void> loadFile(String path) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );
    
    try {
      final content = await _fileService.readFile(path);
      
      // 更新打开的文件列表
      final openFiles = List<String>.from(state.openFiles);
      if (!openFiles.contains(path)) {
        openFiles.add(path);
      }
      final activeFileIndex = openFiles.indexOf(path);
      
      // 更新最近文件列表
      final recentFiles = List<String>.from(state.recentProjects);
      if (recentFiles.contains(path)) {
        recentFiles.remove(path);
      }
      recentFiles.insert(0, path);
      if (recentFiles.length > 10) {
        recentFiles.removeLast();
      }
      
      state = state.copyWith(
        currentFilePath: path,
        text: content,
        isLoading: false,
        isModified: false,
        openFiles: openFiles,
        activeFileIndex: activeFileIndex,
        recentProjects: recentFiles,
      );
      
      // 保存状态到持久化存储
      _persistState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 保存文件
  Future<void> saveFile(String path, String content) async {
    state = state.copyWith(
      isSaving: true,
      error: null,
    );
    
    try {
      await _fileService.writeFile(path, content);
      
      state = state.copyWith(
        currentFilePath: path,
        text: content,
        isSaving: false,
        isModified: false,
      );
      
      // 保存状态到持久化存储
      _persistState();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
    }
  }
  
  /// 更新文本内容
  void updateText(String text) {
    state = state.copyWith(text: text);
  }
  
  /// 切换行号显示
  void toggleLineNumbers() {
    state = state.copyWith(
      showLineNumbers: !state.showLineNumbers,
    );
    
    // 保存状态到持久化存储
    _persistState();
  }
  
  /// 切换小地图显示
  void toggleMinimap() {
    state = state.copyWith(
      showMinimap: !state.showMinimap,
    );
    
    // 保存状态到持久化存储
    _persistState();
  }
  
  /// 切换文件树显示
  void toggleFileTree() {
    state = state.copyWith(
      showFileTree: !state.showFileTree,
    );
    
    // 保存状态到持久化存储
    _persistState();
  }
  
  /// 更新文件树宽度
  void updateFileTreeWidth(double width) {
    state = state.copyWith(
      fileTreeWidth: width,
    );
    
    // 保存状态到持久化存储
    _persistState();
  }
  
  /// 关闭文件
  void closeFile(String path) {
    final openFiles = List<String>.from(state.openFiles);
    final index = openFiles.indexOf(path);
    if (index != -1) {
      openFiles.removeAt(index);
      
      // 更新活动文件索引
      int activeFileIndex = state.activeFileIndex;
      if (openFiles.isEmpty) {
        activeFileIndex = -1;
      } else if (index == activeFileIndex) {
        activeFileIndex = index < openFiles.length ? index : openFiles.length - 1;
      } else if (index < activeFileIndex) {
        activeFileIndex--;
      }
      
      state = state.copyWith(
        openFiles: openFiles,
        activeFileIndex: activeFileIndex,
        currentFilePath: activeFileIndex >= 0 ? openFiles[activeFileIndex] : null,
      );
      
      // 保存状态到持久化存储
      _persistState();
    }
  }
  
  /// 切换到文件
  void switchToFile(String path) {
    final openFiles = List<String>.from(state.openFiles);
    final index = openFiles.indexOf(path);
    if (index != -1) {
      state = state.copyWith(
        activeFileIndex: index,
        currentFilePath: path,
      );
      
      // 保存状态到持久化存储
      _persistState();
    }
  }
  
  /// 更新编辑器状态
  void updateState({
    List<String>? openFiles,
    int? activeFileIndex,
    bool? showFileTree,
    bool? showLineNumbers,
    bool? showMinimap,
    double? fileTreeWidth,
    String? currentDirectoryPath,
    String? currentFilePath,
    List<String>? recentProjects,
    String? text,
    bool? isModified,
    String? error,
  }) {
    state = state.copyWith(
      openFiles: openFiles,
      activeFileIndex: activeFileIndex,
      showFileTree: showFileTree,
      showLineNumbers: showLineNumbers,
      showMinimap: showMinimap,
      fileTreeWidth: fileTreeWidth,
      currentDirectoryPath: currentDirectoryPath,
      currentFilePath: currentFilePath,
      recentProjects: recentProjects,
      text: text,
      isModified: isModified,
      error: error,
    );
    
    // 保存状态到持久化存储
    _persistState();
  }
  
  void addRecentProject(String path) {
    final recentProjects = List<String>.from(state.recentProjects);
    // 移除已存在的路径（如果有）
    recentProjects.remove(path);
    // 添加到列表开头
    recentProjects.insert(0, path);
    // 保持最近项目列表不超过10个
    if (recentProjects.length > 10) {
      recentProjects.removeLast();
    }
    state = state.copyWith(recentProjects: recentProjects);
  }
  
  // 将状态保存到持久化存储
  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 创建要保存的状态映射
      final stateMap = {
        'openFiles': state.openFiles,
        'activeFileIndex': state.activeFileIndex,
        'showFileTree': state.showFileTree,
        'fileTreeWidth': state.fileTreeWidth,
        'showLineNumbers': state.showLineNumbers,
        'showMinimap': state.showMinimap,
        'currentDirectoryPath': state.currentDirectoryPath,
        'currentFilePath': state.currentFilePath,
        'recentProjects': state.recentProjects,
      };
      
      // 转换为JSON并保存
      final stateJson = jsonEncode(stateMap);
      await prefs.setString(_prefKey, stateJson);
      
      if (kDebugMode) {
        print('编辑器状态已保存: ${state.openFiles.length} 个文件, 活动文件索引: ${state.activeFileIndex}, 当前目录: ${state.currentDirectoryPath}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('保存编辑器状态失败: $e');
      }
    }
  }
} 