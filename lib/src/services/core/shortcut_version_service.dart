import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../state/models/shortcut_config.dart';

/// 快捷键版本
class ShortcutVersion {
  final int version;
  final DateTime timestamp;
  final Map<String, ShortcutConfig> shortcuts;
  final String description;

  const ShortcutVersion({
    required this.version,
    required this.timestamp,
    required this.shortcuts,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      'shortcuts': shortcuts.map((key, value) => MapEntry(
        key,
        value.toJson(),
      )),
      'description': description,
    };
  }

  factory ShortcutVersion.fromJson(Map<String, dynamic> json) {
    final shortcutsJson = json['shortcuts'] as Map<String, dynamic>;
    return ShortcutVersion(
      version: json['version'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      shortcuts: shortcutsJson.map((key, value) => MapEntry(
        key,
        ShortcutConfig.fromJson(value as Map<String, dynamic>),
      )),
      description: json['description'] as String,
    );
  }
}

/// 快捷键版本控制服务
class ShortcutVersionService {
  static const _versionsKey = 'shortcut_versions';
  static const _currentVersionKey = 'current_shortcut_version';
  final SharedPreferences _prefs;

  ShortcutVersionService(this._prefs);

  /// 加载所有版本
  List<ShortcutVersion> loadVersions() {
    final json = _prefs.getString(_versionsKey);
    if (json == null) return [];

    try {
      final List<dynamic> data = jsonDecode(json);
      return data
          .map((item) => ShortcutVersion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有版本
  Future<void> saveVersions(List<ShortcutVersion> versions) async {
    final data = versions.map((version) => version.toJson()).toList();
    await _prefs.setString(_versionsKey, jsonEncode(data));
  }

  /// 获取当前版本号
  int getCurrentVersion() {
    return _prefs.getInt(_currentVersionKey) ?? 0;
  }

  /// 设置当前版本号
  Future<void> setCurrentVersion(int version) async {
    await _prefs.setInt(_currentVersionKey, version);
  }

  /// 创建新版本
  Future<void> createVersion(
    Map<String, ShortcutConfig> shortcuts,
    String description,
  ) async {
    final versions = loadVersions();
    final currentVersion = getCurrentVersion();
    final newVersion = currentVersion + 1;

    final version = ShortcutVersion(
      version: newVersion,
      timestamp: DateTime.now(),
      shortcuts: shortcuts,
      description: description,
    );

    versions.add(version);
    await saveVersions(versions);
    await setCurrentVersion(newVersion);
  }

  /// 切换到指定版本
  Future<Map<String, ShortcutConfig>?> switchToVersion(int version) async {
    final versions = loadVersions();
    final targetVersion = versions.firstWhere(
      (v) => v.version == version,
      orElse: () => throw Exception('找不到指定版本: $version'),
    );

    await setCurrentVersion(version);
    return targetVersion.shortcuts;
  }

  /// 获取版本历史
  List<ShortcutVersion> getHistory() {
    final versions = loadVersions();
    versions.sort((a, b) => b.version.compareTo(a.version));
    return versions;
  }

  /// 清除所有版本
  Future<void> clearVersions() async {
    await _prefs.remove(_versionsKey);
    await _prefs.remove(_currentVersionKey);
  }
}

/// 快捷键版本控制服务提供者
final shortcutVersionProvider = Provider<ShortcutVersionService>((ref) {
  throw UnimplementedError('需要在主程序中提供 SharedPreferences 实例');
}); 