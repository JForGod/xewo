import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../state/providers/editor_settings_provider.dart';

/// 编辑器设置对话框
class EditorSettingsDialog extends ConsumerWidget {
  const EditorSettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsProvider);
    final notifier = ref.read(editorSettingsProvider.notifier);
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('编辑器设置'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: ListView(
          children: [
            // 字体设置
            _buildSection(
              title: '字体设置',
              children: [
                // 字体选择
                _buildDropdownSetting(
                  context: context,
                  label: '字体',
                  value: settings.fontFamily,
                  items: const [
                    'JetBrains Mono',
                    'Fira Code',
                    'Source Code Pro',
                    'Consolas',
                    'Courier New',
                    'Menlo',
                    'Monaco',
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      notifier.updateFontFamily(value);
                    }
                  },
                ),
                
                // 字体大小
                _buildSliderSetting(
                  context: context,
                  label: '字体大小',
                  value: settings.fontSize,
                  min: 8,
                  max: 32,
                  divisions: 24,
                  onChanged: (value) {
                    notifier.updateFontSize(value);
                  },
                  valueDisplay: '${settings.fontSize.toInt()}px',
                ),
              ],
            ),
            
            const Divider(),
            
            // 编辑器行为
            _buildSection(
              title: '编辑器行为',
              children: [
                // 自动换行
                _buildSwitchSetting(
                  context: context,
                  label: '自动换行',
                  value: settings.wordWrap,
                  onChanged: (value) {
                    notifier.updateWordWrap(value);
                  },
                ),
                
                // 显示行号
                _buildSwitchSetting(
                  context: context,
                  label: '显示行号',
                  value: settings.lineNumbers,
                  onChanged: (value) {
                    notifier.updateLineNumbers(value);
                  },
                ),
                
                // 高亮当前行
                _buildSwitchSetting(
                  context: context,
                  label: '高亮当前行',
                  value: settings.highlightCurrentLine,
                  onChanged: (value) {
                    notifier.updateHighlightCurrentLine(value);
                  },
                ),
                
                // 自动缩进
                _buildSwitchSetting(
                  context: context,
                  label: '自动缩进',
                  value: settings.autoIndent,
                  onChanged: (value) {
                    notifier.updateAutoIndent(value);
                  },
                ),
                
                // 自动闭合括号
                _buildSwitchSetting(
                  context: context,
                  label: '自动闭合括号',
                  value: settings.autoCloseBrackets,
                  onChanged: (value) {
                    notifier.updateAutoCloseBrackets(value);
                  },
                ),
                
                // 自动闭合标签
                _buildSwitchSetting(
                  context: context,
                  label: '自动闭合标签',
                  value: settings.autoCloseTags,
                  onChanged: (value) {
                    notifier.updateAutoCloseTags(value);
                  },
                ),
              ],
            ),
            
            const Divider(),
            
            // 缩进设置
            _buildSection(
              title: '缩进设置',
              children: [
                // 缩进大小
                _buildSliderSetting(
                  context: context,
                  label: '缩进大小',
                  value: settings.indentSize.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  onChanged: (value) {
                    notifier.updateIndentSize(value.toInt());
                  },
                  valueDisplay: '${settings.indentSize} 空格',
                ),
                
                // 使用Tab缩进
                _buildSwitchSetting(
                  context: context,
                  label: '使用Tab缩进',
                  value: settings.useTabs,
                  onChanged: (value) {
                    notifier.updateUseTabs(value);
                  },
                ),
              ],
            ),
            
            const Divider(),
            
            // 视觉效果
            _buildSection(
              title: '视觉效果',
              children: [
                // 显示空白字符
                _buildSwitchSetting(
                  context: context,
                  label: '显示空白字符',
                  value: settings.showWhitespace,
                  onChanged: (value) {
                    notifier.updateShowWhitespace(value);
                  },
                ),
                
                // 显示缩进指南
                _buildSwitchSetting(
                  context: context,
                  label: '显示缩进指南',
                  value: settings.showIndentGuides,
                  onChanged: (value) {
                    notifier.updateShowIndentGuides(value);
                  },
                ),
                
                // 显示小地图
                _buildSwitchSetting(
                  context: context,
                  label: '显示小地图',
                  value: settings.minimap,
                  onChanged: (value) {
                    notifier.updateMinimap(value);
                  },
                ),
                
                // 平滑滚动
                _buildSwitchSetting(
                  context: context,
                  label: '平滑滚动',
                  value: settings.smoothScrolling,
                  onChanged: (value) {
                    notifier.updateSmoothScrolling(value);
                  },
                ),
              ],
            ),
            
            const Divider(),
            
            // 自动保存
            _buildSection(
              title: '自动保存',
              children: [
                // 启用自动保存
                _buildSwitchSetting(
                  context: context,
                  label: '启用自动保存',
                  value: settings.autoSave,
                  onChanged: (value) {
                    notifier.updateAutoSave(value);
                  },
                ),
                
                // 自动保存间隔
                if (settings.autoSave)
                  _buildSliderSetting(
                    context: context,
                    label: '自动保存间隔',
                    value: settings.autoSaveInterval.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    onChanged: (value) {
                      notifier.updateAutoSaveInterval(value.toInt());
                    },
                    valueDisplay: '${settings.autoSaveInterval} 秒',
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
  
  // 构建设置分组
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  
  // 构建开关设置项
  Widget _buildSwitchSetting({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
  
  // 构建滑块设置项
  Widget _buildSliderSetting({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueDisplay,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label),
              ),
              Text(
                valueDisplay,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
  
  // 构建下拉设置项
  Widget _buildDropdownSetting<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          DropdownButton<T>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
} 