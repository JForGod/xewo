import 'package:flutter/material.dart';
import 'dart:ui';
import '../themes/app_theme.dart';
import '../themes/guardian_theme.dart';
import '../themes/standard_theme.dart';
import '../themes/pro_theme.dart';
import '../../domain/models/assistant_mode.dart';

class AssistantContainer extends StatelessWidget {
  final Widget child;
  final AssistantMode mode;
  final EdgeInsetsGeometry? padding;
  final bool useGlass;
  final double? width;
  final double? height;

  const AssistantContainer({
    Key? key,
    required this.child,
    this.mode = AssistantMode.standard,
    this.padding,
    this.useGlass = true,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = _getThemeDataByMode();
    
    return Container(
      width: width,
      height: height,
      decoration: _getContainerDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          _getBorderRadiusByMode(),
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 检查平台是否支持BackdropFilter
    final canUseBackdropFilter = useGlass && 
        Theme.of(context).platform != TargetPlatform.linux && 
        Theme.of(context).platform != TargetPlatform.fuchsia;
    
    if (canUseBackdropFilter) {
      try {
        return Stack(
          children: [
            // 背景模糊层
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // 内容层
            Padding(
              padding: padding ?? EdgeInsets.all(_getSpacingByMode()),
              child: Material(
                type: MaterialType.transparency,
                child: child,
              ),
            ),
            // 边缘光效
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ],
        );
      } catch (e) {
        // 如果BackdropFilter失败，回退到普通容器
        return Padding(
          padding: padding ?? EdgeInsets.all(_getSpacingByMode()),
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
        );
      }
    } else {
      // 不使用BackdropFilter的情况
      return Padding(
        padding: padding ?? EdgeInsets.all(_getSpacingByMode()),
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      );
    }
  }

  BoxDecoration _getContainerDecoration() {
    final baseDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(_getBorderRadiusByMode()),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: _getPrimaryColorByMode().withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    );
    
    switch (mode) {
      case AssistantMode.guardian:
        return baseDecoration.copyWith(
          color: GuardianTheme.backgroundColor.withOpacity(0.15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GuardianTheme.primaryColor.withOpacity(0.2),
              GuardianTheme.backgroundColor.withOpacity(0.15),
            ],
          ),
        );
      case AssistantMode.pro:
        return baseDecoration.copyWith(
          color: ProTheme.backgroundColor.withOpacity(0.15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ProTheme.primaryColor.withOpacity(0.2),
              ProTheme.backgroundColor.withOpacity(0.15),
            ],
          ),
        );
      case AssistantMode.standard:
      default:
        return baseDecoration.copyWith(
          color: StandardTheme.backgroundColor.withOpacity(0.15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              StandardTheme.primaryColor.withOpacity(0.2),
              StandardTheme.backgroundColor.withOpacity(0.15),
            ],
          ),
        );
    }
  }

  Color _getPrimaryColorByMode() {
    switch (mode) {
      case AssistantMode.guardian:
        return GuardianTheme.primaryColor;
      case AssistantMode.pro:
        return ProTheme.primaryColor;
      case AssistantMode.standard:
      default:
        return StandardTheme.primaryColor;
    }
  }

  double _getBorderRadiusByMode() {
    switch (mode) {
      case AssistantMode.guardian:
        return GuardianTheme.borderRadius;
      case AssistantMode.pro:
        return ProTheme.borderRadius;
      case AssistantMode.standard:
      default:
        return StandardTheme.borderRadius;
    }
  }

  double _getSpacingByMode() {
    switch (mode) {
      case AssistantMode.guardian:
        return GuardianTheme.spacingUnit;
      case AssistantMode.pro:
        return ProTheme.spacingUnit;
      case AssistantMode.standard:
      default:
        return StandardTheme.spacingUnit;
    }
  }

  ThemeData _getThemeDataByMode() {
    switch (mode) {
      case AssistantMode.guardian:
        return ThemeData(
          primaryColor: GuardianTheme.primaryColor,
          colorScheme: const ColorScheme.dark(
            primary: GuardianTheme.primaryColor,
            secondary: GuardianTheme.secondaryColor,
            surface: GuardianTheme.surfaceColor,
            background: GuardianTheme.backgroundColor,
          ),
          textTheme: TextTheme(
            titleLarge: GuardianTheme.headingStyle,
            bodyMedium: GuardianTheme.bodyStyle,
            bodySmall: GuardianTheme.captionStyle,
          ),
        );
      case AssistantMode.pro:
        return ThemeData(
          primaryColor: ProTheme.primaryColor,
          colorScheme: const ColorScheme.dark(
            primary: ProTheme.primaryColor,
            secondary: ProTheme.accentColor,
            surface: ProTheme.surfaceColor,
            background: ProTheme.backgroundColor,
          ),
          textTheme: TextTheme(
            titleLarge: ProTheme.headingStyle,
            bodyMedium: ProTheme.bodyStyle,
            bodySmall: ProTheme.captionStyle,
          ),
        );
      case AssistantMode.standard:
      default:
        return ThemeData(
          primaryColor: StandardTheme.primaryColor,
          colorScheme: const ColorScheme.dark(
            primary: StandardTheme.primaryColor,
            secondary: StandardTheme.accentColor,
            surface: StandardTheme.surfaceColor,
            background: StandardTheme.backgroundColor,
          ),
          textTheme: TextTheme(
            titleLarge: StandardTheme.headingStyle,
            bodyMedium: StandardTheme.bodyStyle,
            bodySmall: StandardTheme.captionStyle,
          ),
        );
    }
  }
}
