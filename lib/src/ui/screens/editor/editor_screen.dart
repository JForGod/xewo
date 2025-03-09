import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';
import '../../widgets/editor/code_editor.dart';
import '../../widgets/editor/editor_toolbar.dart';
import '../../../services/formatter/formatter_manager.dart';
import '../../../services/file/file_service.dart';
import '../../../state/providers/editor_provider.dart';

/// 编辑器功能集成页面
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  String _currentCode = '''
// 欢迎使用xEwo代码编辑器
void main() {
  print('Hello, xEwo!');
}
''';
  String _currentLanguage = 'dart';
  String _currentFileName = 'main.dart';
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    // 监听编辑器状态变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final editorState = ref.read(editorProvider);
      if (editorState.currentFilePath.isNotEmpty) {
        _loadFile(editorState.currentFilePath);
      }
    });
  }

  // 加载文件
  Future<void> _loadFile(String filePath) async {
    try {
      // 使用文件服务读取文件内容
      final fileService = FileService();
      final content = await fileService.readFile(filePath);
      final fileName = filePath.split('/').last;
      final language = _getLanguageFromFileName(fileName);
      
      setState(() {
        _currentCode = content;
        _currentFileName = fileName;
        _currentLanguage = language;
        _isModified = false;
      });
      
      // 更新编辑器状态
      ref.read(editorProvider.notifier).updateCurrentFile(filePath, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载文件失败: $e')),
        );
      }
    }
  }

  // 保存文件
  Future<void> _saveFile() async {
    final editorState = ref.read(editorProvider);
    if (editorState.currentFilePath.isEmpty) {
      _showSaveAsDialog();
      return;
    }

    try {
      // 使用文件服务保存文件
      final fileService = FileService();
      await fileService.writeFile(editorState.currentFilePath, _currentCode);
      
      setState(() {
        _isModified = false;
      });
      
      // 更新编辑器状态
      ref.read(editorProvider.notifier).saveCurrentFile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存文件失败: $e')),
        );
      }
    }
  }

  // 显示另存为对话框
  Future<void> _showSaveAsDialog() async {
    final controller = TextEditingController(text: _currentFileName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存文件'),
        content: Container(
          width: 300,
          constraints: const BoxConstraints(maxWidth: 300),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '文件名',
              isDense: true,
            ),
            maxLines: 1,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // 使用文件服务保存文件
        final fileService = FileService();
        final directoryPath = 'H:\\AxE\\xewo'; // 默认保存路径
        final filePath = '$directoryPath/$result';
        
        await fileService.writeFile(filePath, _currentCode);
        
        setState(() {
          _currentFileName = result;
          _isModified = false;
        });
        
        // 更新编辑器状态
        ref.read(editorProvider.notifier).updateCurrentFile(filePath, _currentCode);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件保存成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存文件失败: $e')),
          );
        }
      }
    }
  }

  // 格式化代码
  Future<void> _formatCode() async {
    final editorState = ref.read(editorProvider);
    if (editorState.currentFilePath.isEmpty) return;
    
    try {
      // 使用格式化服务格式化代码
      final formatterManager = FormatterManager();
      final formattedCode = await formatterManager.formatCode(
        _currentCode,
        _currentLanguage,
      );
      
      setState(() {
        _currentCode = formattedCode;
        _isModified = true;
      });
      
      // 更新编辑器状态
      ref.read(editorProvider.notifier).updateCurrentFileContent(_currentCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('代码格式化成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('格式化代码失败: $e')),
        );
      }
    }
  }

  // 根据文件名获取语言
  String _getLanguageFromFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return 'dart';
      case 'js':
        return 'javascript';
      case 'ts':
        return 'typescript';
      case 'html':
        return 'html';
      case 'css':
        return 'css';
      case 'json':
        return 'json';
      case 'md':
        return 'markdown';
      case 'py':
        return 'python';
      case 'java':
        return 'java';
      default:
        return 'plaintext';
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // 编辑器工具栏
          EditorToolbar(
            onFormatPressed: _formatCode,
            onFindReplacePressed: () {
              showFindReplaceDialog(
                context,
                editorState,
                ref.read(editorProvider.notifier),
              );
            },
            onSettingsPressed: () {
              showEditorSettingsDialog(context);
            },
            onShortcutsPressed: () {
              showShortcutSettingsDialog(context);
            },
            onSavePressed: _saveFile,
            onSaveAsPressed: _showSaveAsDialog,
          ),
          
          // 编辑器主体
          Expanded(
            child: CodeEditor(
              code: _currentCode,
              language: _currentLanguage,
              onCodeChanged: (code) {
                setState(() {
                  _currentCode = code;
                  _isModified = true;
                });
                
                // 更新编辑器状态
                ref.read(editorProvider.notifier).updateCurrentFileContent(code);
              },
            ),
          ),
        ],
      ),
    );
  }
} 