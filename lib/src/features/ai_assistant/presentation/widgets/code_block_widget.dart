// 2025-03-17: 新增 - 代码块显示组件

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/standard_theme.dart';

/// 代码块显示组件
class CodeBlockWidget extends StatelessWidget {
  /// 代码内容
  final String code;
  
  /// 编程语言
  final String language;
  
  /// 代码块标题（可选）
  final String? title;
  
  /// 构造函数
  const CodeBlockWidget({
    Key? key,
    required this.code,
    required this.language,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(),
          
          // 代码内容
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildCodeContent(),
          ),
          
          // 底部操作栏
          _buildFooter(context),
        ],
      ),
    );
  }
  
  /// 构建标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _getLanguageColor(),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              language.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                title!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// 构建代码内容
  Widget _buildCodeContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _calculateCodeWidth(),
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13.0,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }
  
  /// 构建底部操作栏
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildFooterButton(
            icon: Icons.copy,
            label: '复制',
            onPressed: () => _copyCode(context),
          ),
          const SizedBox(width: 12.0),
          _buildFooterButton(
            icon: Icons.code,
            label: '运行',
            onPressed: () => _runCode(context),
          ),
        ],
      ),
    );
  }
  
  /// 构建底部按钮
  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14.0,
              color: StandardTheme.accentColor,
            ),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 获取语言对应的颜色
  Color _getLanguageColor() {
    switch (language.toLowerCase()) {
      case 'dart':
      case 'flutter':
        return Colors.blue.shade700;
      case 'python':
        return Colors.green.shade700;
      case 'javascript':
      case 'js':
        return Colors.yellow.shade700;
      case 'typescript':
      case 'ts':
        return Colors.blue.shade600;
      case 'java':
        return Colors.orange.shade700;
      case 'html':
        return Colors.red.shade700;
      case 'css':
        return Colors.purple.shade700;
      case 'c':
      case 'cpp':
      case 'c++':
        return Colors.blue.shade800;
      case 'json':
        return Colors.amber.shade700;
      case 'xml':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
  
  /// 计算代码宽度
  double _calculateCodeWidth() {
    // 一个简单的方式：假设每个字符的宽度为8
    const charWidth = 8.0;
    
    if (code.isEmpty) return 100.0;
    
    // 找出最长的行宽度
    double maxLineWidth = 0.0;
    
    for (final line in code.split('\n')) {
      final lineWidth = line.length * charWidth;
      if (lineWidth > maxLineWidth) {
        maxLineWidth = lineWidth;
      }
    }
    
    // 添加一些额外的空间
    const minWidth = 300.0;
    return maxLineWidth < minWidth ? minWidth : maxLineWidth + 20.0;
  }
  
  /// 复制代码
  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('代码已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// 运行代码（示例功能）
  void _runCode(BuildContext context) {
    // 真实场景中，需要实现代码的实际运行功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('运行代码功能正在开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 