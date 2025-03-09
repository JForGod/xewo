import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/settings/settings_screen.dart';

/// 应用路由配置
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // 主页面路由
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // 设置页面路由
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    
    // 错误页面处理
    errorBuilder: (context, state) => Material(
      child: Center(
        child: Text('页面不存在: ${state.error}'),
      ),
    ),
  );
} 