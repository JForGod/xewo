import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// 加载指示器组件
/// 
/// 用于显示加载状态
class LoadingIndicator extends StatelessWidget {
  /// 消息
  final String? message;
  
  /// 指示器大小
  final double size;
  
  /// 指示器颜色
  final Color? color;
  
  /// 指示器线宽
  final double strokeWidth;
  
  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppTheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              message!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 按钮加载指示器
/// 
/// 用于按钮内部的加载状态
class ButtonLoadingIndicator extends StatelessWidget {
  /// 指示器颜色
  final Color? color;
  
  /// 指示器大小
  final double size;
  
  /// 指示器线宽
  final double strokeWidth;
  
  const ButtonLoadingIndicator({
    super.key,
    this.color,
    this.size = 16,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
} 