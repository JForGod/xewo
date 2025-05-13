import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../domain/tts/tts_config.dart';
import '../../../domain/tts/tts_voice_settings.dart';
import '../../providers/tts_providers.dart';

/// 播放状态枚举
enum PlaybackState {
  /// 初始状态
  idle,
  
  /// 播放中
  playing,
  
  /// 暂停状态
  paused,
  
  /// 停止状态
  stopped,
  
  /// 错误状态
  error
}

/// 简化的播放控制器
class SpeechPlaybackController {
  static final SpeechPlaybackController _instance = SpeechPlaybackController._internal();
  final Logger _logger = Logger('SpeechPlaybackController');
  
  PlaybackState _state = PlaybackState.idle;
  List<Function(PlaybackState)> _stateListeners = [];
  
  /// 单例实例获取方法
  factory SpeechPlaybackController.getInstance() {
    return _instance;
  }
  
  SpeechPlaybackController._internal();
  
  /// 添加状态变化监听
  void addStateChangeListener(Function(PlaybackState) listener) {
    _stateListeners.add(listener);
  }
  
  /// 移除状态变化监听
  void removeStateChangeListener(Function(PlaybackState) listener) {
    _stateListeners.remove(listener);
  }
  
  /// 播放文本
  Future<void> speak(String text) async {
    try {
      _logger.info('播放文本: $text');
      _updateState(PlaybackState.playing);
      // 实际实现会调用TTS引擎
    } catch (e) {
      _logger.severe('播放失败: $e');
      _updateState(PlaybackState.error);
      rethrow;
    }
  }
  
  /// 暂停播放
  Future<void> pause() async {
    try {
      _logger.info('暂停播放');
      _updateState(PlaybackState.paused);
      // 实际实现会调用TTS引擎
    } catch (e) {
      _logger.severe('暂停失败: $e');
      rethrow;
    }
  }
  
  /// 恢复播放
  Future<void> resume() async {
    try {
      _logger.info('恢复播放');
      _updateState(PlaybackState.playing);
      // 实际实现会调用TTS引擎
    } catch (e) {
      _logger.severe('恢复失败: $e');
      rethrow;
    }
  }
  
  /// 停止播放
  Future<void> stop() async {
    try {
      _logger.info('停止播放');
      _updateState(PlaybackState.stopped);
      // 实际实现会调用TTS引擎
    } catch (e) {
      _logger.severe('停止失败: $e');
      rethrow;
    }
  }
  
  /// 更新状态
  void _updateState(PlaybackState newState) {
    _state = newState;
    for (var listener in _stateListeners) {
      listener(_state);
    }
  }
}

/// TTS测试面板
class TTSTestPanel extends ConsumerStatefulWidget {
  /// 测试按钮点击回调
  final VoidCallback? onTestButtonPressed;

  /// 构造函数
  const TTSTestPanel({
    super.key,
    this.onTestButtonPressed,
  });

  @override
  ConsumerState<TTSTestPanel> createState() => _TTSTestPanelState();
}

class _TTSTestPanelState extends ConsumerState<TTSTestPanel> {
  final Logger _logger = Logger('TTSTestPanel');
  final TextEditingController _textController = TextEditingController();
  
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _currentSpeed = 1.0;
  
  late final SpeechPlaybackController _playbackController;
  
  @override
  void initState() {
    super.initState();
    _textController.text = '这是一段测试文本，用于测试TTS功能是否正常。';
    _initTTS();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  /// 初始化TTS
  Future<void> _initTTS() async {
    try {
      _playbackController = SpeechPlaybackController.getInstance();
      
      // 添加状态监听
      _playbackController.addStateChangeListener((state) {
        setState(() {
          _isSpeaking = state == PlaybackState.playing;
          _isPaused = state == PlaybackState.paused;
        });
      });
    } catch (e) {
      _logger.severe('TTS初始化失败: $e');
      _showError('TTS初始化失败，请检查系统设置');
    }
  }
  
  /// 测试语音
  Future<void> _testSpeech() async {
    if (_textController.text.isEmpty) {
      _showError('请输入测试文本');
      return;
    }
    
    try {
      if (_isSpeaking) {
        if (_isPaused) {
          await _playbackController.resume();
        } else {
          await _playbackController.pause();
        }
      } else {
        await _playbackController.speak(_textController.text);
      }
      
      widget.onTestButtonPressed?.call();
    } catch (e) {
      _logger.severe('语音测试失败: $e');
      _showError('语音测试失败，请稍后重试');
    }
  }
  
  /// 停止语音
  Future<void> _stopSpeech() async {
    try {
      await _playbackController.stop();
    } catch (e) {
      _logger.severe('停止语音失败: $e');
      _showError('停止语音失败，请稍后重试');
    }
  }
  
  /// 调整语速
  Future<void> _adjustSpeed(double speed) async {
    try {
      // 读取TTS服务
      final ttsService = ref.read(ttsServiceProvider);
      
      // 设置语速
      await ttsService.setSpeechRate(speed);
      setState(() {
        _currentSpeed = speed;
      });
    } catch (e) {
      _logger.severe('调整语速失败: $e');
      _showError('调整语速失败，请稍后重试');
    }
  }
  
  /// 显示错误信息
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '测试文本',
                hintText: '请输入要测试的文本',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('语速调节：'),
                Expanded(
                  child: Slider(
                    value: _currentSpeed,
                    min: 0.1,
                    max: 3.0,
                    divisions: 29,
                    label: _currentSpeed.toStringAsFixed(1),
                    onChanged: _adjustSpeed,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${_currentSpeed.toStringAsFixed(1)}x',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _testSpeech,
                  icon: Icon(_isSpeaking 
                    ? (_isPaused ? Icons.play_arrow : Icons.pause)
                    : Icons.play_arrow
                  ),
                  label: Text(_isSpeaking 
                    ? (_isPaused ? '继续' : '暂停')
                    : '播放'
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSpeaking ? _stopSpeech : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 