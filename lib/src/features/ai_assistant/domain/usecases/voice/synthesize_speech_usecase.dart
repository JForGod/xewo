import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/audio/speech_service.dart';
import '../../repositories/settings_repository.dart';

/// 语音合成用例
class SynthesizeSpeechUseCase {
  final SpeechService _speechService;
  final SettingsRepository _settingsRepository;
  
  /// 构造函数
  SynthesizeSpeechUseCase({
    required SpeechService speechService,
    required SettingsRepository settingsRepository,
  })  : _speechService = speechService,
        _settingsRepository = settingsRepository;
  
  /// 执行用例
  // 2025-03-16 + 执行语音合成功能
  Future<List<int>> execute({
    required String text,
    String? voiceId,
    double? speed,
    double? pitch,
  }) async {
    // 获取语音设置
    final settings = await _getVoiceSettings();
    
    // 使用提供的参数或默认设置
    final actualVoiceId = voiceId ?? settings.voiceId;
    final actualSpeed = speed ?? settings.speed;
    final actualPitch = pitch ?? settings.pitch;
    
    // 合成语音
    return await _speechService.synthesizeSpeech(
      text: text,
      voiceId: actualVoiceId,
      speed: actualSpeed,
      pitch: actualPitch,
    );
  }
  
  /// 获取语音设置
  // 2025-03-16 + 获取语音设置功能
  Future<VoiceSettings> _getVoiceSettings() async {
    final voiceCategory = await _settingsRepository.getCategory('voice');
    
    return VoiceSettings(
      voiceId: voiceCategory['voice_id'] as String? ?? 'default',
      speed: (voiceCategory['speed'] as num?)?.toDouble() ?? 1.0,
      pitch: (voiceCategory['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (voiceCategory['volume'] as num?)?.toDouble() ?? 1.0,
      enableTTS: voiceCategory['enable_tts'] as bool? ?? true,
    );
  }
}

/// 语音设置
class VoiceSettings {
  /// 语音ID
  final String voiceId;
  
  /// 语速
  final double speed;
  
  /// 音调
  final double pitch;
  
  /// 音量
  final double volume;
  
  /// 是否启用TTS
  final bool enableTTS;
  
  /// 构造函数
  VoiceSettings({
    required this.voiceId,
    required this.speed,
    required this.pitch,
    required this.volume,
    required this.enableTTS,
  });
}

/// 语音合成用例提供者
final synthesizeSpeechUseCaseProvider = Provider<SynthesizeSpeechUseCase>((ref) {
  final speechService = ref.watch(speechServiceProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  
  return SynthesizeSpeechUseCase(
    speechService: speechService,
    settingsRepository: settingsRepository,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/audio/speech_service.dart';
import '../../repositories/settings_repository.dart';

/// 语音合成用例
class SynthesizeSpeechUseCase {
  final SpeechService _speechService;
  final SettingsRepository _settingsRepository;
  
  /// 构造函数
  SynthesizeSpeechUseCase({
    required SpeechService speechService,
    required SettingsRepository settingsRepository,
  })  : _speechService = speechService,
        _settingsRepository = settingsRepository;
  
  /// 执行用例
  // 2025-03-16 + 执行语音合成功能
  Future<List<int>> execute({
    required String text,
    String? voiceId,
    double? speed,
    double? pitch,
  }) async {
    // 获取语音设置
    final settings = await _getVoiceSettings();
    
    // 使用提供的参数或默认设置
    final actualVoiceId = voiceId ?? settings.voiceId;
    final actualSpeed = speed ?? settings.speed;
    final actualPitch = pitch ?? settings.pitch;
    
    // 合成语音
    return await _speechService.synthesizeSpeech(
      text: text,
      voiceId: actualVoiceId,
      speed: actualSpeed,
      pitch: actualPitch,
    );
  }
  
  /// 获取语音设置
  // 2025-03-16 + 获取语音设置功能
  Future<VoiceSettings> _getVoiceSettings() async {
    final voiceCategory = await _settingsRepository.getCategory('voice');
    
    return VoiceSettings(
      voiceId: voiceCategory['voice_id'] as String? ?? 'default',
      speed: (voiceCategory['speed'] as num?)?.toDouble() ?? 1.0,
      pitch: (voiceCategory['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (voiceCategory['volume'] as num?)?.toDouble() ?? 1.0,
      enableTTS: voiceCategory['enable_tts'] as bool? ?? true,
    );
  }
}

/// 语音设置
class VoiceSettings {
  /// 语音ID
  final String voiceId;
  
  /// 语速
  final double speed;
  
  /// 音调
  final double pitch;
  
  /// 音量
  final double volume;
  
  /// 是否启用TTS
  final bool enableTTS;
  
  /// 构造函数
  VoiceSettings({
    required this.voiceId,
    required this.speed,
    required this.pitch,
    required this.volume,
    required this.enableTTS,
  });
}

/// 语音合成用例提供者
final synthesizeSpeechUseCaseProvider = Provider<SynthesizeSpeechUseCase>((ref) {
  final speechService = ref.watch(speechServiceProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  
  return SynthesizeSpeechUseCase(
    speechService: speechService,
    settingsRepository: settingsRepository,
  );
});