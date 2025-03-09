import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

/// 搜索历史状态
class SearchHistoryState {
  final List<String> history;
  final int maxHistoryItems;

  const SearchHistoryState({
    this.history = const [],
    this.maxHistoryItems = 20,
  });

  SearchHistoryState copyWith({
    List<String>? history,
    int? maxHistoryItems,
  }) {
    return SearchHistoryState(
      history: history ?? this.history,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
    );
  }
}

/// 搜索历史状态管理
class SearchHistoryNotifier extends StateNotifier<SearchHistoryState> {
  final SharedPreferences _prefs;
  static const String _prefsKey = 'search_history';

  SearchHistoryNotifier(this._prefs) : super(const SearchHistoryState()) {
    _loadHistory();
  }

  // 加载搜索历史
  void _loadHistory() {
    final historyJson = _prefs.getStringList(_prefsKey) ?? [];
    state = state.copyWith(history: historyJson);
  }

  // 保存搜索历史
  Future<void> _saveHistory() async {
    await _prefs.setStringList(_prefsKey, state.history);
  }

  // 添加搜索历史
  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    // 如果已存在，先移除
    final history = List<String>.from(state.history);
    history.remove(query);
    
    // 添加到最前面
    history.insert(0, query);
    
    // 限制历史记录数量
    if (history.length > state.maxHistoryItems) {
      history.removeLast();
    }
    
    state = state.copyWith(history: history);
    await _saveHistory();
  }

  // 清除搜索历史
  Future<void> clearHistory() async {
    state = state.copyWith(history: []);
    await _saveHistory();
  }

  // 删除单个搜索历史
  Future<void> removeSearch(String query) async {
    final history = List<String>.from(state.history);
    history.remove(query);
    
    state = state.copyWith(history: history);
    await _saveHistory();
  }
  
  // 设置最大历史记录数量
  Future<void> setMaxHistoryItems(int maxItems) async {
    if (maxItems < 1) return;
    
    state = state.copyWith(maxHistoryItems: maxItems);
    
    // 如果当前历史记录超过新的最大值，裁剪历史记录
    if (state.history.length > maxItems) {
      final history = state.history.sublist(0, maxItems);
      state = state.copyWith(history: history);
      await _saveHistory();
    }
  }
  
  // 获取搜索建议
  List<String> getSuggestions(String query) {
    if (query.trim().isEmpty) {
      return state.history;
    }
    
    // 过滤出包含查询字符串的历史记录
    return state.history
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

/// 搜索历史提供者
final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, SearchHistoryState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchHistoryNotifier(prefs);
}); 