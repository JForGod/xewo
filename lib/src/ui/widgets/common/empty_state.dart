import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 空状态组件
/// 
/// 用于显示列表或页面为空时的状态
class EmptyState extends StatelessWidget {
  /// 图标
  final IconData icon;
  
  /// 标题
  final String title;
  
  /// 消息
  final String message;
  
  /// 操作按钮
  final Widget? action;
  
  /// 图标大小
  final double iconSize;
  
  /// 图标颜色
  final Color? iconColor;
  
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppTheme.neutral400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.neutral800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
} 