// 2025-03-22: 新增 - 创建高级设置标签页，包含性能、数据管理和开发者选项

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../themes/standard_theme.dart';

/// 缓存清理类型
enum CacheType {
  /// 对话历史缓存
  conversationHistory,
  
  /// 图像缓存
  images,
  
  /// 模型缓存
  models,
  
  /// 临时文件
  tempFiles,
  
  /// 所有缓存
  all
}

/// 性能模式
enum PerformanceMode {
  /// 平衡模式
  balanced,
  
  /// 高性能模式
  highPerformance,
  
  /// 省电模式
  powerSaving,
  
  /// 自定义模式
  custom
}

/// 高级设置标签页
class AdvancedSettingsTab extends ConsumerStatefulWidget {
  /// 构造函数
  const AdvancedSettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedSettingsTab> createState() => _AdvancedSettingsTabState();
}

class _AdvancedSettingsTabState extends ConsumerState<AdvancedSettingsTab> {
  /// 当前选择的性能模式
  PerformanceMode _selectedPerformanceMode = PerformanceMode.balanced;
  
  /// 是否开启开发者模式
  bool _developerMode = false;
  
  /// 是否启用日志记录
  bool _enableLogging = true;
  
  /// 是否启用崩溃报告
  bool _enableCrashReporting = true;
  
  /// 是否启用使用数据收集
  bool _enableUsageDataCollection = false;
  
  /// 是否使用调试服务器
  bool _useDebugServer = false;
  
  /// 日志级别
  int _logLevel = 2; // 0: 错误, 1: 警告, 2: 信息, 3: 调试, 4: 详细
  
  /// 最大对话数量控制器
  final TextEditingController _maxConversationsController = TextEditingController(text: '100');
  
  /// 最大对话消息数量控制器
  final TextEditingController _maxMessagesPerConversationController = TextEditingController(text: '200');
  
  /// 调试服务器URL控制器
  final TextEditingController _debugServerUrlController = TextEditingController(text: 'http://localhost:8080');
  
  /// 自定义GPU内存限制控制器（MB）
  final TextEditingController _gpuMemoryLimitController = TextEditingController(text: '512');
  
  /// 缓存大小（MB）
  double _cacheSize = 256;
  
  @override
  void initState() {
    super.initState();
    _loadAdvancedSettings();
  }
  
  @override
  void dispose() {
    _maxConversationsController.dispose();
    _maxMessagesPerConversationController.dispose();
    _debugServerUrlController.dispose();
    _gpuMemoryLimitController.dispose();
    super.dispose();
  }
  
  /// 2025-03-22: 新增 - 加载高级设置
  Future<void> _loadAdvancedSettings() async {
    // TODO: 从设置服务中加载高级设置
    // 示例代码，实际实现需要加载保存的设置
    setState(() {
      _selectedPerformanceMode = PerformanceMode.balanced;
      _developerMode = false;
      _enableLogging = true;
      _enableCrashReporting = true;
      _enableUsageDataCollection = false;
      _useDebugServer = false;
      _logLevel = 2;
      _cacheSize = 256;
    });
  }
  
  /// 2025-03-22: 新增 - 保存高级设置
  Future<void> saveSettings() async {
    // TODO: 将当前设置保存到设置服务
    // 示例代码，实际实现需要保存设置到持久化存储
    
    // 显示保存成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('高级设置已保存')),
      );
    }
  }
  
  /// 2025-03-22: 新增 - 构建性能设置UI
  Widget _buildPerformanceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性能设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PerformanceMode.values.map((mode) {
            final isSelected = _selectedPerformanceMode == mode;
            String label;
            switch (mode) {
              case PerformanceMode.balanced:
                label = '平衡模式';
                break;
              case PerformanceMode.highPerformance:
                label = '高性能模式';
                break;
              case PerformanceMode.powerSaving:
                label = '省电模式';
                break;
              case PerformanceMode.custom:
                label = '自定义模式';
                break;
            }
            
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedPerformanceMode = mode;
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: StandardTheme.accentColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getPerformanceModeDescription(_selectedPerformanceMode),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        
        if (_selectedPerformanceMode == PerformanceMode.custom) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _gpuMemoryLimitController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'GPU内存限制',
              fillColor: Color(0xFF2A2A38),
              filled: true,
              labelStyle: TextStyle(color: Colors.grey),
              suffixText: 'MB',
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取性能模式描述
  String _getPerformanceModeDescription(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.balanced:
        return '在性能和电池寿命之间平衡，适合大多数用户';
      case PerformanceMode.highPerformance:
        return '最大化性能，但会增加电池消耗和发热';
      case PerformanceMode.powerSaving:
        return '最小化电池消耗，但会降低性能';
      case PerformanceMode.custom:
        return '根据个人需求自定义性能参数';
    }
  }
  
  /// 2025-03-22: 新增 - 构建数据管理UI
  Widget _buildDataManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '数据管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxConversationsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '最大对话数量',
                  fillColor: Color(0xFF2A2A38),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxMessagesPerConversationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '每个对话最大消息数',
                  fillColor: Color(0xFF2A2A38),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('缓存大小限制'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _cacheSize,
                    min: 64,
                    max: 1024,
                    divisions: 15,
                    label: '${_cacheSize.toStringAsFixed(0)} MB',
                    onChanged: (value) {
                      setState(() {
                        _cacheSize = value;
                      });
                    },
                    activeColor: StandardTheme.accentColor,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${_cacheSize.toStringAsFixed(0)} MB',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _showClearCacheDialog(CacheType.all);
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('清除所有缓存'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showClearCacheDialog(CacheType.conversationHistory);
              },
              icon: const Icon(Icons.history),
              label: const Text('清除对话历史'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 显示清除缓存对话框
  void _showClearCacheDialog(CacheType cacheType) {
    String title;
    String content;
    
    switch (cacheType) {
      case CacheType.all:
        title = '清除所有缓存';
        content = '这将清除所有缓存数据，包括对话历史、图像缓存和模型缓存。此操作不可恢复，是否继续？';
        break;
      case CacheType.conversationHistory:
        title = '清除对话历史';
        content = '这将删除所有对话历史记录。此操作不可恢复，是否继续？';
        break;
      case CacheType.images:
        title = '清除图像缓存';
        content = '这将删除所有图像缓存。此操作不可恢复，是否继续？';
        break;
      case CacheType.models:
        title = '清除模型缓存';
        content = '这将删除所有模型缓存。此操作不可恢复，是否继续？';
        break;
      case CacheType.tempFiles:
        title = '清除临时文件';
        content = '这将删除所有临时文件。此操作不可恢复，是否继续？';
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 实现缓存清理逻辑
                Navigator.of(context).pop();
                
                String message;
                switch (cacheType) {
                  case CacheType.all:
                    message = '已清除所有缓存';
                    break;
                  case CacheType.conversationHistory:
                    message = '已清除对话历史';
                    break;
                  case CacheType.images:
                    message = '已清除图像缓存';
                    break;
                  case CacheType.models:
                    message = '已清除模型缓存';
                    break;
                  case CacheType.tempFiles:
                    message = '已清除临时文件';
                    break;
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('确认清除'),
            ),
          ],
        );
      },
    );
  }
  
  /// 2025-03-22: 新增 - 构建开发者选项UI
  Widget _buildDeveloperOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '开发者选项',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: _developerMode,
              onChanged: (value) {
                setState(() {
                  _developerMode = value;
                  if (!value) {
                    // 禁用开发者模式时，重置相关设置
                    _useDebugServer = false;
                    _logLevel = 2;
                  }
                });
              },
              activeColor: StandardTheme.accentColor,
            ),
          ],
        ),
        if (_developerMode) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('启用日志记录'),
            value: _enableLogging,
            onChanged: (value) {
              setState(() {
                _enableLogging = value;
              });
            },
            tileColor: const Color(0xFF2A2A38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('启用崩溃报告'),
            value: _enableCrashReporting,
            onChanged: (value) {
              setState(() {
                _enableCrashReporting = value;
              });
            },
            tileColor: const Color(0xFF2A2A38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('启用使用数据收集'),
            subtitle: const Text('仅用于改进应用，不会收集个人信息'),
            value: _enableUsageDataCollection,
            onChanged: (value) {
              setState(() {
                _enableUsageDataCollection = value;
              });
            },
            tileColor: const Color(0xFF2A2A38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('使用调试服务器'),
            value: _useDebugServer,
            onChanged: (value) {
              setState(() {
                _useDebugServer = value;
              });
            },
            tileColor: const Color(0xFF2A2A38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          
          if (_useDebugServer) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _debugServerUrlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '调试服务器URL',
                fillColor: Color(0xFF2A2A38),
                filled: true,
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
          
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('日志级别'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('错误'),
                      value: 0,
                      groupValue: _logLevel,
                      onChanged: (value) {
                        setState(() {
                          _logLevel = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('警告'),
                      value: 1,
                      groupValue: _logLevel,
                      onChanged: (value) {
                        setState(() {
                          _logLevel = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('信息'),
                      value: 2,
                      groupValue: _logLevel,
                      onChanged: (value) {
                        setState(() {
                          _logLevel = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('调试'),
                      value: 3,
                      groupValue: _logLevel,
                      onChanged: (value) {
                        setState(() {
                          _logLevel = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('详细'),
                      value: 4,
                      groupValue: _logLevel,
                      onChanged: (value) {
                        setState(() {
                          _logLevel = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: 实现导出日志功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('正在导出日志...')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('导出日志'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: 实现重置应用功能
                  _showResetAppDialog();
                },
                icon: const Icon(Icons.restore),
                label: const Text('重置应用'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 显示重置应用对话框
  void _showResetAppDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置应用'),
          content: const Text('这将重置所有应用设置、清除所有缓存并恢复出厂设置。此操作不可恢复，是否继续？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 实现重置应用功能
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已重置应用，即将重启...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('确认重置'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceSettings(),
          const SizedBox(height: 24),
          _buildDataManagement(),
          const SizedBox(height: 24),
          _buildDeveloperOptions(),
        ],
      ),
    );
  }
} 