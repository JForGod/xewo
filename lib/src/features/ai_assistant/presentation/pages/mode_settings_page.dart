import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_theme.dart';
import '../themes/guardian_theme.dart';
import '../themes/standard_theme.dart';
import '../themes/pro_theme.dart';
import '../widgets/assistant_container.dart';
import '../widgets/navigation_buttons.dart';
import '../../domain/models/assistant_mode.dart';

class ModeSettingsPage extends StatefulWidget {
  final AssistantMode mode;

  const ModeSettingsPage({
    Key? key,
    required this.mode,
  }) : super(key: key);

  @override
  State<ModeSettingsPage> createState() => _ModeSettingsPageState();
}

class _ModeSettingsPageState extends State<ModeSettingsPage> {
  late BoxDecoration _decoration;
  late TextStyle _titleStyle;
  late TextStyle _bodyStyle;
  late double _spacing;
  late double _borderRadius;

  @override
  void initState() {
    super.initState();
    _updateThemeValues();
  }

  @override
  void didUpdateWidget(ModeSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _updateThemeValues();
    }
  }

  void _updateThemeValues() {
    switch (widget.mode) {
      case AssistantMode.guardian:
        _decoration = GuardianTheme.containerDecoration;
        _titleStyle = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: GuardianTheme.fontSizeBase,
        );
        _bodyStyle = TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: GuardianTheme.fontSizeBase * 0.9,
        );
        _spacing = GuardianTheme.spacingUnit;
        _borderRadius = GuardianTheme.borderRadius;
        break;
      case AssistantMode.pro:
        _decoration = ProTheme.containerDecoration;
        _titleStyle = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: ProTheme.fontSizeBase,
        );
        _bodyStyle = TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: ProTheme.fontSizeBase * 0.9,
        );
        _spacing = ProTheme.spacingUnit;
        _borderRadius = ProTheme.borderRadius;
        break;
      case AssistantMode.standard:
      default:
        _decoration = StandardTheme.containerDecoration;
        _titleStyle = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: StandardTheme.fontSizeBase,
        );
        _bodyStyle = TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: StandardTheme.fontSizeBase * 0.9,
        );
        _spacing = StandardTheme.spacingUnit;
        _borderRadius = StandardTheme.borderRadius;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_spacing),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: _spacing),
          Expanded(
            child: _buildSettingsContent(),
          ),
          SizedBox(height: _spacing),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          widget.mode == AssistantMode.guardian
              ? '监护模式设置'
              : widget.mode == AssistantMode.pro
                  ? '专业模式设置'
                  : '标准模式设置',
          style: _titleStyle.copyWith(fontSize: _titleStyle.fontSize! * 1.2),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            // 关闭设置页面
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: widget.mode == AssistantMode.pro ? 16 : 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    switch (widget.mode) {
      case AssistantMode.guardian:
        return _buildGuardianSettings();
      case AssistantMode.pro:
        return _buildProSettings();
      case AssistantMode.standard:
      default:
        return _buildStandardSettings();
    }
  }

  Widget _buildGuardianSettings() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('安全设置'),
          _buildSwitchSetting('内容过滤', true),
          _buildSliderSetting('使用时间限制 (分钟)', 30, 0, 120),
          _buildSectionTitle('简化界面设置'),
          _buildSwitchSetting('大按钮模式', true),
          _buildSwitchSetting('简化语言', true),
          _buildSwitchSetting('视觉引导', true),
          _buildSectionTitle('监护控制'),
          _buildPasswordSetting('家长密码'),
          _buildSwitchSetting('活动报告', false),
          _buildSwitchSetting('远程监控', false),
        ],
      ),
    );
  }

  Widget _buildStandardSettings() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('功能设置'),
          _buildSwitchSetting('工具建议', true),
          _buildSwitchSetting('学习辅助', true),
          _buildDropdownSetting('创意级别', '中等', ['低', '中等', '高']),
          _buildSectionTitle('界面定制'),
          _buildDropdownSetting('主题设置', '默认', ['默认', '明亮', '暗黑', '自动']),
          _buildDropdownSetting('布局密度', '舒适', ['舒适', '紧凑']),
          _buildSliderSetting('动画水平', 0.8, 0, 1),
          _buildSectionTitle('导航按钮设置'),
          _buildNavigationButtonsEditor(),
          _buildSectionTitle('学习偏好'),
          _buildSwitchSetting('根据使用情况调整', true),
          _buildSwitchSetting('新功能建议', true),
          _buildSwitchSetting('收集反馈', true),
        ],
      ),
    );
  }

  Widget _buildProSettings() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('高级功能'),
          _buildSwitchSetting('实验性工具', true),
          _buildSwitchSetting('API访问', true),
          _buildSwitchSetting('批处理', false),
          _buildSwitchSetting('脚本支持', true),
          _buildSectionTitle('性能设置'),
          _buildDropdownSetting('资源分配', '平衡', ['平衡', '性能', '效率']),
          _buildDropdownSetting('缓存策略', '标准', ['最小', '标准', '激进']),
          _buildSwitchSetting('后台处理', true),
          _buildSliderSetting('多线程级别', 4, 1, 8),
          _buildSectionTitle('专家设置'),
          _buildSwitchSetting('命令行接口', true),
          _buildSwitchSetting('详细日志', false),
          _buildKeyboardShortcutEditor(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _spacing),
        Text(
          title,
          style: _titleStyle,
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: _spacing / 2),
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: widget.mode == AssistantMode.guardian
                ? GuardianTheme.primaryColor
                : widget.mode == AssistantMode.pro
                    ? ProTheme.accentColor
                    : StandardTheme.accentColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(String label, bool value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _spacing / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _bodyStyle,
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // 更新值
            },
            activeColor: widget.mode == AssistantMode.guardian
                ? GuardianTheme.primaryColor
                : widget.mode == AssistantMode.pro
                    ? ProTheme.accentColor
                    : StandardTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _spacing / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _bodyStyle,
          ),
          SizedBox(height: _spacing / 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: (newValue) {
                    // 更新值
                  },
                  activeColor: widget.mode == AssistantMode.guardian
                      ? GuardianTheme.primaryColor
                      : widget.mode == AssistantMode.pro
                          ? ProTheme.accentColor
                          : StandardTheme.accentColor,
                ),
              ),
              SizedBox(width: _spacing / 2),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  value.round().toString(),
                  style: _bodyStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _spacing / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _bodyStyle,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _spacing,
              vertical: _spacing / 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_borderRadius / 2),
            ),
            child: DropdownButton<String>(
              value: value,
              onChanged: (newValue) {
                // 更新值
              },
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: _bodyStyle,
                  ),
                );
              }).toList(),
              underline: Container(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withOpacity(0.7),
              ),
              dropdownColor: Colors.black.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSetting(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _spacing / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _bodyStyle,
          ),
          SizedBox(height: _spacing / 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: _spacing),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_borderRadius / 2),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              obscureText: true,
              style: _bodyStyle,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '输入密码',
                hintStyle: _bodyStyle.copyWith(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardShortcutEditor() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _spacing / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '自定义快捷键',
                  style: _bodyStyle,
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
          SizedBox(height: _spacing / 2),
          Container(
            padding: EdgeInsets.all(_spacing / 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(_borderRadius / 2),
            ),
            child: Column(
              children: [
                _buildShortcutItem('激活助手', 'Ctrl+Alt+A'),
                _buildShortcutItem('语音模式', 'Ctrl+Alt+V'),
                _buildShortcutItem('终止命令', 'Esc'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String action, String shortcut) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _spacing / 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              action,
              style: _bodyStyle,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _spacing / 2,
              vertical: _spacing / 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_borderRadius / 4),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                color: Colors.white,
                fontSize: ProTheme.fontSizeBase * 0.8,
                fontFamily: 'SF Mono',
              ),
            ),
          ),
          SizedBox(width: _spacing / 2),
          Icon(
            Icons.edit,
            color: Colors.white.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtonsEditor() {
    return Consumer(
      builder: (context, ref, child) {
        final customButtons = ref.watch(customNavigationButtonsProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: _spacing / 2),
              child: Text(
                '自定义导航按钮',
                style: _bodyStyle,
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: _spacing),
              padding: EdgeInsets.all(_spacing / 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customButtons.map((button) {
                      return _buildNavigationButtonItem(button, ref);
                    }).toList(),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.only(top: _spacing),
                    child: GestureDetector(
                      onTap: () => _showAddNavigationButtonDialog(context, ref),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: _spacing / 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(_borderRadius / 2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '添加导航按钮',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationButtonItem(NavigationButtonItem button, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_borderRadius / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            button.icon,
            color: Colors.white.withOpacity(0.8),
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            button.label ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final updatedButtons = List<NavigationButtonItem>.from(ref.read(customNavigationButtonsProvider));
              updatedButtons.removeWhere((item) => 
                item.label == button.label && item.route == button.route);
              ref.read(customNavigationButtonsProvider.notifier).state = updatedButtons;
            },
            child: Icon(
              Icons.close,
              color: Colors.white.withOpacity(0.6),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNavigationButtonDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController labelController = TextEditingController();
    final TextEditingController routeController = TextEditingController();
    IconData selectedIcon = Icons.link;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              title: Text(
                '添加导航按钮',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '按钮名称',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_borderRadius / 2),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_borderRadius / 2),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    SizedBox(height: _spacing),
                    
                    TextField(
                      controller: routeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '路由名称',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_borderRadius / 2),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_borderRadius / 2),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    SizedBox(height: _spacing),
                    
                    Text(
                      '选择图标',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: _spacing / 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildIconOption(Icons.home, selectedIcon, setState),
                        _buildIconOption(Icons.code, selectedIcon, setState),
                        _buildIconOption(Icons.settings, selectedIcon, setState),
                        _buildIconOption(Icons.book, selectedIcon, setState),
                        _buildIconOption(Icons.dashboard, selectedIcon, setState),
                        _buildIconOption(Icons.extension, selectedIcon, setState),
                        _buildIconOption(Icons.build, selectedIcon, setState),
                        _buildIconOption(Icons.link, selectedIcon, setState),
                        _buildIconOption(Icons.chat, selectedIcon, setState),
                        _buildIconOption(Icons.person, selectedIcon, setState),
                        _buildIconOption(Icons.folder, selectedIcon, setState),
                        _buildIconOption(Icons.star, selectedIcon, setState),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AIAssistantTheme.getPrimaryColorByMode(widget.mode),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_borderRadius / 2),
                    ),
                  ),
                  onPressed: () {
                    if (labelController.text.isNotEmpty && routeController.text.isNotEmpty) {
                      final newButton = NavigationButtonItem(
                        icon: selectedIcon,
                        label: labelController.text,
                        route: routeController.text,
                        mode: widget.mode,
                      );
                      
                      final updatedButtons = List<NavigationButtonItem>.from(ref.read(customNavigationButtonsProvider));
                      updatedButtons.add(newButton);
                      ref.read(customNavigationButtonsProvider.notifier).state = updatedButtons;
                      
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    '添加',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIconOption(IconData icon, IconData selectedIcon, Function setState) {
    final isSelected = icon == selectedIcon;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIcon = icon;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
              ? AIAssistantTheme.getPrimaryColorByMode(widget.mode).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AIAssistantTheme.getPrimaryColorByMode(widget.mode).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            // 恢复默认
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
          ),
          child: Text(
            '恢复默认',
            style: _bodyStyle,
          ),
        ),
        SizedBox(width: _spacing),
        ElevatedButton(
          onPressed: () {
            // 保存设置
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: widget.mode == AssistantMode.guardian
                ? GuardianTheme.primaryColor
                : widget.mode == AssistantMode.pro
                    ? ProTheme.accentColor
                    : StandardTheme.accentColor,
            padding: EdgeInsets.symmetric(
              horizontal: _spacing * 1.5,
              vertical: _spacing / 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_borderRadius / 2),
            ),
          ),
          child: Text('保存'),
        ),
      ],
    );
  }
}
