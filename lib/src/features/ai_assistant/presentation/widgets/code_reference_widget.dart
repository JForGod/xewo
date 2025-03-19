// 2025-03-20: 新增 - 代码引用显示组件

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/standard_theme.dart';
import '../../domain/utils/code_block_parser.dart';

/// 代码引用显示组件
class CodeReferenceWidget extends StatelessWidget {
  /// 代码引用
  final CodeReference reference;
  
  /// 是否显示行号
  final bool showLineNumbers;
  
  /// 是否可编辑
  final bool isEditable;
  
  /// 编辑事件回调
  final Function(CodeReference)? onEdit;
  
  /// 构造函数
  const CodeReferenceWidget({
    Key? key,
    required this.reference,
    this.showLineNumbers = true,
    this.isEditable = false,
    this.onEdit,
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
    // 提取文件名称
    final fileName = reference.filePath.split('/').last;
    
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
          Icon(
            Icons.code,
            size: 16.0,
            color: Colors.amber.shade400,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              '$fileName (${reference.startLine}-${reference.endLine})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${reference.endLine - reference.startLine + 1} 行',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10.0,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建代码内容
  Widget _buildCodeContent() {
    final lines = reference.code.split('\n');
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _calculateCodeWidth(lines),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < lines.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLineNumbers)
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${reference.startLine + i}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.0,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  if (showLineNumbers)
                    SizedBox(
                      width: 12,
                      child: Text(
                        '|',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.0,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      lines[i],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.0,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
          ],
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
            icon: Icons.navigate_next,
            label: '查看文件',
            onPressed: () => _viewFile(context),
          ),
          if (isEditable && onEdit != null) ...[
            const SizedBox(width: 12.0),
            _buildFooterButton(
              icon: Icons.edit,
              label: '编辑',
              onPressed: () {
                if (onEdit != null) {
                  onEdit!(reference);
                }
              },
            ),
          ],
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
  
  /// 计算代码宽度
  double _calculateCodeWidth(List<String> lines) {
    // 一个简单的方式：假设每个字符的宽度为8
    const charWidth = 8.0;
    
    if (lines.isEmpty) return 100.0;
    
    // 找出最长的行宽度
    double maxLineWidth = 0.0;
    
    for (final line in lines) {
      final lineWidth = line.length * charWidth;
      if (lineWidth > maxLineWidth) {
        maxLineWidth = lineWidth;
      }
    }
    
    // 计算总宽度，包括行号区域
    final lineNumberWidth = showLineNumbers ? 52.0 : 0.0;
    const minContentWidth = 300.0;
    
    return lineNumberWidth + (maxLineWidth < minContentWidth ? minContentWidth : maxLineWidth + 20.0);
  }
  
  /// 复制代码
  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: reference.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('代码已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// 查看文件
  void _viewFile(BuildContext context) {
    // 此功能需要与编辑器集成
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('查看文件功能正在开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 