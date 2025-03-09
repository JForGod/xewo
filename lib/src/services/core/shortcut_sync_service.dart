import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../state/models/shortcut_config.dart';

/// 快捷键同步服务
class ShortcutSyncService {
  final String _baseUrl;
  final String _apiKey;

  ShortcutSyncService({
    required String baseUrl,
    required String apiKey,
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey;

  /// 上传快捷键配置
  Future<void> uploadShortcuts(Map<String, ShortcutConfig> shortcuts) async {
    final data = shortcuts.map((key, value) => MapEntry(
      key,
      value.toJson(),
    ));

    final response = await http.post(
      Uri.parse('$_baseUrl/shortcuts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('上传快捷键配置失败: ${response.statusCode}');
    }
  }

  /// 下载快捷键配置
  Future<Map<String, ShortcutConfig>> downloadShortcuts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/shortcuts'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('下载快捷键配置失败: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return data.map((key, value) => MapEntry(
      key,
      ShortcutConfig.fromJson(value as Map<String, dynamic>),
    ));
  }

  /// 同步快捷键配置
  Future<Map<String, ShortcutConfig>> syncShortcuts(
    Map<String, ShortcutConfig> localShortcuts,
  ) async {
    try {
      final remoteShortcuts = await downloadShortcuts();
      // 合并本地和远程配置，以远程为准
      final mergedShortcuts = {
        ...localShortcuts,
        ...remoteShortcuts,
      };
      await uploadShortcuts(mergedShortcuts);
      return mergedShortcuts;
    } catch (e) {
      // 如果同步失败，返回本地配置
      return localShortcuts;
    }
  }
}

/// 快捷键同步服务提供者
final shortcutSyncProvider = Provider<ShortcutSyncService>((ref) {
  throw UnimplementedError('需要在主程序中提供 baseUrl 和 apiKey');
}); 