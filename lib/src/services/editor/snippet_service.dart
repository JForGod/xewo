import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences.dart';

/// 代码片段模型
class CodeSnippet {
  final String id;
  final String name;
  final String description;
  final String code;
  final String language;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CodeSnippet({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.language,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'code': code,
    'language': language,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CodeSnippet.fromJson(Map<String, dynamic> json) => CodeSnippet(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    code: json['code'] as String,
    language: json['language'] as String,
    tags: (json['tags'] as List).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// 代码片段服务
class SnippetService {
  final SharedPreferences _prefs;
  static const String _snippetsKey = 'code_snippets';

  SnippetService(this._prefs);

  /// 获取所有代码片段
  List<CodeSnippet> getAllSnippets() {
    final jsonStr = _prefs.getString(_snippetsKey);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList.map((json) => CodeSnippet.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading snippets: $e');
      return [];
    }
  }

  /// 按语言获取代码片段
  List<CodeSnippet> getSnippetsByLanguage(String language) {
    return getAllSnippets()
        .where((snippet) => snippet.language == language)
        .toList();
  }

  /// 按标签搜索代码片段
  List<CodeSnippet> searchSnippetsByTags(List<String> tags) {
    return getAllSnippets()
        .where((snippet) => 
            tags.every((tag) => snippet.tags.contains(tag)))
        .toList();
  }

  /// 添加代码片段
  Future<void> addSnippet(CodeSnippet snippet) async {
    final snippets = getAllSnippets();
    snippets.add(snippet);
    await _saveSnippets(snippets);
  }

  /// 更新代码片段
  Future<void> updateSnippet(CodeSnippet snippet) async {
    final snippets = getAllSnippets();
    final index = snippets.indexWhere((s) => s.id == snippet.id);
    if (index != -1) {
      snippets[index] = snippet;
      await _saveSnippets(snippets);
    }
  }

  /// 删除代码片段
  Future<void> deleteSnippet(String id) async {
    final snippets = getAllSnippets();
    snippets.removeWhere((s) => s.id == id);
    await _saveSnippets(snippets);
  }

  /// 保存代码片段列表
  Future<void> _saveSnippets(List<CodeSnippet> snippets) async {
    final jsonList = snippets.map((s) => s.toJson()).toList();
    await _prefs.setString(_snippetsKey, json.encode(jsonList));
  }
}

/// 代码片段服务提供者
final snippetServiceProvider = Provider<SnippetService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SnippetService(prefs);
}); 