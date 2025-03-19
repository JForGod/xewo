import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assistant_mode.dart';
import '../models/assistant_state.dart';
import '../../../../src/state/providers/shared_preferences_provider.dart';

/// AI助手控制器
class AssistantController extends StateNotifier<AssistantState> {
  final SharedPreferences _prefs;
  
  AssistantController(this._prefs)
      : super(AssistantState(
          mode: AssistantMode.values.byName(
            _prefs.getString('assistant.mode') ?? 'standard',
          ),
          isMinimized: _prefs.getBool('assistant.isMinimized') ?? false,
        ));
  
  /// 切换模式
  void setMode(AssistantMode mode) {
    _prefs.setString('assistant.mode', mode.name);
    state = state.copyWith(mode: mode);
  }
  
  /// 切换最小化状态
  void toggleMinimized() {
    final isMinimized = !state.isMinimized;
    _prefs.setBool('assistant.isMinimized', isMinimized);
    state = state.copyWith(isMinimized: isMinimized);
  }
  
  /// 设置处理状态
  void setProcessing(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing);
  }
  
  /// 设置错误信息
  void setError(String? error) {
    state = state.copyWith(error: error);
  }
  
  /// 更新上下文数据
  void updateContext(Map<String, dynamic> data) {
    state = state.copyWith(
      contextData: {...state.contextData, ...data},
    );
  }
  
  /// 清除上下文数据
  void clearContext() {
    state = state.copyWith(contextData: {});
  }
}

/// AI助手状态提供者
final assistantProvider = StateNotifierProvider<AssistantController, AssistantState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AssistantController(prefs);
}); 