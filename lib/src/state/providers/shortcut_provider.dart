import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shortcut_model.dart';
import '../../services/core/logger_service.dart';
import '../providers/shared_preferences_provider.dart';

/// 快捷键存储服务
class ShortcutStorageService {
  final SharedPreferences _prefs;
  final LoggerService _logger;
  
  ShortcutStorageService(this._prefs, this._logger);
  
  /// 保存快捷键
  Future<bool> saveShortcuts(List<ShortcutModel> shortcuts) async {
    try {
      final shortcutsJson = shortcuts.map((s) => s.toJson()).toList();
      return await _prefs.setString('shortcuts', shortcutsJson.toString());
    } catch (e) {
      _logger.error('保存快捷键失败', e);
      return false;
    }
  }
  
  /// 加载快捷键
  List<ShortcutModel> loadShortcuts() {
    try {
      final shortcutsJson = _prefs.getString('shortcuts');
      if (shortcutsJson == null) {
        return [];
      }
      
      // 解析JSON
      // 简化实现，实际应该使用json.decode
      return [];
    } catch (e) {
      _logger.error('加载快捷键失败', e);
      return [];
    }
  }
}

/// 快捷键存储服务提供者
final shortcutStorageProvider = Provider<ShortcutStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final logger = ref.watch(loggerServiceProvider);
  return ShortcutStorageService(prefs, logger);
});

/// 快捷键状态
class ShortcutState {
  final List<ShortcutModel> shortcuts;
  final Map<String, SingleActivator> activators;
  
  ShortcutState({
    required this.shortcuts,
    required this.activators,
  });
  
  /// 创建初始状态
  factory ShortcutState.initial() {
    final defaultShortcuts = [
      ShortcutModel(
        id: 'save',
        name: '保存',
        description: '保存当前文件',
        defaultKeys: 'ctrl+s',
        category: ShortcutCategory.file,
      ),
      ShortcutModel(
        id: 'saveAll',
        name: '全部保存',
        description: '保存所有文件',
        defaultKeys: 'ctrl+shift+s',
        category: ShortcutCategory.file,
      ),
      ShortcutModel(
        id: 'find',
        name: '查找',
        description: '在当前文件中查找',
        defaultKeys: 'ctrl+f',
        category: ShortcutCategory.edit,
      ),
      ShortcutModel(
        id: 'replace',
        name: '替换',
        description: '在当前文件中替换',
        defaultKeys: 'ctrl+h',
        category: ShortcutCategory.edit,
      ),
      ShortcutModel(
        id: 'format',
        name: '格式化',
        description: '格式化当前文件',
        defaultKeys: 'ctrl+shift+f',
        category: ShortcutCategory.edit,
      ),
    ];
    
    final activators = <String, SingleActivator>{};
    for (final shortcut in defaultShortcuts) {
      activators[shortcut.id] = _parseShortcut(shortcut.defaultKeys);
    }
    
    return ShortcutState(
      shortcuts: defaultShortcuts,
      activators: activators,
    );
  }
  
  /// 复制并更新
  ShortcutState copyWith({
    List<ShortcutModel>? shortcuts,
    Map<String, SingleActivator>? activators,
  }) {
    return ShortcutState(
      shortcuts: shortcuts ?? this.shortcuts,
      activators: activators ?? this.activators,
    );
  }
}

/// 快捷键通知器
class ShortcutNotifier extends StateNotifier<ShortcutState> {
  final ShortcutStorageService _storage;
  final LoggerService _logger;
  
  ShortcutNotifier(this._storage, this._logger) : super(ShortcutState.initial()) {
    _loadShortcuts();
  }
  
  /// 加载快捷键
  void _loadShortcuts() {
    try {
      final savedShortcuts = _storage.loadShortcuts();
      if (savedShortcuts.isNotEmpty) {
        final activators = <String, SingleActivator>{};
        for (final shortcut in savedShortcuts) {
          activators[shortcut.id] = _parseShortcut(shortcut.customKeys ?? shortcut.defaultKeys);
        }
        
        state = state.copyWith(
          shortcuts: savedShortcuts,
          activators: activators,
        );
      }
    } catch (e) {
      _logger.error('加载快捷键失败', e);
    }
  }
  
  /// 更新快捷键
  Future<bool> updateShortcut(String id, String keys) async {
    try {
      final shortcuts = [...state.shortcuts];
      final index = shortcuts.indexWhere((s) => s.id == id);
      
      if (index == -1) return false;
      
      shortcuts[index] = shortcuts[index].copyWith(customKeys: keys);
      
      final activators = Map<String, SingleActivator>.from(state.activators);
      activators[id] = _parseShortcut(keys);
      
      state = state.copyWith(
        shortcuts: shortcuts,
        activators: activators,
      );
      
      return await _storage.saveShortcuts(shortcuts);
    } catch (e) {
      _logger.error('更新快捷键失败', e);
      return false;
    }
  }
  
  /// 重置快捷键
  Future<bool> resetShortcut(String id) async {
    try {
      final shortcuts = [...state.shortcuts];
      final index = shortcuts.indexWhere((s) => s.id == id);
      
      if (index == -1) return false;
      
      shortcuts[index] = shortcuts[index].copyWith(customKeys: null);
      
      final activators = Map<String, SingleActivator>.from(state.activators);
      activators[id] = _parseShortcut(shortcuts[index].defaultKeys);
      
      state = state.copyWith(
        shortcuts: shortcuts,
        activators: activators,
      );
      
      return await _storage.saveShortcuts(shortcuts);
    } catch (e) {
      _logger.error('重置快捷键失败', e);
      return false;
    }
  }
  
  /// 重置所有快捷键
  Future<bool> resetAllShortcuts() async {
    try {
      final shortcuts = state.shortcuts.map((s) => s.copyWith(customKeys: null)).toList();
      
      final activators = <String, SingleActivator>{};
      for (final shortcut in shortcuts) {
        activators[shortcut.id] = _parseShortcut(shortcut.defaultKeys);
      }
      
      state = state.copyWith(
        shortcuts: shortcuts,
        activators: activators,
      );
      
      return await _storage.saveShortcuts(shortcuts);
    } catch (e) {
      _logger.error('重置所有快捷键失败', e);
      return false;
    }
  }
  
  /// 获取快捷键
  SingleActivator? getShortcut(String id) {
    return state.activators[id];
  }
  
  /// 获取所有快捷键
  Map<String, SingleActivator> getAllShortcuts() {
    return state.activators;
  }
  
  /// 获取特定类别的快捷键
  List<ShortcutModel> getShortcutsByCategory(ShortcutCategory category) {
    return state.shortcuts.where((s) => s.category == category).toList();
  }
}

/// 解析快捷键字符串
SingleActivator _parseShortcut(String keys) {
  final parts = keys.toLowerCase().split('+');
  
  bool ctrl = false;
  bool alt = false;
  bool shift = false;
  bool meta = false;
  
  LogicalKeyboardKey? key;
  
  for (final part in parts) {
    switch (part) {
      case 'ctrl':
        ctrl = true;
        break;
      case 'alt':
        alt = true;
        break;
      case 'shift':
        shift = true;
        break;
      case 'meta':
      case 'cmd':
      case 'win':
        meta = true;
        break;
      default:
        key = _getKeyFromString(part);
        break;
    }
  }
  
  if (key == null) {
    // 默认为A键
    key = LogicalKeyboardKey.keyA;
  }
  
  return SingleActivator(
    key,
    control: ctrl,
    alt: alt,
    shift: shift,
    meta: meta,
  );
}

/// 从字符串获取键
LogicalKeyboardKey _getKeyFromString(String key) {
  switch (key) {
    case 'a': return LogicalKeyboardKey.keyA;
    case 'b': return LogicalKeyboardKey.keyB;
    case 'c': return LogicalKeyboardKey.keyC;
    case 'd': return LogicalKeyboardKey.keyD;
    case 'e': return LogicalKeyboardKey.keyE;
    case 'f': return LogicalKeyboardKey.keyF;
    case 'g': return LogicalKeyboardKey.keyG;
    case 'h': return LogicalKeyboardKey.keyH;
    case 'i': return LogicalKeyboardKey.keyI;
    case 'j': return LogicalKeyboardKey.keyJ;
    case 'k': return LogicalKeyboardKey.keyK;
    case 'l': return LogicalKeyboardKey.keyL;
    case 'm': return LogicalKeyboardKey.keyM;
    case 'n': return LogicalKeyboardKey.keyN;
    case 'o': return LogicalKeyboardKey.keyO;
    case 'p': return LogicalKeyboardKey.keyP;
    case 'q': return LogicalKeyboardKey.keyQ;
    case 'r': return LogicalKeyboardKey.keyR;
    case 's': return LogicalKeyboardKey.keyS;
    case 't': return LogicalKeyboardKey.keyT;
    case 'u': return LogicalKeyboardKey.keyU;
    case 'v': return LogicalKeyboardKey.keyV;
    case 'w': return LogicalKeyboardKey.keyW;
    case 'x': return LogicalKeyboardKey.keyX;
    case 'y': return LogicalKeyboardKey.keyY;
    case 'z': return LogicalKeyboardKey.keyZ;
    case '0': return LogicalKeyboardKey.digit0;
    case '1': return LogicalKeyboardKey.digit1;
    case '2': return LogicalKeyboardKey.digit2;
    case '3': return LogicalKeyboardKey.digit3;
    case '4': return LogicalKeyboardKey.digit4;
    case '5': return LogicalKeyboardKey.digit5;
    case '6': return LogicalKeyboardKey.digit6;
    case '7': return LogicalKeyboardKey.digit7;
    case '8': return LogicalKeyboardKey.digit8;
    case '9': return LogicalKeyboardKey.digit9;
    case 'f1': return LogicalKeyboardKey.f1;
    case 'f2': return LogicalKeyboardKey.f2;
    case 'f3': return LogicalKeyboardKey.f3;
    case 'f4': return LogicalKeyboardKey.f4;
    case 'f5': return LogicalKeyboardKey.f5;
    case 'f6': return LogicalKeyboardKey.f6;
    case 'f7': return LogicalKeyboardKey.f7;
    case 'f8': return LogicalKeyboardKey.f8;
    case 'f9': return LogicalKeyboardKey.f9;
    case 'f10': return LogicalKeyboardKey.f10;
    case 'f11': return LogicalKeyboardKey.f11;
    case 'f12': return LogicalKeyboardKey.f12;
    case 'enter': return LogicalKeyboardKey.enter;
    case 'space': return LogicalKeyboardKey.space;
    case 'tab': return LogicalKeyboardKey.tab;
    case 'esc': return LogicalKeyboardKey.escape;
    case 'escape': return LogicalKeyboardKey.escape;
    case 'backspace': return LogicalKeyboardKey.backspace;
    case 'delete': return LogicalKeyboardKey.delete;
    case 'home': return LogicalKeyboardKey.home;
    case 'end': return LogicalKeyboardKey.end;
    case 'pageup': return LogicalKeyboardKey.pageUp;
    case 'pagedown': return LogicalKeyboardKey.pageDown;
    case 'up': return LogicalKeyboardKey.arrowUp;
    case 'down': return LogicalKeyboardKey.arrowDown;
    case 'left': return LogicalKeyboardKey.arrowLeft;
    case 'right': return LogicalKeyboardKey.arrowRight;
    default: return LogicalKeyboardKey.keyA;
  }
}

/// 快捷键提供者
final shortcutProvider = StateNotifierProvider<ShortcutNotifier, ShortcutState>((ref) {
  final storage = ref.watch(shortcutStorageProvider);
  final logger = ref.watch(loggerServiceProvider);
  return ShortcutNotifier(storage, logger);
}); 