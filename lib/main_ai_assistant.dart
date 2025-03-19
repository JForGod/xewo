import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/features/ai_assistant/domain/models/assistant_mode.dart';
import 'src/features/ai_assistant/presentation/pages/guardian_mode_page.dart';
import 'src/features/ai_assistant/presentation/pages/standard_mode_page.dart';
import 'src/features/ai_assistant/presentation/pages/pro_mode_page.dart';
import 'src/features/ai_assistant/presentation/widgets/assistant_container.dart';
import 'src/features/ai_assistant/presentation/widgets/multimodal_controls.dart';
import 'src/intelligence/global_assistant/services/global_assistant_service.dart';
import 'src/intelligence/global_assistant/providers/global_assistant_provider.dart';
import 'src/state/providers/shared_preferences_provider.dart';
import 'src/ui/themes/app_theme.dart';

// 创建一个状态提供者来管理当前选择的AI助手模式
final currentModeProvider = StateProvider<AssistantMode>((ref) => AssistantMode.standard);

// 创建一个状态提供者来管理AI助手的可见性
final assistantVisibilityProvider = StateProvider<bool>((ref) => false);

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 设置错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.toString()}');
      print('Stack trace: ${details.stack}');
    }
  };

  // 设置平台错误处理
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };

  // 运行应用
  runApp(
    ProviderScope(
      overrides: [
        // 覆盖SharedPreferences提供者
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AIAssistantApp(),
    ),
  );
}

class AIAssistantApp extends ConsumerWidget {
  const AIAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化全局助手服务
    final globalAssistantService = GlobalAssistantService();

    return GlobalAssistantProvider(
      service: globalAssistantService,
      child: MaterialApp(
        title: 'xEwo AI助手',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AIAssistantOverlay(),
      ),
    );
  }
}

class AIAssistantOverlay extends ConsumerStatefulWidget {
  const AIAssistantOverlay({super.key});

  @override
  ConsumerState<AIAssistantOverlay> createState() => _AIAssistantOverlayState();
}

class _AIAssistantOverlayState extends ConsumerState<AIAssistantOverlay> {
  InteractionMode _currentInteractionMode = InteractionMode.text;
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(currentModeProvider);
    final isVisible = ref.watch(assistantVisibilityProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'xEwo AI助手',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '点击右下角按钮打开AI助手',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),
                _buildModeSelector(),
              ],
            ),
          ),

          // AI助手覆盖层
          if (isVisible) _buildAIAssistantOverlay(),

          // 悬浮按钮
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () {
                ref.read(assistantVisibilityProvider.notifier).state = !isVisible;
              },
              tooltip: isVisible ? '隐藏AI助手' : '显示AI助手',
              child: Icon(isVisible ? Icons.close : Icons.smart_toy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    final currentMode = ref.watch(currentModeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '选择AI助手模式:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeButton(
              AssistantMode.guardian,
              '监护模式',
              Colors.purple,
              currentMode == AssistantMode.guardian,
            ),
            const SizedBox(width: 16),
            _buildModeButton(
              AssistantMode.standard,
              '标准模式',
              Colors.blue,
              currentMode == AssistantMode.standard,
            ),
            const SizedBox(width: 16),
            _buildModeButton(
              AssistantMode.pro,
              '专业模式',
              Colors.green,
              currentMode == AssistantMode.pro,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton(AssistantMode mode, String label, Color color, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        ref.read(currentModeProvider.notifier).state = mode;
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildAIAssistantOverlay() {
    final currentMode = ref.watch(currentModeProvider);
    
    // 根据当前模式显示对应的页面
    if (_isMinimized) {
      return _buildMinimizedAssistant();
    }
    
    switch (currentMode) {
      case AssistantMode.guardian:
        return const Positioned(
          right: 20,
          bottom: 80,
          width: 380,
          height: 600,
          child: GuardianModePage(),
        );
      case AssistantMode.standard:
        return const Positioned(
          right: 20,
          bottom: 80,
          width: 380,
          height: 600,
          child: StandardModePage(),
        );
      case AssistantMode.pro:
        return const Positioned(
          right: 20,
          bottom: 80,
          width: 380,
          height: 600,
          child: ProModePage(),
        );
      default:
        return const Positioned(
          right: 20,
          bottom: 80,
          width: 380,
          height: 600,
          child: StandardModePage(),
        );
    }
  }

  Widget _buildMinimizedAssistant() {
    return Positioned(
      right: 20,
      bottom: 80,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isMinimized = false;
          });
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getModeColor(ref.watch(currentModeProvider)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.smart_toy,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Color _getModeColor(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.guardian:
        return Colors.purple;
      case AssistantMode.pro:
        return Colors.green;
      case AssistantMode.standard:
      default:
        return Colors.blue;
    }
  }
}
