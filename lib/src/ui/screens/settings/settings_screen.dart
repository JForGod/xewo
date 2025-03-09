import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';
import '../../widgets/editor/dialogs/editor_settings_dialog.dart';
import '../../widgets/editor/dialogs/shortcut_settings_dialog.dart';

/// 设置项类型
enum SettingType {
  toggle,
  select,
  input,
  button,
  color,
}

/// 设置项
class SettingItem {
  final String id;
  final String title;
  final String? description;
  final SettingType type;
  final dynamic value;
  final List<dynamic>? options;
  final IconData? icon;
  
  const SettingItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.value,
    this.options,
    this.icon,
  });
}

/// 设置分组
class SettingGroup {
  final String title;
  final List<SettingItem> settings;
  
  const SettingGroup({
    required this.title,
    required this.settings,
  });
}

/// 设置屏幕
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final List<SettingGroup> _settingGroups = [
    const SettingGroup(
      title: '常规',
      settings: [
        SettingItem(
          id: 'theme',
          title: '主题',
          description: '选择应用主题',
          type: SettingType.select,
          value: '深色',
          options: ['浅色', '深色', '跟随系统'],
          icon: Icons.palette,
        ),
        SettingItem(
          id: 'font_size',
          title: '字体大小',
          description: '调整应用字体大小',
          type: SettingType.select,
          value: '中',
          options: ['小', '中', '大'],
          icon: Icons.format_size,
        ),
        SettingItem(
          id: 'auto_save',
          title: '自动保存',
          description: '自动保存编辑内容',
          type: SettingType.toggle,
          value: true,
          icon: Icons.save,
        ),
      ],
    ),
    const SettingGroup(
      title: '编辑器',
      settings: [
        SettingItem(
          id: 'word_wrap',
          title: '自动换行',
          description: '启用编辑器自动换行',
          type: SettingType.toggle,
          value: true,
          icon: Icons.wrap_text,
        ),
        SettingItem(
          id: 'line_numbers',
          title: '显示行号',
          description: '在编辑器中显示行号',
          type: SettingType.toggle,
          value: true,
          icon: Icons.format_list_numbered,
        ),
        SettingItem(
          id: 'tab_size',
          title: 'Tab大小',
          description: '设置Tab键的空格数',
          type: SettingType.select,
          value: '4',
          options: ['2', '4', '8'],
          icon: Icons.space_bar,
        ),
        SettingItem(
          id: 'editor_font',
          title: '编辑器字体',
          description: '选择编辑器字体',
          type: SettingType.select,
          value: 'Consolas',
          options: ['Consolas', 'Fira Code', 'JetBrains Mono', 'Source Code Pro'],
          icon: Icons.font_download,
        ),
      ],
    ),
    const SettingGroup(
      title: '数据库',
      settings: [
        SettingItem(
          id: 'connection_timeout',
          title: '连接超时',
          description: '设置数据库连接超时时间（秒）',
          type: SettingType.input,
          value: '30',
          icon: Icons.timer,
        ),
        SettingItem(
          id: 'query_limit',
          title: '查询限制',
          description: '设置默认查询结果限制',
          type: SettingType.input,
          value: '1000',
          icon: Icons.filter_list,
        ),
      ],
    ),
    const SettingGroup(
      title: '高级',
      settings: [
        SettingItem(
          id: 'clear_cache',
          title: '清除缓存',
          description: '清除应用缓存数据',
          type: SettingType.button,
          value: '清除',
          icon: Icons.cleaning_services,
        ),
        SettingItem(
          id: 'export_settings',
          title: '导出设置',
          description: '导出应用设置',
          type: SettingType.button,
          value: '导出',
          icon: Icons.upload_file,
        ),
        SettingItem(
          id: 'import_settings',
          title: '导入设置',
          description: '导入应用设置',
          type: SettingType.button,
          value: '导入',
          icon: Icons.download,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: _settingGroups.length,
        itemBuilder: (context, groupIndex) {
          final group = _settingGroups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSm,
                  horizontal: AppTheme.spacingMd,
                ),
                child: Text(
                  group.title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.settings.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final setting = group.settings[index];
                    return _buildSettingItem(setting);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSettingItem(SettingItem setting) {
    switch (setting.type) {
      case SettingType.toggle:
        return _buildToggleSetting(setting);
      case SettingType.select:
        // 确保选项列表是List<String>类型
        final options = (setting.options as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        return _buildSelectSetting(setting, options);
      case SettingType.input:
        return _buildInputSetting(setting);
      case SettingType.button:
        return _buildButtonSetting(setting);
      case SettingType.color:
        return _buildColorSetting(setting);
      default:
        return Container();
    }
  }

  Widget _buildToggleSetting(SettingItem setting) {
    return ListTile(
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(setting.title),
      subtitle: setting.description != null ? Text(setting.description!) : null,
      trailing: Switch(
        value: setting.value as bool,
        onChanged: (value) {
          // TODO: 更新设置值
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${setting.title}设置更新功能开发中')),
          );
        },
      ),
      onTap: setting.type == SettingType.button
          ? null
          : () {
              // TODO: 打开设置详情页
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${setting.title}设置详情页开发中')),
              );
            },
    );
  }

  Widget _buildSelectSetting(SettingItem setting, List<String> options) {
    return ListTile(
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(setting.title),
      subtitle: setting.description != null ? Text(setting.description!) : null,
      trailing: DropdownButton<String>(
        value: setting.value as String,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          // TODO: 更新设置值
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${setting.title}设置更新功能开发中')),
          );
        },
      ),
      onTap: setting.type == SettingType.button
          ? null
          : () {
              // TODO: 打开设置详情页
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${setting.title}设置详情页开发中')),
              );
            },
    );
  }

  Widget _buildInputSetting(SettingItem setting) {
    return ListTile(
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(setting.title),
      subtitle: setting.description != null ? Text(setting.description!) : null,
      trailing: Container(
        width: 100,
        constraints: const BoxConstraints(
          maxWidth: 100,
        ),
        child: TextField(
          controller: TextEditingController(text: setting.value as String),
          textAlign: TextAlign.end,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          maxLines: 1,
          onSubmitted: (value) {
            // TODO: 更新设置值
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${setting.title}设置更新功能开发中')),
            );
          },
        ),
      ),
      onTap: setting.type == SettingType.button
          ? null
          : () {
              // TODO: 打开设置详情页
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${setting.title}设置详情页开发中')),
              );
            },
    );
  }

  Widget _buildButtonSetting(SettingItem setting) {
    return ListTile(
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(setting.title),
      subtitle: setting.description != null ? Text(setting.description!) : null,
      trailing: TextButton(
        child: Text(setting.value as String),
        onPressed: () {
          // TODO: 执行按钮操作
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${setting.title}功能开发中')),
          );
        },
      ),
      onTap: setting.type == SettingType.button
          ? null
          : () {
              // TODO: 打开设置详情页
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${setting.title}设置详情页开发中')),
              );
            },
    );
  }

  Widget _buildColorSetting(SettingItem setting) {
    return ListTile(
      leading: setting.icon != null ? Icon(setting.icon) : null,
      title: Text(setting.title),
      subtitle: setting.description != null ? Text(setting.description!) : null,
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: setting.value as Color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onTap: setting.type == SettingType.button
          ? null
          : () {
              // TODO: 打开设置详情页
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${setting.title}设置详情页开发中')),
              );
            },
    );
  }
} 