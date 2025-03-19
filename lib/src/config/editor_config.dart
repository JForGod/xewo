import 'package:flutter/material.dart';

/// 编辑器配置类
class EditorConfig {
  /// 基础配置
  static const double defaultFontSize = 14.0;
  static const String defaultFontFamily = 'JetBrains Mono';
  static const double lineHeight = 1.5;
  static const double letterSpacing = 0.5;
  
  /// 性能相关配置
  static const int virtualScrollThreshold = 1000; // 超过此行数启用虚拟滚动
  static const int maxFileSize = 10 * 1024 * 1024; // 最大文件大小(10MB)
  static const Duration autoSaveInterval = Duration(minutes: 2);
  
  /// 编辑器功能开关
  static const bool enableMultiCursor = true;
  static const bool enableCodeFolding = true;
  static const bool enableAutoComplete = true;
  static const bool enableSyntaxHighlight = true;
  static const bool enableLineNumbers = true;
  static const bool enableMinimap = true;
  
  /// 主题配置
  static const Color cursorColor = Color(0xFF2196F3);
  static const Color selectionColor = Color(0x402196F3);
  static const Color currentLineColor = Color(0x0A000000);
  
  /// 缓存配置
  static const int maxHistorySize = 100; // 撤销重做最大步数
  static const Duration cacheTimeout = Duration(minutes: 30);
  
  /// 默认快捷键配置
  static const Map<String, String> defaultShortcuts = {
    'save': 'ctrl+s',
    'find': 'ctrl+f',
    'replace': 'ctrl+h',
    'undo': 'ctrl+z',
    'redo': 'ctrl+y',
    'format': 'ctrl+alt+l',
  };
  
  /// 获取支持的文件类型
  static List<String> get supportedFileTypes => [
    'dart', 'java', 'kotlin', 'swift', 'cpp', 'c', 'cs', 'py',
    'js', 'ts', 'jsx', 'tsx', 'html', 'css', 'scss', 'less',
    'json', 'yaml', 'xml', 'md', 'txt', 'log'
  ];
  
  /// 支持的文件格式映射到语言模式
  static Map<String, String> get supportedFormats => {
    'dart': 'dart',
    'java': 'java',
    'kotlin': 'kotlin',
    'swift': 'swift',
    'cpp': 'cpp',
    'c': 'c',
    'cs': 'csharp',
    'py': 'python',
    'js': 'javascript',
    'jsx': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'less': 'less',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'xml': 'xml',
    'md': 'markdown',
    'txt': 'plaintext',
    'log': 'plaintext',
  };
  
  /// 检查文件是否支持
  static bool isFileSupported(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return supportedFileTypes.contains(extension);
  }
  
  /// 获取文件类型对应的语言模式
  static String getLanguageMode(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return 'dart';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'html':
        return 'html';
      case 'css':
      case 'scss':
      case 'less':
        return 'css';
      case 'json':
        return 'json';
      case 'md':
        return 'markdown';
      default:
        return 'plaintext';
    }
  }

  /// 获取文件扩展名对应的语言模式
  static String getLanguageModeFromExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return supportedFormats[extension] ?? 'plaintext';
  }

  /// 检查文件是否支持
  static bool isSupported(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return supportedFormats.containsKey(extension);
  }

  /// 获取文件图标
  static IconData getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    
    // 根据文件类型返回对应图标
    switch (extension) {
      case 'dart':
        return Icons.flutter_dash;
      case 'java':
      case 'kt':
      case 'gradle':
        return Icons.android;
      case 'swift':
      case 'xcodeproj':
        return Icons.apple;
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        return Icons.javascript;
      case 'html':
        return Icons.html;
      case 'css':
      case 'scss':
      case 'less':
        return Icons.style;
      case 'json':
      case 'yaml':
      case 'xml':
        return Icons.data_object;
      case 'md':
        return Icons.description;
      case 'sql':
        return Icons.storage;
      case 'sh':
      case 'bash':
      case 'ps1':
        return Icons.terminal;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
} 