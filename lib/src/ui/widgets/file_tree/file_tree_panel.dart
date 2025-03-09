import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/file_tree_provider.dart';
import 'file_tree.dart';
import 'file_preview.dart';
import 'version_control_indicator.dart';

/// 文件树面板组件，集成文件树和文件预览功能
class FileTreePanel extends ConsumerStatefulWidget {
  const FileTreePanel({Key? key}) : super(key: key);

  @override
  ConsumerState<FileTreePanel> createState() => _FileTreePanelState();
}

class _FileTreePanelState extends ConsumerState<FileTreePanel> {
  bool _showPreview = true;
  bool _showVersionControl = false;
  FileNode? _previewNode;
  
  @override
  Widget build(BuildContext context) {
    final fileTreeState = ref.watch(fileTreeProvider);
    
    // 获取当前选中的节点
    FileNode? selectedNode;
    if (fileTreeState.isMultiSelectMode) {
      if (fileTreeState.selectedPaths.isNotEmpty) {
        // 多选模式下，预览第一个选中的节点
        selectedNode = _findNodeByPath(fileTreeState.nodes, fileTreeState.selectedPaths.first);
      }
    } else if (fileTreeState.selectedPath != null) {
      // 单选模式下，预览选中的节点
      selectedNode = _findNodeByPath(fileTreeState.nodes, fileTreeState.selectedPath!);
    }
    
    // 更新预览节点
    if (selectedNode != null && selectedNode != _previewNode) {
      _previewNode = selectedNode;
    }
    
    return Column(
      children: [
        // 面板头部
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Text(
                '文件浏览器',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 版本控制按钮
              IconButton(
                icon: Icon(_showVersionControl ? Icons.history : Icons.history_outlined, size: 18),
                onPressed: () {
                  setState(() {
                    _showVersionControl = !_showVersionControl;
                    // 如果同时打开版本控制和预览，关闭预览
                    if (_showVersionControl && _showPreview) {
                      _showPreview = false;
                    }
                  });
                },
                tooltip: _showVersionControl ? '隐藏版本控制' : '显示版本控制',
                splashRadius: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
              ),
              // 预览按钮
              IconButton(
                icon: Icon(_showPreview ? Icons.visibility : Icons.visibility_off, size: 18),
                onPressed: () {
                  setState(() {
                    _showPreview = !_showPreview;
                    // 如果同时打开预览和版本控制，关闭版本控制
                    if (_showPreview && _showVersionControl) {
                      _showVersionControl = false;
                    }
                  });
                },
                tooltip: _showPreview ? '隐藏预览' : '显示预览',
                splashRadius: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ),
        
        // 面板内容
        Expanded(
          child: _buildPanelContent(),
        ),
      ],
    );
  }
  
  // 构建面板内容
  Widget _buildPanelContent() {
    // 如果没有选中节点，或者没有启用预览和版本控制，只显示文件树
    if (_previewNode == null || (!_showPreview && !_showVersionControl)) {
      return const FileTree();
    }
    
    // 如果启用了预览
    if (_showPreview) {
      return Row(
        children: [
          // 文件树
          Flexible(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: const FileTree(),
            ),
          ),
          
          // 文件预览
          Flexible(
            flex: 3,
            child: FilePreview(
              node: _previewNode,
              onClose: () {
                setState(() {
                  _showPreview = false;
                });
              },
            ),
          ),
        ],
      );
    }
    
    // 如果启用了版本控制
    if (_showVersionControl) {
      return Row(
        children: [
          // 文件树
          Flexible(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: const FileTree(),
            ),
          ),
          
          // 版本控制详情
          Flexible(
            flex: 3,
            child: Column(
              children: [
                // 版本控制详情头部
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _previewNode!.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _showVersionControl = false;
                          });
                        },
                        splashRadius: 16,
                        tooltip: '关闭版本控制',
                      ),
                    ],
                  ),
                ),
                
                // 版本控制详情内容
                Expanded(
                  child: VersionControlDetailsPanel(node: _previewNode!),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // 默认情况下只显示文件树
    return const FileTree();
  }
  
  // 根据路径查找节点
  FileNode? _findNodeByPath(List<FileNode> nodes, String path) {
    for (final node in nodes) {
      if (node.path == path) {
        return node;
      }
      
      if (node.isDirectory && node.children.isNotEmpty) {
        final result = _findNodeByPath(node.children, path);
        if (result != null) {
          return result;
        }
      }
    }
    
    return null;
  }
} 