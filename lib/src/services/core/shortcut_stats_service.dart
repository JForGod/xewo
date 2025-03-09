import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 快捷键使用统计
class ShortcutStats {
  final String id;
  final int useCount;
  final DateTime lastUsed;

  const ShortcutStats({
    required this.id,
    required this.useCount,
    required this.lastUsed,
  });

  ShortcutStats copyWith({
    String? id,
    int? useCount,
    DateTime? lastUsed,
  }) {
    return ShortcutStats(
      id: id ?? this.id,
      useCount: useCount ?? this.useCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'useCount': useCount,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory ShortcutStats.fromJson(Map<String, dynamic> json) {
    return ShortcutStats(
      id: json['id'] as String,
      useCount: json['useCount'] as int,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }
}

/// 快捷键统计服务
class ShortcutStatsService {
  static const _statsKey = 'shortcut_stats';
  final SharedPreferences _prefs;

  ShortcutStatsService(this._prefs);

  /// 加载统计数据
  Map<String, ShortcutStats> loadStats() {
    final json = _prefs.getString(_statsKey);
    if (json == null) return {};

    try {
      final Map<String, dynamic> data = jsonDecode(json);
      return data.map((key, value) => MapEntry(
        key,
        ShortcutStats.fromJson(value as Map<String, dynamic>),
      ));
    } catch (e) {
      return {};
    }
  }

  /// 保存统计数据
  Future<void> saveStats(Map<String, ShortcutStats> stats) async {
    final data = stats.map((key, value) => MapEntry(
      key,
      value.toJson(),
    ));
    await _prefs.setString(_statsKey, jsonEncode(data));
  }

  /// 记录快捷键使用
  Future<void> recordUsage(String id) async {
    final stats = loadStats();
    final currentStats = stats[id];
    final updatedStats = currentStats == null
        ? ShortcutStats(
            id: id,
            useCount: 1,
            lastUsed: DateTime.now(),
          )
        : currentStats.copyWith(
            useCount: currentStats.useCount + 1,
            lastUsed: DateTime.now(),
          );
    stats[id] = updatedStats;
    await saveStats(stats);
  }

  /// 获取使用次数最多的快捷键
  List<ShortcutStats> getMostUsedShortcuts({int limit = 10}) {
    final stats = loadStats().values.toList()
      ..sort((a, b) => b.useCount.compareTo(a.useCount));
    return stats.take(limit).toList();
  }

  /// 获取最近使用的快捷键
  List<ShortcutStats> getRecentlyUsedShortcuts({int limit = 10}) {
    final stats = loadStats().values.toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return stats.take(limit).toList();
  }

  /// 清除统计数据
  Future<void> clearStats() async {
    await _prefs.remove(_statsKey);
  }
}

/// 快捷键统计服务提供者
final shortcutStatsProvider = Provider<ShortcutStatsService>((ref) {
  throw UnimplementedError('需要在主程序中提供 SharedPreferences 实例');
}); 