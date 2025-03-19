import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

/// 卡片类型
enum CustomCardType {
  elevated,
  outline,
  filled,
  transparent,
}

/// 卡片尺寸
enum CustomCardSize {
  small,
  medium,
  large,
}

/// 自定义卡片
class CustomCard extends StatelessWidget {
  final Widget child;
  final CustomCardType type;
  final CustomCardSize size;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  
  /// 构造函数
  const CustomCard({
    Key? key,
    required this.child,
    this.type = CustomCardType.elevated,
    this.size = CustomCardSize.medium,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation,
    this.width,
    this.height,
    this.clipBehavior = Clip.none,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ?? _getPadding();
    final effectiveMargin = margin ?? _getMargin();
    final effectiveBorderRadius = borderRadius ?? _getBorderRadius();
    final effectiveElevation = elevation ?? _getElevation();
    
    // 获取卡片样式
    final CardTheme cardTheme = _getCardTheme(theme, effectiveBorderRadius);
    
    // 获取卡片内容
    final Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );
    
    // 构建卡片
    Widget card = Card(
      elevation: effectiveElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        side: type == CustomCardType.outline
            ? BorderSide(
                color: borderColor ?? theme.dividerColor,
                width: 1.0,
              )
            : BorderSide.none,
      ),
      color: _getBackgroundColor(theme, effectiveBorderRadius),
      child: content,
    );
    
    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    
    return SizedBox(
      width: width,
      height: height,
      child: clipBehavior == Clip.none ? card : ClipRRect(
        clipBehavior: clipBehavior,
        child: card,
      ),
    );
  }
  
  Color _getBackgroundColor(ThemeData theme, double borderRadius) {
    if (type == CustomCardType.filled) {
      return backgroundColor ?? theme.cardColor;
    } else if (type == CustomCardType.transparent) {
      return Colors.transparent;
    } else {
      return Colors.transparent;
    }
  }
  
  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case CustomCardSize.small:
        return EdgeInsets.all(ThemeConstants.paddingSmall);
      case CustomCardSize.medium:
        return EdgeInsets.all(ThemeConstants.paddingMedium);
      case CustomCardSize.large:
        return EdgeInsets.all(ThemeConstants.paddingLarge);
    }
  }
  
  EdgeInsetsGeometry _getMargin() {
    switch (size) {
      case CustomCardSize.small:
        return EdgeInsets.all(ThemeConstants.marginSmall);
      case CustomCardSize.medium:
        return EdgeInsets.all(ThemeConstants.marginMedium);
      case CustomCardSize.large:
        return EdgeInsets.all(ThemeConstants.marginLarge);
    }
  }
  
  double _getBorderRadius() {
    return borderRadius ?? ThemeConstants.borderRadius;
  }
  
  double _getElevation() {
    return elevation ?? ThemeConstants.elevation;
  }
  
  CardTheme _getCardTheme(ThemeData theme, double borderRadius) {
    return CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
