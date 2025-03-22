// 2025-03-22: 新增 - 创建手势跟踪设置标签页，支持手势识别和操作控制功能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../themes/standard_theme.dart';

/// 手势识别模式
enum GestureRecognitionMode {
  /// 基础手势识别（点击、滑动、缩放等）
  basic,
  
  /// 高级手势识别（多点触控、精确跟踪）
  advanced,
  
  /// 自定义手势识别
  custom
}

/// 手势灵敏度级别
enum GestureSensitivityLevel {
  /// 低灵敏度
  low,
  
  /// 中等灵敏度
  medium,
  
  /// 高灵敏度
  high,
  
  /// 自定义灵敏度
  custom
}

/// 手势类型
enum GestureType {
  /// 上滑
  swipeUp,
  
  /// 下滑
  swipeDown,
  
  /// 左滑
  swipeLeft,
  
  /// 右滑
  swipeRight,
  
  /// 捏合
  pinch,
  
  /// 双指滑动
  twoFingerSwipe,
  
  /// 长按
  longPress,
  
  /// 双击
  doubleTap
}

/// 手势跟踪设置标签页
class GestureTrackingSettingsTab extends ConsumerStatefulWidget {
  /// 构造函数
  const GestureTrackingSettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<GestureTrackingSettingsTab> createState() => _GestureTrackingSettingsTabState();
}

class _GestureTrackingSettingsTabState extends ConsumerState<GestureTrackingSettingsTab> {
  /// 是否启用手势跟踪
  bool _enableGestureTracking = false;
  
  /// 当前选择的手势识别模式
  GestureRecognitionMode _selectedGestureMode = GestureRecognitionMode.basic;
  
  /// 当前选择的手势灵敏度级别
  GestureSensitivityLevel _selectedSensitivityLevel = GestureSensitivityLevel.medium;
  
  /// 自定义灵敏度值
  double _customSensitivityValue = 0.5;
  
  /// 是否启用振动反馈
  bool _enableHapticFeedback = true;
  
  /// 是否启用声音反馈
  bool _enableSoundFeedback = false;
  
  /// 是否启用视觉反馈
  bool _enableVisualFeedback = true;
  
  /// 是否显示手势指示器
  bool _showGestureIndicator = true;
  
  /// 是否允许自定义手势
  bool _allowCustomGestures = false;
  
  /// 手势操作映射
  final Map<GestureType, String> _gestureActions = {};
  
  @override
  void initState() {
    super.initState();
    _loadGestureSettings();
    _initDefaultGestureActions();
  }
  
  /// 2025-03-22: 新增 - 初始化默认手势操作映射
  void _initDefaultGestureActions() {
    _gestureActions[GestureType.swipeUp] = '向上滚动';
    _gestureActions[GestureType.swipeDown] = '向下滚动';
    _gestureActions[GestureType.swipeLeft] = '下一个';
    _gestureActions[GestureType.swipeRight] = '上一个';
    _gestureActions[GestureType.pinch] = '缩放';
    _gestureActions[GestureType.twoFingerSwipe] = '切换页面';
    _gestureActions[GestureType.longPress] = '显示菜单';
    _gestureActions[GestureType.doubleTap] = '选择';
  }
  
  /// 2025-03-22: 新增 - 加载手势设置
  Future<void> _loadGestureSettings() async {
    // TODO: 从设置服务中加载手势设置
    // 示例代码，实际实现需要加载保存的设置
    setState(() {
      _enableGestureTracking = true;
      _selectedGestureMode = GestureRecognitionMode.basic;
      _selectedSensitivityLevel = GestureSensitivityLevel.medium;
      _enableHapticFeedback = true;
      _enableSoundFeedback = false;
      _enableVisualFeedback = true;
      _showGestureIndicator = true;
      _allowCustomGestures = false;
    });
  }
  
  /// 2025-03-22: 新增 - 保存手势设置
  Future<void> saveSettings() async {
    // TODO: 将当前设置保存到设置服务
    // 示例代码，实际实现需要保存设置到持久化存储
    
    // 显示保存成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('手势设置已保存')),
      );
    }
  }
  
  /// 2025-03-22: 新增 - 构建手势跟踪开关UI
  Widget _buildGestureTrackingSwitch() {
    return SwitchListTile(
      title: const Text('启用手势跟踪'),
      subtitle: const Text('允许使用手势控制应用'),
      value: _enableGestureTracking,
      onChanged: (value) {
        setState(() {
          _enableGestureTracking = value;
        });
      },
      tileColor: const Color(0xFF2A2A38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  /// 2025-03-22: 新增 - 构建手势识别模式选择UI
  Widget _buildGestureRecognitionModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '手势识别模式',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GestureRecognitionMode.values.map((mode) {
            final isSelected = _selectedGestureMode == mode;
            String label;
            switch (mode) {
              case GestureRecognitionMode.basic:
                label = '基础模式';
                break;
              case GestureRecognitionMode.advanced:
                label = '高级模式';
                break;
              case GestureRecognitionMode.custom:
                label = '自定义模式';
                break;
            }
            
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedGestureMode = mode;
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: StandardTheme.accentColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getGestureRecognitionModeDescription(_selectedGestureMode),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取手势识别模式描述
  String _getGestureRecognitionModeDescription(GestureRecognitionMode mode) {
    switch (mode) {
      case GestureRecognitionMode.basic:
        return '识别基本的手势操作，如点击、滑动和缩放';
      case GestureRecognitionMode.advanced:
        return '识别更复杂的手势操作，如多点触控和精确跟踪';
      case GestureRecognitionMode.custom:
        return '自定义手势识别规则';
    }
  }
  
  /// 2025-03-22: 新增 - 构建手势灵敏度设置UI
  Widget _buildGestureSensitivitySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '手势灵敏度',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GestureSensitivityLevel.values.map((level) {
            final isSelected = _selectedSensitivityLevel == level;
            String label;
            switch (level) {
              case GestureSensitivityLevel.low:
                label = '低';
                break;
              case GestureSensitivityLevel.medium:
                label = '中';
                break;
              case GestureSensitivityLevel.high:
                label = '高';
                break;
              case GestureSensitivityLevel.custom:
                label = '自定义';
                break;
            }
            
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedSensitivityLevel = level;
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: StandardTheme.accentColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getGestureSensitivityLevelDescription(_selectedSensitivityLevel),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        
        if (_selectedSensitivityLevel == GestureSensitivityLevel.custom) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _customSensitivityValue,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: (_customSensitivityValue * 100).toStringAsFixed(0) + '%',
                  onChanged: (value) {
                    setState(() {
                      _customSensitivityValue = value;
                    });
                  },
                  activeColor: StandardTheme.accentColor,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${(_customSensitivityValue * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取手势灵敏度级别描述
  String _getGestureSensitivityLevelDescription(GestureSensitivityLevel level) {
    switch (level) {
      case GestureSensitivityLevel.low:
        return '需要较大幅度的手势才能识别，减少误触';
      case GestureSensitivityLevel.medium:
        return '适合大多数用户的默认灵敏度';
      case GestureSensitivityLevel.high:
        return '对微小的手势变化也能识别，但可能增加误触';
      case GestureSensitivityLevel.custom:
        return '根据个人偏好调整灵敏度';
    }
  }
  
  /// 2025-03-22: 新增 - 构建反馈设置UI
  Widget _buildFeedbackSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '反馈设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('振动反馈'),
          subtitle: const Text('手势识别成功时振动'),
          value: _enableHapticFeedback,
          onChanged: (value) {
            setState(() {
              _enableHapticFeedback = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('声音反馈'),
          subtitle: const Text('手势识别成功时播放声音'),
          value: _enableSoundFeedback,
          onChanged: (value) {
            setState(() {
              _enableSoundFeedback = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('视觉反馈'),
          subtitle: const Text('手势识别成功时显示动画'),
          value: _enableVisualFeedback,
          onChanged: (value) {
            setState(() {
              _enableVisualFeedback = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('显示手势指示器'),
          subtitle: const Text('显示手势轨迹'),
          value: _showGestureIndicator,
          onChanged: (value) {
            setState(() {
              _showGestureIndicator = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 构建手势操作映射UI
  Widget _buildGestureActionMappings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '手势操作映射',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('允许自定义手势'),
          subtitle: const Text('允许创建和使用自定义手势'),
          value: _allowCustomGestures,
          onChanged: (value) {
            setState(() {
              _allowCustomGestures = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A38),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: GestureType.values.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF3A3A48)),
            itemBuilder: (context, index) {
              final gestureType = GestureType.values[index];
              final actionName = _gestureActions[gestureType] ?? '未设置';
              
              return ListTile(
                title: Text(_getGestureTypeName(gestureType)),
                subtitle: Text(actionName),
                trailing: const Icon(Icons.edit, color: Colors.grey),
                onTap: () {
                  // TODO: 实现编辑手势操作映射功能
                  _showEditGestureActionDialog(gestureType);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 显示编辑手势操作对话框
  void _showEditGestureActionDialog(GestureType gestureType) {
    final TextEditingController controller = TextEditingController(text: _gestureActions[gestureType]);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('编辑${_getGestureTypeName(gestureType)}操作'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '操作名称',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _gestureActions[gestureType] = controller.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }
  
  /// 2025-03-22: 新增 - 获取手势类型名称
  String _getGestureTypeName(GestureType type) {
    switch (type) {
      case GestureType.swipeUp:
        return '上滑';
      case GestureType.swipeDown:
        return '下滑';
      case GestureType.swipeLeft:
        return '左滑';
      case GestureType.swipeRight:
        return '右滑';
      case GestureType.pinch:
        return '捏合';
      case GestureType.twoFingerSwipe:
        return '双指滑动';
      case GestureType.longPress:
        return '长按';
      case GestureType.doubleTap:
        return '双击';
    }
  }
  
  /// 2025-03-22: 新增 - 构建测试按钮UI
  Widget _buildTestButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: 实现手势测试功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开始手势测试模式...')),
        );
      },
      icon: const Icon(Icons.touch_app),
      label: const Text('测试手势'),
      style: ElevatedButton.styleFrom(
        backgroundColor: StandardTheme.accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGestureTrackingSwitch(),
          if (_enableGestureTracking) ...[
            const SizedBox(height: 24),
            _buildGestureRecognitionModeSelection(),
            const SizedBox(height: 24),
            _buildGestureSensitivitySettings(),
            const SizedBox(height: 24),
            _buildFeedbackSettings(),
            const SizedBox(height: 24),
            _buildGestureActionMappings(),
            const SizedBox(height: 24),
            _buildTestButton(),
          ],
        ],
      ),
    );
  }
} 