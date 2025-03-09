import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/ui/widgets/editor/advanced_editor_core.dart';
import 'package:xewo/src/services/core/file_service.dart';
import 'package:xewo/src/services/core/language_support.dart';
import 'package:path/path.dart' as path;

/// 高级编辑器页面
class AdvancedEditorPage extends ConsumerStatefulWidget {
  /// 文件路径
  final String filePath;
  
  /// 构造函数
  const AdvancedEditorPage({
    Key? key,
    required this.filePath,
  }) : super(key: key);
  
  @override
  ConsumerState<AdvancedEditorPage> createState() => _AdvancedEditorPageState();
}

class _AdvancedEditorPageState extends ConsumerState<AdvancedEditorPage> {
  String _fileContent = '';
  bool _isLoading = true;
  String _language = 'text';
  String _fileName = '';
  
  @override
  void initState() {
    super.initState();
    _loadFile();
  }
  
  /// 加载文件
  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final fileService = ref.read(fileServiceProvider);
      final languageSupport = ref.read(languageSupportProvider);
      
      // 加载文件内容
      final content = await fileService.readFile(widget.filePath);
      
      // 获取文件名
      _fileName = path.basename(widget.filePath);
      
      // 获取文件语言
      _language = languageSupport.getLanguageFromFileName(_fileName);
      
      setState(() {
        _fileContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _fileContent = '无法加载文件: $e';
        _isLoading = false;
      });
    }
  }
  
  /// 保存文件
  Future<void> _saveFile(String content) async {
    try {
      final fileService = ref.read(fileServiceProvider);
      
      // 保存文件内容
      await fileService.writeFile(widget.filePath, content);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件已保存')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存文件失败: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveFile(_fileContent),
            tooltip: '保存',
          ),
          IconButton(
            icon: const Icon(Icons.format_align_left),
            onPressed: () => _formatCode(),
            tooltip: '格式化代码',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showEditorSettings(),
            tooltip: '编辑器设置',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AdvancedEditorCore(
              text: _fileContent,
              language: _language,
              filePath: widget.filePath,
              onTextChanged: (text) {
                _fileContent = text;
              },
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }
  
  /// 构建状态栏
  Widget _buildStatusBar() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          Text('语言: $_language'),
          const SizedBox(width: 16),
          const Text('UTF-8'),
          const Spacer(),
          const Text('行: 1, 列: 1'),
        ],
      ),
    );
  }
  
  /// 格式化代码
  void _formatCode() {
    // 实现代码格式化功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('代码格式化功能即将实现')),
    );
  }
  
  /// 显示编辑器设置
  void _showEditorSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑器设置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingItem('字体大小', '14px'),
              _buildSettingItem('缩进', '2个空格'),
              _buildSettingItem('自动保存', '开启'),
              _buildSettingItem('自动括号匹配', '开启'),
              _buildSettingItem('智能缩进', '开启'),
              _buildSettingItem('代码折叠', '开启'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  /// 构建设置项
  Widget _buildSettingItem(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 