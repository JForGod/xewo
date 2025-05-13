import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../../domain/tts/tts_engine.dart';
import '../../../providers/tts_providers.dart';

/// 语音设置面板
class VoiceSettingsPanel extends ConsumerStatefulWidget {
  final double speed;
  final double pitch;
  final double volume;
  final Function(double)? onSpeedChanged;
  final Function(double)? onPitchChanged;
  final Function(double)? onVolumeChanged;
  final bool showRealTimeControls;

  const VoiceSettingsPanel({
    super.key,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.onSpeedChanged,
    this.onPitchChanged,
    this.onVolumeChanged,
    this.showRealTimeControls = true,
  });

  @override
  ConsumerState<VoiceSettingsPanel> createState() => _VoiceSettingsPanelState();
}

class _VoiceSettingsPanelState extends ConsumerState<VoiceSettingsPanel> {
  double _speed = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;
  final _logger = Logger('VoiceSettingsPanel');
  bool _isSpeaking = false;
  bool _isRealTimeMode = false;
  
  @override
  void initState() {
    super.initState();
    _speed = widget.speed;
    _pitch = widget.pitch;
    _volume = widget.volume;
    
    // 默认情况下检查当前是否有TTS在播放
    _checkTTSStatus();
  }
  
  @override
  void didUpdateWidget(VoiceSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      setState(() => _speed = widget.speed);
    }
    if (oldWidget.pitch != widget.pitch) {
      setState(() => _pitch = widget.pitch);
    }
    if (oldWidget.volume != widget.volume) {
      setState(() => _volume = widget.volume);
    }
  }
  
  Future<void> _checkTTSStatus() async {
    try {
      final ttsService = ref.read(ttsServiceProvider);
      
      // 获取当前活跃的引擎
      final engines = await ttsService.getAvailableEngines();
      final activeEngine = engines.isNotEmpty ? engines.first : null;
      
      if (activeEngine != null) {
        setState(() {
          _isSpeaking = activeEngine.isSpeaking;
        });
        
        // 监听状态变化
        activeEngine.onStateChanged.listen((state) {
          if (mounted) {
            setState(() {
              _isSpeaking = state == TTSState.speaking;
            });
          }
        });
      }
    } catch (e) {
      _logger.warning('检查TTS状态失败: $e');
    }
  }
  
  Future<void> _applyRealTimeSpeedChange(double value) async {
    try {
      if (!_isRealTimeMode || !_isSpeaking) return;
      
      final ttsService = ref.read(ttsServiceProvider);
      
      // 获取当前活跃的引擎
      final engines = await ttsService.getAvailableEngines();
      final engine = engines.isNotEmpty ? engines.first : null;
      
      if (engine == null) {
        _logger.warning('无法获取TTS引擎');
        return;
      }
      
      // 实时应用语速变化
      if (engine.type == TTSEngineType.system) {
        await engine.setSpeechRate(value);
      } else {
        // 通用处理方式
        await engine.setSpeechRate(value);
        if (_isSpeaking) {
          // 需要停止并重新开始
          await ttsService.stop();
          // 这里假设我们能够获取当前播放的文本
          // 实际应用中可能需要存储最近播放的文本
          await Future.delayed(const Duration(milliseconds: 300));
          // 由于我们没有当前播放的文本，此处可能需要使用其他方式恢复播放
        }
      }
      
      _logger.info('实时应用语速: $value');
    } catch (e) {
      _logger.warning('实时调整语速失败: $e');
    }
  }
  
  Widget _buildSpeedSlider() {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('语速:')),
        Expanded(
          child: Slider(
            value: _speed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: _speed.toStringAsFixed(1),
            activeColor: _isRealTimeMode ? Colors.green : null,
            onChanged: (value) {
              setState(() => _speed = value);
              
              // 如果启用了实时模式，立即应用更改
              if (_isRealTimeMode) {
                _applyRealTimeSpeedChange(value);
              }
              
              if (widget.onSpeedChanged != null) {
                widget.onSpeedChanged!(value);
              }
            },
            onChangeEnd: (value) {
              // 即使不是实时模式，在滑动结束时也应用更改
              if (!_isRealTimeMode && _isSpeaking) {
                _applyRealTimeSpeedChange(value);
              }
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(_speed.toStringAsFixed(1), textAlign: TextAlign.center),
        ),
      ],
    );
  }
  
  Widget _buildPitchSlider() {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('音调:')),
        Expanded(
          child: Slider(
            value: _pitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: _pitch.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => _pitch = value);
              if (widget.onPitchChanged != null) {
                widget.onPitchChanged!(value);
              }
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(_pitch.toStringAsFixed(1), textAlign: TextAlign.center),
        ),
      ],
    );
  }
  
  Widget _buildVolumeSlider() {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('音量:')),
        Expanded(
          child: Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: (_volume * 100).round().toString() + '%',
            onChanged: (value) {
              setState(() => _volume = value);
              if (widget.onVolumeChanged != null) {
                widget.onVolumeChanged!(value);
              }
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text((_volume * 100).round().toString() + '%', textAlign: TextAlign.center),
        ),
      ],
    );
  }
  
  Widget _buildRealTimeControls() {
    if (!widget.showRealTimeControls) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: _isRealTimeMode,
            onChanged: (value) {
              setState(() {
                _isRealTimeMode = value ?? false;
              });
            },
          ),
          const Text('实时应用语速变化'),
          const Spacer(),
          if (_isSpeaking)
            Chip(
              label: const Text('TTS播放中'),
              backgroundColor: Colors.green[100],
              avatar: const Icon(Icons.volume_up, size: 16),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '语音设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildRealTimeControls(),
            _buildSpeedSlider(),
            const SizedBox(height: 8),
            _buildPitchSlider(),
            const SizedBox(height: 8),
            _buildVolumeSlider(),
          ],
        ),
      ),
    );
  }
} 