import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/features/ai_assistant/domain/tts/tts_engine.dart';
import 'package:xewo/src/features/ai_assistant/domain/tts/tts_voice.dart';
import 'package:xewo/src/features/ai_assistant/presentation/providers/tts_providers.dart';

/// 语音选择器组件
class TTSVoiceSelector extends ConsumerStatefulWidget {
  final TTSEngineType engineType;
  final TTSVoice? selectedVoice;
  final Function(TTSVoice) onVoiceChanged;
  
  const TTSVoiceSelector({
    super.key,
    required this.engineType,
    this.selectedVoice,
    required this.onVoiceChanged,
  });

  @override
  ConsumerState<TTSVoiceSelector> createState() => _TTSVoiceSelectorState();
}

class _TTSVoiceSelectorState extends ConsumerState<TTSVoiceSelector> {
  List<TTSVoice> _voices = [];
  bool _isLoading = true;
  TTSVoice? _selectedVoice;
  
  @override
  void initState() {
    super.initState();
    _selectedVoice = widget.selectedVoice;
    _loadVoices();
  }
  
  @override
  void didUpdateWidget(TTSVoiceSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engineType != widget.engineType) {
      _loadVoices();
    }
    
    if (oldWidget.selectedVoice != widget.selectedVoice) {
      _selectedVoice = widget.selectedVoice;
    }
  }
  
  Future<void> _loadVoices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final ttsService = ref.read(ttsServiceProvider);
      final voices = await ttsService.getAvailableVoices();
      
      setState(() {
        // 确保所有返回的对象都是TTSVoice类型
        _voices = voices.where((v) => v is TTSVoice).cast<TTSVoice>().toList();
        
        // 如果没有语音或列表为空，添加默认语音
        if (_voices.isEmpty) {
          _voices = [
            const TTSVoice(
              id: 'default',
              name: '默认语音',
              language: 'zh-CN',
              locale: 'zh-CN',
              gender: null,
            ),
          ];
        }
        
        // 如果没有选择语音，使用第一个
        if (_selectedVoice == null && _voices.isNotEmpty) {
          _selectedVoice = _voices.first;
          widget.onVoiceChanged(_selectedVoice!);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _voices = [
          const TTSVoice(
            id: 'default',
            name: '默认语音',
            language: 'zh-CN',
            locale: 'zh-CN',
            gender: null,
          ),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '语音',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          DropdownButtonFormField<TTSVoice>(
            value: _selectedVoice,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedVoice = newValue;
                });
                widget.onVoiceChanged(newValue);
              }
            },
            items: _voices.map((voice) {
              return DropdownMenuItem<TTSVoice>(
                value: voice,
                child: Text(
                  '${voice.name} (${voice.language})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
} 