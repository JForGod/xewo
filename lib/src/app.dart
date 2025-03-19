import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'intelligence/global_assistant/providers/global_assistant_provider.dart';
import 'intelligence/global_assistant/services/global_assistant_service.dart';
import 'ui/screens/main_screen.dart';
import 'ui/themes/app_theme.dart';
import 'state/providers/global_providers.dart';
import 'ui/widgets/ai_assistant/ai_assistant_floating_button.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      print('Building App');
    }

    // 初始化全局助手服务
    final globalAssistantService = GlobalAssistantService();

    return GlobalAssistantProvider(
      service: globalAssistantService,
      child: MaterialApp(
        title: 'xEwo',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        navigatorKey: ref.watch(navigatorKeyProvider),
        home: Builder(
          builder: (context) {
            if (kDebugMode) {
              print('Building MainScreen');
            }
            return Stack(
              children: [
                const MainScreen(),
                // 添加AI助手悬浮按钮
                const AIAssistantFloatingButton(),
              ],
            );
          },
        ),
      ),
    );
  }
} 