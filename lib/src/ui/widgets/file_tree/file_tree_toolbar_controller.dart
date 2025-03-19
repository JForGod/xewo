import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/file/file_tree_service.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../../state/providers/global_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

enum SortBy {
  name,
  modified,
  type,
  size,
}

enum FileTreeView {
  fileBrowser,
  search,
  sourceControl,
  runDebug,
  extensions,
}

final fileTreeViewProvider = StateProvider<FileTreeView>((ref) {
  return FileTreeView.fileBrowser;
});

class FileTreeToolbarState {
  final FileTreeView activeView;
  final bool isVisible;
  final bool showHiddenFiles;
  final bool showFileIcons;
  final bool compactView;
  final SortBy sortBy;
  final bool showFilter;
  final String? currentPath;
  final String? error;
  final bool showSettings;

  const FileTreeToolbarState({
    this.activeView = FileTreeView.fileBrowser,
    this.isVisible = true,
    this.showHiddenFiles = true,
    this.showFileIcons = true,
    this.compactView = false,
    this.sortBy = SortBy.name,
    this.showFilter = false,
    this.currentPath,
    this.error,
    this.showSettings = false,
  });

  FileTreeToolbarState copyWith({
    FileTreeView? activeView,
    bool? isVisible,
    bool? showHiddenFiles,
    bool? showFileIcons,
    bool? compactView,
    SortBy? sortBy,
    bool? showFilter,
    String? currentPath,
    String? error,
    bool? showSettings,
  }) {
    return FileTreeToolbarState(
      activeView: activeView ?? this.activeView,
      isVisible: isVisible ?? this.isVisible,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      showFileIcons: showFileIcons ?? this.showFileIcons,
      compactView: compactView ?? this.compactView,
      sortBy: sortBy ?? this.sortBy,
      showFilter: showFilter ?? this.showFilter,
      currentPath: currentPath ?? this.currentPath,
      error: error,
      showSettings: showSettings ?? this.showSettings,
    );
  }
}

final fileTreeToolbarProvider = StateNotifierProvider<FileTreeToolbarController, FileTreeToolbarState>((ref) {
  final fileTreeService = ref.watch(fileTreeServiceProvider);
  return FileTreeToolbarController(ref, fileTreeService);
});

class FileTreeToolbarController extends StateNotifier<FileTreeToolbarState> {
  FileTreeToolbarController(this._ref, this._fileTreeService) : super(const FileTreeToolbarState()) {
    // 注册键盘快捷键处理器
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  final Ref _ref;
  final FileTreeService _fileTreeService;

  void setActiveView(FileTreeView view) {
    state = state.copyWith(activeView: view);
  }

  void refresh() {
    _ref.read(fileTreeProvider.notifier).refresh();
  }

  void createNewFolder() async {
    try {
      final currentPath = state.currentPath;
      if (currentPath == null) {
        state = state.copyWith(error: '未选择目录');
        return;
      }
      await _ref.read(fileTreeProvider.notifier).createDirectory(currentPath, 'New Folder');
      refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void createNewFile() async {
    try {
      final currentPath = state.currentPath;
      if (currentPath == null) {
        state = state.copyWith(error: '未选择目录');
        return;
      }
      await _ref.read(fileTreeProvider.notifier).createFile(currentPath, 'New File');
      refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void toggleFilter() {
    state = state.copyWith(showFilter: !state.showFilter);
  }

  void collapseAll() {
    _ref.read(fileTreeProvider.notifier).collapseAll();
  }

  void openSettings() {
    state = state.copyWith(showSettings: !state.showSettings);
  }

  void setSortBy(SortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleHiddenFiles() {
    state = state.copyWith(showHiddenFiles: !state.showHiddenFiles);
  }

  void toggleFileIcons() {
    state = state.copyWith(showFileIcons: !state.showFileIcons);
  }

  void toggleCompactView() {
    state = state.copyWith(compactView: !state.compactView);
  }

  /// 打开新项目
  Future<void> openProject() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        state = state.copyWith(currentPath: result);
        _ref.read(fileTreeProvider.notifier).loadDirectory(result);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 在新窗口打开
  Future<void> openInNewWindow() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        // 这里实际上应该启动一个新的应用实例
        // 由于Flutter桌面应用限制，我们暂时只是加载新目录
        state = state.copyWith(currentPath: result);
        _ref.read(fileTreeProvider.notifier).loadDirectory(result);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 处理键盘快捷键
  bool _handleKeyPress(KeyEvent event) {
    // 只处理按键按下事件
    if (event is! KeyDownEvent) {
      return false;
    }

    final bool isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Ctrl+Shift+F: 搜索视图
    if (event.logicalKey == LogicalKeyboardKey.keyF && 
        isControlPressed && 
        isShiftPressed) {
      switchView(FileTreeView.search);
      return true;
    }

    // Ctrl+Shift+G: 源代码控制视图
    if (event.logicalKey == LogicalKeyboardKey.keyG && 
        isControlPressed && 
        isShiftPressed) {
      switchView(FileTreeView.sourceControl);
      return true;
    }

    // Ctrl+Shift+D: 运行和调试视图
    if (event.logicalKey == LogicalKeyboardKey.keyD && 
        isControlPressed && 
        isShiftPressed) {
      switchView(FileTreeView.runDebug);
      return true;
    }

    // Ctrl+Shift+X: 扩展视图
    if (event.logicalKey == LogicalKeyboardKey.keyX && 
        isControlPressed && 
        isShiftPressed) {
      switchView(FileTreeView.extensions);
      return true;
    }

    return false;
  }

  void switchView(FileTreeView view) {
    _ref.read(fileTreeViewProvider.notifier).state = view;
  }

  void toggleFileBrowser() {
    final currentView = _ref.read(fileTreeViewProvider);
    if (currentView == FileTreeView.fileBrowser) {
      // 如果当前已经是文件浏览器，则不做任何操作
      return;
    }
    switchView(FileTreeView.fileBrowser);
  }

  void toggleSearch() {
    final currentView = _ref.read(fileTreeViewProvider);
    if (currentView == FileTreeView.search) {
      switchView(FileTreeView.fileBrowser);
    } else {
      switchView(FileTreeView.search);
    }
  }

  void toggleSourceControl() {
    final currentView = _ref.read(fileTreeViewProvider);
    if (currentView == FileTreeView.sourceControl) {
      switchView(FileTreeView.fileBrowser);
    } else {
      switchView(FileTreeView.sourceControl);
    }
  }

  void toggleRunDebug() {
    final currentView = _ref.read(fileTreeViewProvider);
    if (currentView == FileTreeView.runDebug) {
      switchView(FileTreeView.fileBrowser);
    } else {
      switchView(FileTreeView.runDebug);
    }
  }

  void toggleExtensions() {
    final currentView = _ref.read(fileTreeViewProvider);
    if (currentView == FileTreeView.extensions) {
      switchView(FileTreeView.fileBrowser);
    } else {
      switchView(FileTreeView.extensions);
    }
  }

  void dispose() {
    // 移除键盘快捷键处理器
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
  }
}
