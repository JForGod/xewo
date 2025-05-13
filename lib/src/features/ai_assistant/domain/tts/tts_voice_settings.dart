// 2025-03-26: 新增 - TTS语音设置类

/// 语音性别枚举
enum TTSVoiceGender {
  /// 男性
  male,
  
  /// 女性
  female,
  
  /// 中性
  neutral,
  
  /// 未知
  unknown
}

/// TTS语音设置类
/// 用于存储TTS语音的相关设置
class TTSVoiceSettings {
  /// 语音ID
  final String voiceId;
  
  /// 语音名称
  final String voiceName;
  
  /// 语音性别
  final TTSVoiceGender gender;
  
  /// 语速 (0.1-3.0)
  final double speed;
  
  /// 音调 (0.1-2.0)
  final double pitch;
  
  /// 音量 (0.0-1.0)
  final double volume;
  
  /// 语言代码 (例如: zh-CN)
  final String languageCode;
  
  /// 构造函数
  const TTSVoiceSettings({
    this.voiceId = '',
    this.voiceName = '',
    this.gender = TTSVoiceGender.unknown,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.languageCode = 'zh-CN',
  });
  
  /// 复制并修改
  TTSVoiceSettings copyWith({
    String? voiceId,
    String? voiceName,
    TTSVoiceGender? gender,
    double? speed,
    double? pitch,
    double? volume,
    String? languageCode,
  }) {
    return TTSVoiceSettings(
      voiceId: voiceId ?? this.voiceId,
      voiceName: voiceName ?? this.voiceName,
      gender: gender ?? this.gender,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      languageCode: languageCode ?? this.languageCode,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'voiceId': voiceId,
      'voiceName': voiceName,
      'gender': gender.toString(),
      'speed': speed,
      'pitch': pitch,
      'volume': volume,
      'languageCode': languageCode,
    };
  }
  
  /// 从JSON创建
  factory TTSVoiceSettings.fromJson(Map<String, dynamic> json) {
    return TTSVoiceSettings(
      voiceId: json['voiceId'] ?? '',
      voiceName: json['voiceName'] ?? '',
      gender: _parseGender(json['gender']),
      speed: json['speed'] ?? 1.0,
      pitch: json['pitch'] ?? 1.0,
      volume: json['volume'] ?? 1.0,
      languageCode: json['languageCode'] ?? 'zh-CN',
    );
  }
  
  /// 解析性别
  static TTSVoiceGender _parseGender(String? gender) {
    if (gender == null) return TTSVoiceGender.unknown;
    
    try {
      final strippedGender = gender.replaceAll('TTSVoiceGender.', '');
      return TTSVoiceGender.values.firstWhere(
        (g) => g.toString().replaceAll('TTSVoiceGender.', '') == strippedGender,
        orElse: () => TTSVoiceGender.unknown
      );
    } catch (e) {
      return TTSVoiceGender.unknown;
    }
  }
  
  /// 验证语速是否在有效范围内
  bool isValidSpeed(double speed) {
    return speed >= 0.1 && speed <= 3.0;
  }
  
  /// 验证音调是否在有效范围内
  bool isValidPitch(double pitch) {
    return pitch >= 0.1 && pitch <= 2.0;
  }
  
  /// 验证音量是否在有效范围内
  bool isValidVolume(double volume) {
    return volume >= 0.0 && volume <= 1.0;
  }
  
  /// 获取语音显示名称
  String get displayName {
    if (voiceName.isNotEmpty) {
      return voiceName;
    }
    return voiceId.isNotEmpty ? voiceId : '默认语音';
  }
}

/// TTS引擎配置，包含引擎的基本配置参数
class InternalTTSEngineConfig {
  /// 语音设置
  final TTSVoiceSettings voiceSettings;
  
  /// API密钥
  final String apiKey;
  
  /// 自定义端点URL
  final String customEndpoint;
  
  /// 构造函数
  const InternalTTSEngineConfig({
    this.voiceSettings = const TTSVoiceSettings(),
    this.apiKey = '',
    this.customEndpoint = '',
  });
  
  /// 拷贝并修改属性
  InternalTTSEngineConfig copyWith({
    TTSVoiceSettings? voiceSettings,
    String? apiKey,
    String? customEndpoint,
  }) {
    return InternalTTSEngineConfig(
      voiceSettings: voiceSettings ?? this.voiceSettings,
      apiKey: apiKey ?? this.apiKey,
      customEndpoint: customEndpoint ?? this.customEndpoint,
    );
  }
  
  /// 2025-04-03: 新增 - 获取语音ID
  String get voiceId => voiceSettings.voiceId;
  
  /// 2025-04-03: 新增 - 获取语速
  double get speed => voiceSettings.speed;
  
  /// 2025-04-03: 新增 - 获取音调
  double get pitch => voiceSettings.pitch;
  
  /// 2025-04-03: 新增 - 获取音量
  double get volume => voiceSettings.volume;
  
  @override
  String toString() {
    return 'InternalTTSEngineConfig{voiceSettings: $voiceSettings, apiKey: ${apiKey.isNotEmpty ? "***" : "未设置"}, customEndpoint: $customEndpoint}';
  }
} 