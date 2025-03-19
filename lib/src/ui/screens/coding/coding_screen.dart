import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../services/file/file_service.dart';
import '../../../services/file/file_tree_service.dart';
import '../../../services/formatter/formatter_manager.dart';
import '../../../state/providers/editor_provider.dart';
import '../../../state/providers/file_tree_provider.dart';
import '../../themes/app_theme.dart';
import '../../../features/ai_assistant/ai_assistant_export.dart';
import '../../widgets/common/find_replace_dialog.dart';
import '../../widgets/editor/code_editor.dart';
import '../../widgets/editor/editor_tabs.dart';
import '../../widgets/editor/editor_toolbar.dart';
import '../../widgets/file_tree/file_tree.dart';
import '../../widgets/common/new_window_dialog.dart';
import '../../../services/settings/settings_service.dart';
import '../../../services/global_assistant_service/global_assistant_service.dart';
import '../../widgets/ai_assistant/ai_assistant_floating_button.dart';

/// 智能编程功能集成页面
class CodingScreen extends ConsumerStatefulWidget {
  const CodingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends ConsumerState<CodingScreen> {
  final _showFileTree = ValueNotifier<bool>(true);
  double _fileTreeWidth = 200;
  final double _minFileTreeWidth = 160;
  final double _maxFileTreeWidth = 280;
  final FocusNode _editorFocusNode = FocusNode();
  final List<String> _openFiles = [];
  int _activeFileIndex = -1;
  bool _showAiAssistant = false;
  bool _showToolbar = true;
  bool _showLineNumbers = true;
  bool _showMinimap = true;
  String _text = '';
  String _filePath = '';
  double _aiAssistantWidth = 240;
  final double _minAiAssistantWidth = 200;
  final double _maxAiAssistantWidth = 320;

  // 处理键盘快捷键
  bool _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final bool isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Ctrl+O: 打开项目
    if (event.logicalKey == LogicalKeyboardKey.keyO && 
        isControlPressed && 
        !isShiftPressed) {
      _openProject();
      return true;
    }

    // Ctrl+Shift+O: 在新窗口打开
    if (event.logicalKey == LogicalKeyboardKey.keyO && 
        isControlPressed && 
        isShiftPressed) {
      _openInNewWindow();
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    
    // 注册键盘快捷键监听器
    HardwareKeyboard.instance.addHandler(_handleKeyPress);
    
    // 从命令行参数中获取项目路径和导航标志
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processCommandLineArgs();
    });
  }
  
  // 处理命令行参数
  void _processCommandLineArgs() async {
    try {
      // 获取命令行参数
      final args = Platform.executableArguments;
      String? projectPath;
      bool shouldNavigateToCoding = false;
      
      // 解析参数
      for (int i = 0; i < args.length; i++) {
        if (args[i] == '--project-path' && i + 1 < args.length) {
          projectPath = args[i + 1];
        } else if (args[i] == '--coding-screen') {
          shouldNavigateToCoding = true;
        }
      }
      
      // 如果指定了项目路径，加载该项目
      if (projectPath != null) {
        if (kDebugMode) {
          print('从命令行加载项目: $projectPath');
        }
        
        // 创建文件树服务实例
        final fileTreeService = FileTreeService();
        
        // 加载目录到文件树
        await fileTreeService.loadDirectory(projectPath);
        
        // 更新编辑器状态提供者中的当前目录路径
        ref.read(editorProvider.notifier).updateState(
          currentDirectoryPath: projectPath,
        );
        
        // 更新文件树提供者
        ref.read(fileTreeProvider.notifier).loadDirectory(projectPath);
        
        // 更新UI状态
        setState(() {
          // 只在首次加载时清空文件列表，避免在返回该页面时清空已保存的状态
          // 通过检查编辑器状态来决定是否需要清空
          final editorState = ref.read(editorProvider);
          if (editorState.openFiles.isEmpty || editorState.currentDirectoryPath != projectPath) {
            // 只有当前没有打开文件，或者当前项目与要打开的项目不同时才清空
            _openFiles.clear();
            _activeFileIndex = -1;
            _text = '';
            _filePath = '';
          }
          // 显示文件树
          _showFileTree.value = true;
        });
      }
      
      // 如果需要导航到智能编程页面
      if (shouldNavigateToCoding) {
        // 延迟执行以确保状态已更新
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            // 导航到智能编程页面
            Navigator.pushReplacementNamed(context, '/coding');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('处理命令行参数失败: $e');
      }
    }
  }

  @override
  void dispose() {
    // 移除键盘快捷键监听器
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    
    // 保存编辑器状态
    if (_openFiles.isNotEmpty) {
      // 仅在确实有打开文件时保存状态
      ref.read(editorProvider.notifier).updateState(
        openFiles: _openFiles,
        activeFileIndex: _activeFileIndex,
        showFileTree: _showFileTree.value,
      );
    }
    
    // 释放资源
    _editorFocusNode.dispose();
    _showFileTree.dispose();
    
    super.dispose();
  }

  void _formatCode() {
    // TODO: 实现代码格式化功能
  }

  void _showFindDialog() {
    // TODO: 实现查找功能
  }

  void _showReplaceDialog() {
    // TODO: 实现替换功能
  }
  
  void _saveFile() async {
    if (_filePath.isEmpty) {
      // 如果没有文件路径，则执行另存为操作
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存文件',
        fileName: 'untitled.txt',
      );
      
      if (result != null) {
        _filePath = result;
      } else {
        return; // 用户取消了保存操作
      }
    }
    
    try {
      final file = File(_filePath);
      await file.writeAsString(_text);
      
      // 更新编辑器状态
      ref.read(editorProvider.notifier).updateText(_text);
      
      // 显示保存成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件保存成功')),
        );
      }
    } catch (e) {
      // 显示保存失败提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  void _loadFile(String filePath) async {
    try {
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        _handleError('文件不存在: $filePath');
        return;
      }
      
      // 检查文件大小
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB
        _handleError('文件过大，无法打开 (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB): $filePath');
        return;
      }
      
      // 尝试读取文件内容
      final content = await file.readAsString();
      
      if (mounted) {
        setState(() {
          _text = content;
          _filePath = filePath;
          
          // 更新打开的文件列表
          if (!_openFiles.contains(filePath)) {
            _openFiles.add(filePath);
            _activeFileIndex = _openFiles.length - 1;
          } else {
            _activeFileIndex = _openFiles.indexOf(filePath);
          }
        });
        
        // 更新编辑器状态
        ref.read(editorProvider.notifier).updateState(
          text: content,
          currentFilePath: filePath,
          openFiles: _openFiles,
          activeFileIndex: _activeFileIndex,
        );
        
        // 记录操作日志
        try {
          final globalAssistantService = GlobalAssistantService();
          globalAssistantService.logEditorAction(
            WindowContextAction.openFile,
            {
              'filePath': filePath,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } catch (e) {
          // 忽略记录操作失败的错误
          if (kDebugMode) {
            print('记录文件打开操作失败: $e');
          }
        }
      }
    } catch (e) {
      _handleError('加载文件失败: $e');
    }
  }

  void _updateText(String text) {
    if (!mounted) return;
    
    // 首先更新provider
    ref.read(editorProvider.notifier).updateState(
      text: text,
      currentFilePath: _filePath,
    );
    
    // 然后安全地更新本地状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _text = text;
        });
      }
    });
  }

  // 打开项目方法
  Future<void> _openProject() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        // 处理打开项目的逻辑
        if (kDebugMode) {
          print('打开项目: $result');
        }
        
        // 记录操作到全局上下文
        final globalAssistantService = GlobalAssistantService();
        final currentWindowId = globalAssistantService.getActiveWindowContext()?.windowId ?? const Uuid().v4();
        
        globalAssistantService.logEditorAction(
          WindowContextAction.openProject,
          {
            'action': 'open_project',
            'source': 'coding_screen',
            'windowId': currentWindowId,
            'projectPath': result,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        // 加载文件树
        try {
          // 创建文件树服务实例
          final fileTreeService = FileTreeService();
          
          // 加载目录到文件树
          await fileTreeService.loadDirectory(result);
          
          // 更新编辑器状态提供者中的当前目录路径
          ref.read(editorProvider.notifier).updateState(
            currentDirectoryPath: result,
          );
          
          // 更新文件树提供者
          ref.read(fileTreeProvider.notifier).loadDirectory(result);
          
          // 更新UI状态
          setState(() {
            // 只在首次加载时清空文件列表，避免在返回该页面时清空已保存的状态
            // 通过检查编辑器状态来决定是否需要清空
            final editorState = ref.read(editorProvider);
            if (editorState.openFiles.isEmpty || editorState.currentDirectoryPath != result) {
              // 只有当前没有打开文件，或者当前项目与要打开的项目不同时才清空
              _openFiles.clear();
              _activeFileIndex = -1;
              _text = '';
              _filePath = '';
            }
            // 显示文件树
            _showFileTree.value = true;
          });
          
          // 显示成功提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('项目已加载: ${path.basename(result)}')),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('加载文件树失败: $e');
          }
          // 显示错误提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('加载项目失败: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('打开项目失败: $e');
      }
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开项目失败: $e')),
        );
      }
    }
  }

  // 在新窗口打开方法
  Future<void> _openInNewWindow() async {
    try {
      // 显示新建窗口对话框
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const NewWindowDialog(),
      );

      if (result == null) return;

      String? projectPath;
      bool isDirectory = true;

      switch (result['action']) {
        case 'welcome':
          // 打开欢迎页
          _launchNewWindow('', isDirectory: false);
          return;
        case 'open_project':
          // 选择新目录
          final selectedPath = await FilePicker.platform.getDirectoryPath();
          if (selectedPath == null) return;
          projectPath = selectedPath;
          break;
        case 'open_recent':
          // 打开最近的项目
          projectPath = result['path'];
          break;
      }

      if (projectPath == null) return;

      // 创建全局助手服务实例
      final globalAssistantService = GlobalAssistantService();
      
      // 获取或创建当前窗口上下文
      final currentWindowId = globalAssistantService.getActiveWindowContext()?.windowId ?? const Uuid().v4();
      if (globalAssistantService.getWindowContext(currentWindowId) == null) {
        globalAssistantService.createWindowContext(
          windowId: currentWindowId,
          title: '当前窗口',
          type: 'editor',
          state: {
            'filePath': '',
            'isDirectory': false,
          },
        );
      }
      
      // 记录操作到全局上下文
      globalAssistantService.logEditorAction(
        WindowContextAction.openNewWindow,
        {
          'action': 'open_in_new_window',
          'source': 'coding_screen',
          'windowId': currentWindowId,
          'filePath': projectPath,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      // 创建新窗口上下文
      final newWindowId = const Uuid().v4();
      globalAssistantService.createWindowContext(
        windowId: newWindowId,
        title: path.basename(projectPath),
        type: 'editor',
        state: {
          'filePath': projectPath,
          'sourceWindowId': currentWindowId,
          'isDirectory': isDirectory,
        },
      );
      
      // 添加窗口关联
      try {
        globalAssistantService.addWindowRelation(currentWindowId, newWindowId);
      } catch (e) {
        if (kDebugMode) {
          print('添加窗口关联失败: $e');
        }
      }
      
      // 启动新窗口
      _launchNewWindow(projectPath, isDirectory: isDirectory);
    } catch (e) {
      if (kDebugMode) {
        print('在新窗口打开失败: $e');
      }
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('在新窗口打开失败: $e')),
        );
      }
    }
  }
  
  // 启动新窗口
  Future<void> _launchNewWindow(String filePath, {bool isDirectory = false}) async {
    try {
      // 获取当前应用的可执行文件路径
      final executablePath = Platform.resolvedExecutable;
      final projectPath = isDirectory ? filePath : Directory(filePath).parent.path;
      
      if (kDebugMode) {
        print('启动新窗口: $executablePath, 项目路径: $projectPath');
      }
      
      // 在Windows上使用不同的启动方式
      if (Platform.isWindows) {
        // 使用ProcessStartInfo启动新进程，添加--coding-screen参数直接进入智能编程页面
        final result = await Process.start(
          'cmd.exe',
          ['/c', 'start', '', executablePath, '--project-path', projectPath, '--coding-screen'],
        );
        
        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已在新窗口打开: ${path.basename(projectPath)}')),
          );
        }
      } else {
        // 在其他平台上使用Process.run，添加--coding-screen参数
        final result = await Process.run(
          executablePath,
          ['--project-path', projectPath, '--coding-screen'],
          runInShell: true,
        );
        
        if (result.exitCode != 0) {
          if (kDebugMode) {
            print('启动新窗口失败: ${result.stderr}');
          }
          
          // 显示错误提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('启动新窗口失败，请检查应用配置')),
            );
          }
        } else {
          // 显示成功提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已在新窗口打开: ${path.basename(projectPath)}')),
            );
          }
        }
      }
      
      // 保存当前项目路径到设置
      final settingsService = ref.read(settingsServiceProvider);
      await settingsService.initialize();
      await settingsService.saveLastOpenedProjectPath(projectPath);
      await settingsService.addToRecentProjects(projectPath);
      
    } catch (e) {
      if (kDebugMode) {
        print('启动新窗口异常: $e');
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动新窗口失败: $e')),
        );
      }
    }
  }

  // 处理错误
  void _handleError(String message) {
    if (kDebugMode) {
      print(message);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '确定',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;
    
    // 在窄屏幕上自动隐藏文件树和AI助手
    if (isNarrowScreen) {
      _showFileTree.value = false;
      _showAiAssistant = false;
    }
    
    return WillPopScope(
      onWillPop: () async {
        // 在页面退出前保存状态
        try {
          // 获取当前目录路径
          String? currentDirPath;
          try {
            final fileTreeState = ref.read(fileTreeProvider);
            currentDirPath = fileTreeState.rootNode?.path;
          } catch (e) {
            // 忽略获取目录路径时的错误
            if (kDebugMode) {
              print('获取当前目录路径失败: $e');
            }
          }
          
          // 保存当前状态到编辑器提供者
          try {
            final editorNotifier = ref.read(editorProvider.notifier);
            editorNotifier.updateState(
              openFiles: _openFiles,
              activeFileIndex: _activeFileIndex,
              showFileTree: _showFileTree.value,
              showLineNumbers: _showLineNumbers,
              showMinimap: _showMinimap,
              fileTreeWidth: _fileTreeWidth,
              currentDirectoryPath: currentDirPath,
            );
          } catch (e) {
            if (kDebugMode) {
              print('更新编辑器状态失败: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('保存编辑器状态失败: $e');
          }
        }
        return true;
      },
      child: Stack(
        children: [
          Scaffold(
            body: Column(
              children: [
                // 编辑器工具栏
                EditorToolbar(
                  filePath: _filePath,
                  showLineNumbers: _showLineNumbers,
                  showMinimap: _showMinimap,
                  showFileTree: _showFileTree.value,
                  onFormat: _formatCode,
                  onFindReplacePressed: _showFindDialog,
                  onToggleLineNumbers: () {
                    setState(() => _showLineNumbers = !_showLineNumbers);
                  },
                  onToggleMinimap: () {
                    setState(() => _showMinimap = !_showMinimap);
                  },
                  onToggleFileTree: () {
                    _showFileTree.value = !_showFileTree.value;
                  },
                  onBack: () {
                    // 在返回前保存状态
                    try {
                      // 获取当前目录路径
                      String? currentDirPath;
                      try {
                        final fileTreeState = ref.read(fileTreeProvider);
                        currentDirPath = fileTreeState.rootNode?.path;
                      } catch (e) {
                        // 忽略获取目录路径时的错误
                        if (kDebugMode) {
                          print('获取当前目录路径失败: $e');
                        }
                      }
                      
                      // 保存当前状态到编辑器提供者
                      try {
                        final editorNotifier = ref.read(editorProvider.notifier);
                        editorNotifier.updateState(
                          openFiles: _openFiles,
                          activeFileIndex: _activeFileIndex,
                          showFileTree: _showFileTree.value,
                          showLineNumbers: _showLineNumbers,
                          showMinimap: _showMinimap,
                          fileTreeWidth: _fileTreeWidth,
                          currentDirectoryPath: currentDirPath,
                        );
                      } catch (e) {
                        if (kDebugMode) {
                          print('更新编辑器状态失败: $e');
                        }
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('保存编辑器状态失败: $e');
                      }
                    }
                    Navigator.of(context).pop();
                  },
                  onSave: _saveFile,
                  onOpenProject: _openProject,
                  onOpenInNewWindow: _openInNewWindow,
                ),
                
                // 主要内容区域
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 文件树
                      ValueListenableBuilder<bool>(
                        valueListenable: _showFileTree,
                        builder: (context, showFileTree, child) {
                          if (!showFileTree || isNarrowScreen) return const SizedBox();
                          return SizedBox(
                            width: _fileTreeWidth,
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _fileTreeWidth = (_fileTreeWidth + details.delta.dx)
                                      .clamp(_minFileTreeWidth, _maxFileTreeWidth);
                                });
                              },
                              child: FileTree(
                                enableSmartHide: true,
                                hideDelay: const Duration(seconds: 20),
                                onFileSelected: (filePath) {
                                  _loadFile(filePath);
                                  setState(() {
                                    if (!_openFiles.contains(filePath)) {
                                      _openFiles.add(filePath);
                                      _activeFileIndex = _openFiles.length - 1;
                                    } else {
                                      _activeFileIndex = _openFiles.indexOf(filePath);
                                    }
                                  });
                                },
                                onToggleVisibility: () {
                                  _showFileTree.value = !_showFileTree.value;
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // 分隔线
                      ValueListenableBuilder<bool>(
                        valueListenable: _showFileTree,
                        builder: (context, showFileTree, child) {
                          if (!showFileTree || isNarrowScreen) return const SizedBox();
                          return MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: Container(
                              width: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                          );
                        },
                      ),
                      
                      // 编辑器区域
                      Expanded(
                        child: Column(
                          children: [
                            // 标签页
                            if (_openFiles.isNotEmpty)
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                ),
                                child: EditorTabs(
                                  files: _openFiles,
                                  activeIndex: _activeFileIndex,
                                  onClose: (index) {
                                    setState(() {
                                      final path = _openFiles.removeAt(index);
                                      if (_activeFileIndex >= _openFiles.length) {
                                        _activeFileIndex = _openFiles.isEmpty ? -1 : _openFiles.length - 1;
                                      }
                                      if (_openFiles.isEmpty) {
                                        _text = '';
                                        _filePath = '';
                                      } else {
                                        _loadFile(_openFiles[_activeFileIndex]);
                                      }
                                      ref.read(editorProvider.notifier).closeFile(path);
                                    });
                                  },
                                  onSelect: (index) {
                                    if (index >= 0 && index < _openFiles.length) {
                                      setState(() {
                                        _activeFileIndex = index;
                                        _loadFile(_openFiles[index]);
                                      });
                                    }
                                  },
                                ),
                              ),
                            
                            // 编辑器
                            Expanded(
                              child: CodeEditor(
                                text: _text,
                                filePath: _filePath,
                                readOnly: false,
                                showLineNumbers: _showLineNumbers,
                                showMinimap: _showMinimap && !isNarrowScreen,
                                focusNode: _editorFocusNode,
                                onTextChanged: _updateText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // AI助手
                      if (_showAiAssistant && !isNarrowScreen)
                        SizedBox(
                          width: _aiAssistantWidth,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _aiAssistantWidth = (_aiAssistantWidth - details.delta.dx)
                                    .clamp(_minAiAssistantWidth, _maxAiAssistantWidth);
                              });
                            },
                            child: const AIAssistant(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // 在窄屏幕上显示底部导航栏
            bottomNavigationBar: isNarrowScreen
                ? BottomNavigationBar(
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.folder),
                        label: '文件',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.code),
                        label: '编辑器',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat),
                        label: 'AI助手',
                      ),
                    ],
                    currentIndex: _showFileTree.value ? 0 : (_showAiAssistant ? 2 : 1),
                    onTap: (index) {
                      setState(() {
                        switch (index) {
                          case 0:
                            _showFileTree.value = true;
                            _showAiAssistant = false;
                            break;
                          case 1:
                            _showFileTree.value = false;
                            _showAiAssistant = false;
                            break;
                          case 2:
                            _showFileTree.value = false;
                            _showAiAssistant = true;
                            break;
                        }
                      });
                    },
                  )
                : null,
          ),
          
          // 添加AI助手悬浮按钮
          const AIAssistantFloatingButton(),
        ],
      ),
    );
  }
} 