import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/features/ai_assistant/domain/tts/tts_config.dart';
import 'package:xewo/src/features/ai_assistant/domain/tts/tts_engine.dart';
import 'package:xewo/src/features/ai_assistant/domain/tts/tts_voice.dart';
import 'package:xewo/src/features/ai_assistant/domain/tts/tts_voice_settings.dart';
import 'package:xewo/src/features/ai_assistant/presentation/providers/tts_providers.dart';
import 'package:xewo/src/features/ai_assistant/presentation/widgets/voice_settings/tts_engine_selector.dart';
import 'package:xewo/src/features/ai_assistant/presentation/widgets/voice_settings/tts_test_panel.dart';
import 'package:xewo/src/features/ai_assistant/presentation/widgets/voice_settings/tts_voice_selector.dart';
import 'package:xewo/src/features/ai_assistant/presentation/widgets/voice_settings/voice_settings_panel.dart';

class VoiceSettingsTab extends ConsumerStatefulWidget {
  const VoiceSettingsTab({super.key});

  @override
  ConsumerState<VoiceSettingsTab> createState() => _VoiceSettingsTabState();
}

class _VoiceSettingsTabState extends ConsumerState<VoiceSettingsTab> {
  TTSEngineType _selectedEngineType = TTSEngineType.system;
  TTSVoice? _selectedVoice;
  double _speed = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final ttsService = ref.read(ttsServiceProvider);
    
    // 获取引擎列表
    final engines = await ttsService.getAvailableEngines();
    
    if (engines.isNotEmpty) {
      setState(() {
        _selectedEngineType = engines.first.type;
      });

      final voices = await engines.first.getAvailableVoices();
      if (voices.isNotEmpty) {
        setState(() {
          _selectedVoice = voices.first;
        });
      }
    }
  }

  void _onEngineChanged(TTSEngineType type) async {
    setState(() {
      _selectedEngineType = type;
      _selectedVoice = null;
    });

    final ttsService = ref.read(ttsServiceProvider);
    
    // 找到选择的引擎类型对应的引擎
    final engines = await ttsService.getAvailableEngines();
    final engine = engines.firstWhere(
      (e) => e.type == type,
      orElse: () => engines.first,
    );

    final voices = await engine.getAvailableVoices();
    if (voices.isNotEmpty) {
      setState(() {
        _selectedVoice = voices.first;
      });
    }
  }

  void _onVoiceChanged(TTSVoice voice) {
    setState(() {
      _selectedVoice = voice;
    });
  }

  void _onSpeedChanged(double value) {
    setState(() {
      _speed = value;
    });
  }

  void _onPitchChanged(double value) {
    setState(() {
      _pitch = value;
    });
  }

  void _onVolumeChanged(double value) {
    setState(() {
      _volume = value;
    });
  }

  void _onTestButtonPressed() async {
    if (_selectedVoice == null) return;

    final ttsService = ref.read(ttsServiceProvider);
    
    // 创建语音设置
    final voiceSettings = TTSVoiceSettings(
      voiceId: _selectedVoice!.id,
      voiceName: _selectedVoice!.name,
      speed: _speed,
      pitch: _pitch,
      volume: _volume,
    );
    
    // 创建配置
    final config = TTSConfig(
      engineType: _selectedEngineType,
      voiceSettings: voiceSettings,
    );

    await ttsService.speak('这是一段测试语音，用于验证语音合成效果。');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TTSEngineSelector(
            selectedEngine: _selectedEngineType,
            onEngineChanged: _onEngineChanged,
          ),
          const SizedBox(height: 16),
          TTSVoiceSelector(
            engineType: _selectedEngineType,
            selectedVoice: _selectedVoice,
            onVoiceChanged: _onVoiceChanged,
          ),
          const SizedBox(height: 16),
          VoiceSettingsPanel(
            speed: _speed,
            pitch: _pitch,
            volume: _volume,
            onSpeedChanged: _onSpeedChanged,
            onPitchChanged: _onPitchChanged,
            onVolumeChanged: _onVolumeChanged,
          ),
          const SizedBox(height: 16),
          TTSTestPanel(
            onTestButtonPressed: _onTestButtonPressed,
          ),
        ],
      ),
    );
  }
} 