import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});

class AppConfig {
  final String? lastOpenDirectory;
  final List<String> recentFiles;
  final Map<String, dynamic> editorSettings;
  
  AppConfig({
    this.lastOpenDirectory,
    List<String>? recentFiles,
    Map<String, dynamic>? editorSettings,
  }) : recentFiles = recentFiles ?? [],
       editorSettings = editorSettings ?? {};
  
  AppConfig copyWith({
    String? lastOpenDirectory,
    List<String>? recentFiles,
    Map<String, dynamic>? editorSettings,
  }) {
    return AppConfig(
      lastOpenDirectory: lastOpenDirectory ?? this.lastOpenDirectory,
      recentFiles: recentFiles ?? this.recentFiles,
      editorSettings: editorSettings ?? this.editorSettings,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'lastOpenDirectory': lastOpenDirectory,
      'recentFiles': recentFiles,
      'editorSettings': editorSettings,
    };
  }
  
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      lastOpenDirectory: json['lastOpenDirectory'] as String?,
      recentFiles: List<String>.from(json['recentFiles'] ?? []),
      editorSettings: Map<String, dynamic>.from(json['editorSettings'] ?? {}),
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(AppConfig()) {
    _loadConfig();
  }
  
  Future<void> _loadConfig() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/app_config.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AppConfig.fromJson(json);
      }
    } catch (e) {
      print('Error loading config: $e');
    }
  }
  
  Future<void> saveConfig() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/app_config.json');
      
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (e) {
      print('Error saving config: $e');
    }
  }
  
  void updateLastOpenDirectory(String path) {
    state = state.copyWith(lastOpenDirectory: path);
    saveConfig();
  }
  
  void addRecentFile(String path) {
    final recentFiles = List<String>.from(state.recentFiles);
    if (!recentFiles.contains(path)) {
      recentFiles.insert(0, path);
      if (recentFiles.length > 10) {
        recentFiles.removeLast();
      }
      state = state.copyWith(recentFiles: recentFiles);
      saveConfig();
    }
  }
  
  void updateEditorSettings(String key, dynamic value) {
    final settings = Map<String, dynamic>.from(state.editorSettings);
    settings[key] = value;
    state = state.copyWith(editorSettings: settings);
    saveConfig();
  }
} 