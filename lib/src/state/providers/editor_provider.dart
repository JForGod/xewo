import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

// 编辑器状态类
class EditorState {
  final String currentFilePath;
  final String currentFileContent;
  final bool isModified;
  final String language;
  final Map<String, String> openFiles; // 路径 -> 内容
  final List<String> recentFiles;

  EditorState({
    this.currentFilePath = '',
    this.currentFileContent = '',
    this.isModified = false,
    this.language = 'plaintext',
    Map<String, String>? openFiles,
    List<String>? recentFiles,
  }) : 
    openFiles = openFiles ?? {},
    recentFiles = recentFiles ?? [];

  EditorState copyWith({
    String? currentFilePath,
    String? currentFileContent,
    bool? isModified,
    String? language,
    Map<String, String>? openFiles,
    List<String>? recentFiles,
  }) {
    return EditorState(
      currentFilePath: currentFilePath ?? this.currentFilePath,
      currentFileContent: currentFileContent ?? this.currentFileContent,
      isModified: isModified ?? this.isModified,
      language: language ?? this.language,
      openFiles: openFiles ?? this.openFiles,
      recentFiles: recentFiles ?? this.recentFiles,
    );
  }
}

// 编辑器状态管理类
class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState());

  // 更新当前文件
  void updateCurrentFile(String filePath, String content) {
    final language = _getLanguageFromPath(filePath);
    
    // 更新打开的文件列表
    final openFiles = Map<String, String>.from(state.openFiles);
    openFiles[filePath] = content;
    
    // 更新最近文件列表
    final recentFiles = List<String>.from(state.recentFiles);
    recentFiles.remove(filePath);
    recentFiles.insert(0, filePath);
    if (recentFiles.length > 10) {
      recentFiles.removeLast();
    }
    
    state = state.copyWith(
      currentFilePath: filePath,
      currentFileContent: content,
      isModified: false,
      language: language,
      openFiles: openFiles,
      recentFiles: recentFiles,
    );
  }

  // 更新当前文件内容
  void updateCurrentFileContent(String content) {
    if (state.currentFilePath.isEmpty) return;
    
    final openFiles = Map<String, String>.from(state.openFiles);
    openFiles[state.currentFilePath] = content;
    
    state = state.copyWith(
      currentFileContent: content,
      isModified: content != state.openFiles[state.currentFilePath],
      openFiles: openFiles,
    );
  }

  // 关闭文件
  void closeFile(String filePath) {
    if (!state.openFiles.containsKey(filePath)) return;
    
    final openFiles = Map<String, String>.from(state.openFiles);
    openFiles.remove(filePath);
    
    // 如果关闭的是当前文件，则切换到其他文件
    if (filePath == state.currentFilePath) {
      final nextFilePath = openFiles.keys.isNotEmpty ? openFiles.keys.first : '';
      final nextContent = nextFilePath.isNotEmpty ? openFiles[nextFilePath]! : '';
      final nextLanguage = nextFilePath.isNotEmpty ? _getLanguageFromPath(nextFilePath) : 'plaintext';
      
      state = state.copyWith(
        currentFilePath: nextFilePath,
        currentFileContent: nextContent,
        isModified: false,
        language: nextLanguage,
        openFiles: openFiles,
      );
    } else {
      state = state.copyWith(openFiles: openFiles);
    }
  }

  // 切换到已打开的文件
  void switchToFile(String filePath) {
    if (!state.openFiles.containsKey(filePath)) return;
    
    final content = state.openFiles[filePath]!;
    final language = _getLanguageFromPath(filePath);
    
    // 更新最近文件列表
    final recentFiles = List<String>.from(state.recentFiles);
    recentFiles.remove(filePath);
    recentFiles.insert(0, filePath);
    
    state = state.copyWith(
      currentFilePath: filePath,
      currentFileContent: content,
      isModified: false,
      language: language,
      recentFiles: recentFiles,
    );
  }

  // 保存当前文件
  void saveCurrentFile() {
    if (state.currentFilePath.isEmpty) return;
    
    final openFiles = Map<String, String>.from(state.openFiles);
    openFiles[state.currentFilePath] = state.currentFileContent;
    
    state = state.copyWith(
      isModified: false,
      openFiles: openFiles,
    );
  }

  // 根据文件路径获取语言
  String _getLanguageFromPath(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.dart':
        return 'dart';
      case '.js':
        return 'javascript';
      case '.ts':
        return 'typescript';
      case '.html':
        return 'html';
      case '.css':
        return 'css';
      case '.json':
        return 'json';
      case '.md':
        return 'markdown';
      case '.py':
        return 'python';
      case '.java':
        return 'java';
      case '.c':
        return 'c';
      case '.cpp':
        return 'cpp';
      case '.cs':
        return 'csharp';
      case '.go':
        return 'go';
      case '.rs':
        return 'rust';
      case '.rb':
        return 'ruby';
      case '.php':
        return 'php';
      case '.swift':
        return 'swift';
      case '.kt':
        return 'kotlin';
      default:
        return 'plaintext';
    }
  }
}

// 编辑器状态提供者
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
}); 