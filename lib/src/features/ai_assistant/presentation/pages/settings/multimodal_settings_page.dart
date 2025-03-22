// 2025-03-22: 新增 - 创建多模态设置页面，整合LLM、语音、视觉和手势设置

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';
import '../../themes/standard_theme.dart';
import '../llm_config_page.dart';
import 'tabs/llm_settings_tab.dart';
import 'tabs/voice_settings_tab.dart';
import 'tabs/visual_input_settings_tab.dart';
import 'tabs/gesture_tracking_settings_tab.dart';
import 'tabs/advanced_settings_tab.dart';

/// 多模态设置页面，整合了各种输入模态的设置
class MultimodalSettingsPage extends ConsumerStatefulWidget {
  /// 构造函数
  const MultimodalSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MultimodalSettingsPage> createState() => _MultimodalSettingsPageState();
}

class _MultimodalSettingsPageState extends ConsumerState<MultimodalSettingsPage> with SingleTickerProviderStateMixin {
  /// 标签控制器
  late TabController _tabController;
  
  /// 是否正在保存
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// 2025-03-22: 新增 - 保存所有设置
  Future<void> _saveAllSettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 调用各标签页的保存方法
      // 此处将在各标签页实现完成后添加
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有设置已保存')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存设置时出错: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('助手设置'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'LLM服务'),
            Tab(text: '语音设置'),
            Tab(text: '视觉输入'),
            Tab(text: '手势追踪'),
            Tab(text: '高级设置'),
          ],
        ),
        actions: [
          // 保存按钮
          TextButton.icon(
            onPressed: _isSaving ? null : _saveAllSettings,
            icon: _isSaving 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? '保存中...' : '保存所有设置'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LLMSettingsTab(),
          VoiceSettingsTab(),
          VisualInputSettingsTab(),
          GestureTrackingSettingsTab(),
          AdvancedSettingsTab(),
        ],
      ),
    );
  }
} 