// 2025-03-20: 新增 - Gemini模型定义

/// Gemini模型变体
enum GeminiModel {
  /// Gemini 2.0 Flash - 最新的多模态模型
  gemini2Flash('gemini-2.0-flash', '新一代功能、速度、思考、实时串流和多模式生成'),
  
  /// Gemini 2.0 Flash-Lite - 优化的轻量版本
  gemini2FlashLite('gemini-2.0-flash-lite', '针对性价比和低延迟时间进行了优化'),
  
  /// Gemini 2.0 Pro 实验版 - 最强大的2.0模型
  gemini2ProExp('gemini-2.0-pro-exp-02-05', '最强大的 Gemini 2.0 模型'),
  
  /// Gemini 1.5 Flash - 平衡的多模态模型
  gemini15Flash('gemini-1.5-flash', '在各种任务中提供快速、多样化的性能'),
  
  /// Gemini 1.5 Flash-8B - 轻量级模型
  gemini15Flash8B('gemini-1.5-flash-8b', '量大且智能程度较低的任务'),
  
  /// Gemini 1.5 Pro - 复杂任务模型
  gemini15Pro('gemini-1.5-pro', '需要更高智能的复杂推理任务'),
  
  /// Gemini 嵌入 - 文本嵌入模型
  geminiEmbedding('gemini-embedding-exp', '衡量文本字符串的相关性'),
  
  /// Imagen 3 - 图像生成模型
  imagen3('imagen-3.0-generate-002', '最先进的图片生成模型');

  /// 构造函数
  const GeminiModel(this.modelId, this.description);
  
  /// 模型ID
  final String modelId;
  
  /// 模型描述
  final String description;
  
  /// 获取所有可用的模型ID
  static List<String> get allModelIds => GeminiModel.values.map((e) => e.modelId).toList();
  
  /// 获取所有模型的描述映射
  static Map<String, String> get modelDescriptions => 
    Map.fromEntries(GeminiModel.values.map((e) => MapEntry(e.modelId, e.description)));
  
  /// 根据模型ID获取模型
  static GeminiModel? fromModelId(String modelId) =>
    GeminiModel.values.firstWhere(
      (e) => e.modelId == modelId,
      orElse: () => gemini15Pro, // 默认使用 1.5 Pro
    );
  
  /// 获取模型的输入类型
  List<String> get supportedInputTypes {
    switch (this) {
      case GeminiModel.imagen3:
        return ['text'];
      case GeminiModel.geminiEmbedding:
        return ['text'];
      default:
        return ['audio', 'image', 'video', 'text'];
    }
  }
  
  /// 获取模型的输出类型
  List<String> get supportedOutputTypes {
    switch (this) {
      case GeminiModel.imagen3:
        return ['image'];
      case GeminiModel.geminiEmbedding:
        return ['text_embedding'];
      case GeminiModel.gemini2Flash:
        return ['text', 'image', 'audio'];
      default:
        return ['text'];
    }
  }
  
  /// 检查模型是否支持特定的输入类型
  bool supportsInputType(String inputType) => supportedInputTypes.contains(inputType);
  
  /// 检查模型是否支持特定的输出类型
  bool supportsOutputType(String outputType) => supportedOutputTypes.contains(outputType);
  
  /// 获取模型的最大上下文窗口大小
  int get maxContextWindow {
    switch (this) {
      case GeminiModel.gemini2FlashLite:
        return 1000000; // 100万tokens
      case GeminiModel.gemini2Flash:
      case GeminiModel.gemini2ProExp:
        return 128000;
      case GeminiModel.gemini15Flash:
      case GeminiModel.gemini15Pro:
        return 64000;
      case GeminiModel.gemini15Flash8B:
        return 32000;
      default:
        return 8192;
    }
  }
  
  /// 获取模型是否为实验性质
  bool get isExperimental {
    switch (this) {
      case GeminiModel.gemini2ProExp:
      case GeminiModel.geminiEmbedding:
        return true;
      default:
        return false;
    }
  }
  
  /// 获取模型的建议用途
  String get recommendedUse {
    switch (this) {
      case GeminiModel.gemini2Flash:
        return '适用于需要最新功能和高性能的场景';
      case GeminiModel.gemini2FlashLite:
        return '适用于需要大规模处理且对延迟敏感的场景';
      case GeminiModel.gemini2ProExp:
        return '适用于需要最强大AI能力的场景';
      case GeminiModel.gemini15Flash:
        return '适用于需要平衡性能和多样性的一般场景';
      case GeminiModel.gemini15Flash8B:
        return '适用于简单的大规模处理场景';
      case GeminiModel.gemini15Pro:
        return '适用于复杂的推理和分析场景';
      case GeminiModel.geminiEmbedding:
        return '适用于文本相似度分析和检索场景';
      case GeminiModel.imagen3:
        return '适用于高质量图像生成场景';
    }
  }
} 