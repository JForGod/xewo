import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

/// 按钮类型
enum CustomButtonType {
  primary,
  secondary,
  outline,
  text,
  danger,
  success,
}

/// 按钮尺寸
enum CustomButtonSize {
  small,
  medium,
  large,
}

/// 自定义按钮
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final CustomButtonSize size;
  final IconData? icon;
  final bool iconRight;
  final bool fullWidth;
  final bool isLoading;
  final bool isDisabled;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  
  /// 构造函数
  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = CustomButtonType.primary,
    this.size = CustomButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.fullWidth = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.borderRadius,
    this.padding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 按钮样式
    final buttonStyle = _getButtonStyle(theme);
    
    // 按钮大小
    final buttonHeight = _getButtonHeight();
    final buttonPadding = padding ?? _getButtonPadding();
    final textStyle = _getTextStyle(theme);
    final iconSize = _getIconSize();
    
    // 根据状态构建子组件
    final child = _buildChild(textStyle, iconSize);
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: buttonStyle,
        child: Padding(
          padding: buttonPadding,
          child: child,
        ),
      ),
    );
  }
  
  /// 构建按钮内容
  Widget _buildChild(TextStyle textStyle, double iconSize) {
    // 加载中状态
    if (isLoading) {
      return SizedBox(
        height: iconSize,
        width: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
        ),
      );
    }
    
    // 仅文本
    if (icon == null) {
      return Text(text, style: textStyle);
    }
    
    // 图标和文本
    final iconWidget = Icon(icon, size: iconSize);
    final textWidget = Text(text, style: textStyle);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: iconRight
          ? [textWidget, SizedBox(width: 8), iconWidget]
          : [iconWidget, SizedBox(width: 8), textWidget],
    );
  }
  
  /// 获取按钮样式
  ButtonStyle _getButtonStyle(ThemeData theme) {
    final effectiveBorderRadius = borderRadius ?? ThemeConstants.borderRadius;
    
    switch (type) {
      case CustomButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.primaryColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
        );
      
      case CustomButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.colorScheme.secondary.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
        );
      
      case CustomButtonType.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.primaryColor,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            side: BorderSide(
              color: isDisabled
                  ? theme.primaryColor.withOpacity(0.5)
                  : theme.primaryColor,
            ),
          ),
        );
      
      case CustomButtonType.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.primaryColor,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
        );
      
      case CustomButtonType.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
        );
      
      case CustomButtonType.success:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.green.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
        );
    }
  }
  
  /// 获取按钮高度
  double _getButtonHeight() {
    switch (size) {
      case CustomButtonSize.small:
        return ThemeConstants.buttonHeightSmall;
      case CustomButtonSize.medium:
        return ThemeConstants.buttonHeight;
      case CustomButtonSize.large:
        return ThemeConstants.buttonHeightLarge;
    }
  }
  
  /// 获取按钮内边距
  EdgeInsetsGeometry _getButtonPadding() {
    switch (size) {
      case CustomButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12);
      case CustomButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 16);
      case CustomButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 24);
    }
  }
  
  /// 获取文本样式
  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case CustomButtonSize.small:
        return TextStyle(
          fontSize: ThemeConstants.fontSizeSmall,
          fontWeight: FontWeight.w500,
        );
      case CustomButtonSize.medium:
        return TextStyle(
          fontSize: ThemeConstants.fontSize,
          fontWeight: FontWeight.w500,
        );
      case CustomButtonSize.large:
        return TextStyle(
          fontSize: ThemeConstants.fontSizeLarge,
          fontWeight: FontWeight.w500,
        );
    }
  }
  
  /// 获取图标尺寸
  double _getIconSize() {
    switch (size) {
      case CustomButtonSize.small:
        return ThemeConstants.iconSizeSmall;
      case CustomButtonSize.medium:
        return ThemeConstants.iconSize;
      case CustomButtonSize.large:
        return ThemeConstants.iconSizeLarge;
    }
  }
  
  /// 获取加载指示器颜色
  Color _getLoadingColor() {
    switch (type) {
      case CustomButtonType.primary:
      case CustomButtonType.secondary:
      case CustomButtonType.danger:
      case CustomButtonType.success:
        return Colors.white;
      case CustomButtonType.outline:
      case CustomButtonType.text:
        return ThemeConstants.primaryColor;
    }
  }
}
