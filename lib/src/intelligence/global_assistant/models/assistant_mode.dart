/// AI助手模式
enum AssistantMode {
  /// 标准模式：基础的代码补全和提示
  standard,
  
  /// 专业模式：高级的代码分析和重构建议
  professional,
  
  /// 监护模式：适合初学者的引导和教学
  guardian,
}

/// AI助手模式扩展
extension AssistantModeExtension on AssistantMode {
  /// 获取模式名称
  String get name {
    switch (this) {
      case AssistantMode.standard:
        return '标准模式';
      case AssistantMode.professional:
        return '专业模式';
      case AssistantMode.guardian:
        return '监护模式';
    }
  }
  
  /// 获取模式描述
  String get description {
    switch (this) {
      case AssistantMode.standard:
        return '提供基础的代码补全和智能提示';
      case AssistantMode.professional:
        return '提供高级的代码分析和重构建议';
      case AssistantMode.guardian:
        return '提供适合初学者的引导和教学';
    }
  }
  
  /// 获取模式图标
  String get icon {
    switch (this) {
      case AssistantMode.standard:
        return 'assets/icons/mode_standard.png';
      case AssistantMode.professional:
        return 'assets/icons/mode_professional.png';
      case AssistantMode.guardian:
        return 'assets/icons/mode_guardian.png';
    }
  }
} 