import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app.dart';
import 'src/features/ai_assistant/domain/models/assistant_mode.dart';
import 'src/features/ai_assistant/presentation/widgets/multimodal_controls.dart';
import 'src/features/ai_assistant/presentation/pages/guardian_mode_page.dart';
import 'src/features/ai_assistant/presentation/pages/standard_mode_page.dart';
import 'src/features/ai_assistant/presentation/pages/pro_mode_page.dart';
import 'src/features/ai_assistant/presentation/widgets/assistant_container.dart';
import 'src/core/ai_engine/llm/llm_service_provider.dart';
import 'src/core/ai_engine/llm/llm_config_service.dart';
import 'src/state/providers/shared_preferences_provider.dart';

// 创建一个状态提供者来管理当前加载的AI助手功能
final aiAssistantFeaturesProvider = StateProvider<List<AIAssistantFeature>>((ref) => []);
// 创建一个状态提供者来管理当前选择的AI助手模式
final currentModeProvider = StateProvider<AssistantMode>((ref) => AssistantMode.standard);

// 创建一个状态提供者来管理AI助手的可见性
final assistantVisibilityProvider = StateProvider<bool>((ref) => false);

// 定义AI助手功能枚举
enum AIAssistantFeature {
  basicUI,
  modeSelection,
  guardianMode,
  standardMode,
  proMode,
  voiceControl,
  gestureControl,
  multimodalInteraction,
}

// 获取功能名称
String getFeatureName(AIAssistantFeature feature) {
  switch (feature) {
    case AIAssistantFeature.basicUI:
      return '基础UI';
    case AIAssistantFeature.modeSelection:
      return '模式选择';
    case AIAssistantFeature.guardianMode:
      return '监护模式';
    case AIAssistantFeature.standardMode:
      return '标准模式';
    case AIAssistantFeature.proMode:
      return '专业模式';
    case AIAssistantFeature.voiceControl:
      return '语音控制';
    case AIAssistantFeature.gestureControl:
      return '手势控制';
    case AIAssistantFeature.multimodalInteraction:
      return '多模态交互';
  }
}

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // 创建LLM配置服务
  final llmConfigService = await LLMConfigService.create();

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
        // 覆盖LLM配置服务提供者
        llmConfigServiceProvider.overrideWithValue(llmConfigService),
      ],
      child: const App(),
    ),
  );
}

class IntegratedApp extends ConsumerWidget {
  const IntegratedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'xEwo 集成测试',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const IntegratedHomePage(),
    );
  }
}

class IntegratedHomePage extends ConsumerStatefulWidget {
  const IntegratedHomePage({super.key});

  @override
  ConsumerState<IntegratedHomePage> createState() => _IntegratedHomePageState();
}

class _IntegratedHomePageState extends ConsumerState<IntegratedHomePage> {
  bool _showAIAssistant = false;
  InteractionMode _currentInteractionMode = InteractionMode.text;

  @override
  Widget build(BuildContext context) {
    final loadedFeatures = ref.watch(aiAssistantFeaturesProvider);
    final currentMode = ref.watch(currentModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('xEwo 集成测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Switch(
            value: _showAIAssistant,
            onChanged: (value) {
              setState(() {
                _showAIAssistant = value;
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // 主应用内容
          Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'AI助手功能集成测试',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '已加载功能: ${loadedFeatures.length}/${AIAssistantFeature.values.length}',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: AIAssistantFeature.values.length,
                    itemBuilder: (context, index) {
                      final feature = AIAssistantFeature.values[index];
                      final isLoaded = loadedFeatures.contains(feature);
                      
                      return ListTile(
                        title: Text(getFeatureName(feature)),
                        trailing: isLoaded 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined),
                        onTap: () {
                          _toggleFeature(feature);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _runMainApp,
                  child: const Text('运行主程序'),
                ),
              ],
            ),
          ),
          
          // AI助手覆盖层
          if (_showAIAssistant) _buildAIAssistantOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildAIAssistantOverlay() {
    final loadedFeatures = ref.watch(aiAssistantFeaturesProvider);
    final currentMode = ref.watch(currentModeProvider);
    
    // 如果没有加载任何功能，显示提示
    if (loadedFeatures.isEmpty) {
      return const Center(
        child: Text(
          '请先加载至少一个AI助手功能',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // 根据加载的功能和当前模式构建UI
    if (loadedFeatures.contains(AIAssistantFeature.basicUI)) {
      // 如果加载了特定模式的页面，则显示对应的页面
      if (currentMode == AssistantMode.guardian && loadedFeatures.contains(AIAssistantFeature.guardianMode)) {
        return const Positioned(
          right: 20,
          bottom: 20,
          width: 350,
          height: 500,
          child: GuardianModePage(),
        );
      } else if (currentMode == AssistantMode.standard && loadedFeatures.contains(AIAssistantFeature.standardMode)) {
        return const Positioned(
          right: 20,
          bottom: 20,
          width: 350,
          height: 500,
          child: StandardModePage(),
        );
      } else if (currentMode == AssistantMode.pro && loadedFeatures.contains(AIAssistantFeature.proMode)) {
        return const Positioned(
          right: 20,
          bottom: 20,
          width: 350,
          height: 500,
          child: ProModePage(),
        );
      }
      
      // 如果加载了多模态交互功能，则显示多模态控件
      if (loadedFeatures.contains(AIAssistantFeature.multimodalInteraction)) {
        return Positioned(
          right: 20,
          bottom: 20,
          child: AssistantContainer(
            mode: currentMode,
            width: 300,
            height: 400,
            child: Column(
              children: [
                _buildAssistantHeader(currentMode),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildAssistantContent(loadedFeatures),
                ),
                const SizedBox(height: 16),
                MultimodalControls(
                  currentMode: _currentInteractionMode,
                  onModeChanged: (mode) {
                    setState(() {
                      _currentInteractionMode = mode;
                    });
                  },
                  onSubmit: (text) {
                    print('收到消息: $text');
                  },
                ),
              ],
            ),
          ),
        );
      }
      
      // 默认显示简单的AI助手界面
      return Positioned(
        right: 20,
        bottom: 20,
        child: Container(
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            color: _getModeColor(currentMode).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // 头部
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getModeColor(currentMode).withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getModeColor(currentMode).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI 助手 - ${_getModeText(currentMode)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showAIAssistant = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // 内容区域
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '已加载功能:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: loadedFeatures.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '• ${getFeatureName(loadedFeatures[index])}',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // 如果加载了模式选择功能，显示模式选择器
                      if (loadedFeatures.contains(AIAssistantFeature.modeSelection))
                        _buildModeSelector(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 如果没有加载基础UI，显示简单提示
      return Positioned(
        right: 20,
        bottom: 20,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '请先加载基础UI功能',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }
  
  Widget _buildAssistantHeader(AssistantMode mode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getModeColor(mode).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                mode == AssistantMode.pro ? 'AI+' : 'AI',
                style: TextStyle(
                  fontSize: mode == AssistantMode.pro ? 10 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI 助手 - ${_getModeText(mode)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () {
              setState(() {
                _showAIAssistant = false;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssistantContent(List<AIAssistantFeature> features) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '集成功能演示',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                if (features.contains(AIAssistantFeature.voiceControl))
                  _buildFeatureItem('语音控制', '使用语音与AI助手交互', Icons.mic),
                if (features.contains(AIAssistantFeature.gestureControl))
                  _buildFeatureItem('手势控制', '使用手势与AI助手交互', Icons.gesture),
                _buildFeatureItem('功能列表', '已加载 ${features.length} 个功能', Icons.list),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeSelector() {
    final currentMode = ref.watch(currentModeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择模式:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeButton(
              AssistantMode.guardian,
              '监护',
              Colors.purple,
              currentMode == AssistantMode.guardian,
            ),
            _buildModeButton(
              AssistantMode.standard,
              '标准',
              Colors.blue,
              currentMode == AssistantMode.standard,
            ),
            _buildModeButton(
              AssistantMode.pro,
              '专业',
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
  
  String _getModeText(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.guardian:
        return '监护模式';
      case AssistantMode.pro:
        return '专业模式';
      case AssistantMode.standard:
      default:
        return '标准模式';
    }
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
  
  void _toggleFeature(AIAssistantFeature feature) {
    final currentFeatures = [...ref.read(aiAssistantFeaturesProvider)];
    
    if (currentFeatures.contains(feature)) {
      currentFeatures.remove(feature);
    } else {
      currentFeatures.add(feature);
    }
    
    ref.read(aiAssistantFeaturesProvider.notifier).state = currentFeatures;
  }
  
  void _runMainApp() {
    // 运行主应用程序
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const App(),
      ),
    );
  }
}
