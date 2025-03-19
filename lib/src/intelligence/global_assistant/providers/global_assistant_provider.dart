import 'package:flutter/material.dart';
import '../services/global_assistant_service.dart';

/// 全局助手服务提供者
class GlobalAssistantProvider extends InheritedWidget {
  /// 全局助手服务实例
  final GlobalAssistantService service;

  /// 构造函数
  const GlobalAssistantProvider({
    Key? key,
    required this.service,
    required Widget child,
  }) : super(key: key, child: child);

  /// 获取全局助手服务提供者
  static GlobalAssistantProvider of(BuildContext context) {
    final GlobalAssistantProvider? result =
        context.dependOnInheritedWidgetOfExactType<GlobalAssistantProvider>();
    assert(result != null, 'No GlobalAssistantProvider found in context');
    return result!;
  }

  /// 获取全局助手服务
  static GlobalAssistantService getService(BuildContext context) {
    return of(context).service;
  }

  @override
  bool updateShouldNotify(GlobalAssistantProvider oldWidget) {
    return service != oldWidget.service;
  }
} 