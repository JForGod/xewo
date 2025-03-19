/// 本地模型配置类
/// 
/// 管理本地大语言模型的配置参数
class LocalConfig {
  /// 模型路径
  String modelPath;
  
  /// 模型名称
  String modelName;
  
  /// 量化类型（如GGML、GGUF等）
  String quantizationType;
  
  /// 上下文窗口大小
  int contextWindow;
  
  /// 线程数
  int numThreads;
  
  /// 使用GPU
  bool useGpu;
  
  /// GPU层数
  int gpuLayers;
  
  /// 批处理大小
  int batchSize;
  
  /// 温度
  double temperature;
  
  /// 重复惩罚
  double repetitionPenalty;
  
  /// 构造函数
  LocalConfig({
    required this.modelPath,
    this.modelName = 'localllm',
    this.quantizationType = 'gguf',
    this.contextWindow = 4096,
    this.numThreads = 4,
    this.useGpu = false,
    this.gpuLayers = 0,
    this.batchSize = 512,
    this.temperature = 0.7,
    this.repetitionPenalty = 1.1,
  });
  
  /// 从Map创建配置
  factory LocalConfig.fromMap(Map<String, dynamic> map) {
    return LocalConfig(
      modelPath: map['modelPath'] ?? '',
      modelName: map['modelName'] ?? 'localllm',
      quantizationType: map['quantizationType'] ?? 'gguf',
      contextWindow: map['contextWindow'] ?? 4096,
      numThreads: map['numThreads'] ?? 4,
      useGpu: map['useGpu'] ?? false,
      gpuLayers: map['gpuLayers'] ?? 0,
      batchSize: map['batchSize'] ?? 512,
      temperature: map['temperature'] ?? 0.7,
      repetitionPenalty: map['repetitionPenalty'] ?? 1.1,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'modelPath': modelPath,
      'modelName': modelName,
      'quantizationType': quantizationType,
      'contextWindow': contextWindow,
      'numThreads': numThreads,
      'useGpu': useGpu,
      'gpuLayers': gpuLayers,
      'batchSize': batchSize,
      'temperature': temperature,
      'repetitionPenalty': repetitionPenalty,
    };
  }
  
  /// 克隆配置
  LocalConfig clone() {
    return LocalConfig.fromMap(toMap());
  }
  
  /// 合并配置
  void merge(LocalConfig other) {
    if (other.modelPath.isNotEmpty) {
      modelPath = other.modelPath;
    }
    
    if (other.modelName.isNotEmpty) {
      modelName = other.modelName;
    }
    
    if (other.quantizationType.isNotEmpty) {
      quantizationType = other.quantizationType;
    }
    
    contextWindow = other.contextWindow;
    numThreads = other.numThreads;
    useGpu = other.useGpu;
    gpuLayers = other.gpuLayers;
    batchSize = other.batchSize;
    temperature = other.temperature;
    repetitionPenalty = other.repetitionPenalty;
  }
} 