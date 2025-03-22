// 2025-03-22: 新增 - 创建语音设置标签页，包含语音识别和语音合成功能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../themes/standard_theme.dart';

/// 语音服务类型
enum VoiceServiceType {
  /// 本地语音服务
  local,

  /// 在线语音服务
  online,
  
  /// 混合模式（优先本地，失败后使用在线）
  hybrid
}

/// STT引擎类型
enum STTEngineType {
  /// 系统内置STT
  system,
  
  /// OpenAI Whisper
  whisper,
  
  /// Google STT
  google,
  
  /// 自定义STT引擎
  custom
}

/// TTS引擎类型
enum TTSEngineType {
  /// 系统内置TTS
  system,
  
  /// Google TTS
  google,
  
  /// Azure TTS
  azure,
  
  /// 自定义TTS引擎
  custom
}

/// 语音设置标签页
class VoiceSettingsTab extends ConsumerStatefulWidget {
  /// 构造函数
  const VoiceSettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceSettingsTab> createState() => _VoiceSettingsTabState();
}

class _VoiceSettingsTabState extends ConsumerState<VoiceSettingsTab> with AutomaticKeepAliveClientMixin {
  /// 是否开启语音识别
  bool _enableSTT = false;
  
  /// 是否开启语音合成
  bool _enableTTS = false;
  
  /// 当前选择的语音服务类型
  VoiceServiceType _selectedVoiceServiceType = VoiceServiceType.hybrid;
  
  /// 当前选择的STT引擎类型
  STTEngineType _selectedSTTEngine = STTEngineType.system;
  
  /// 当前选择的TTS引擎类型
  TTSEngineType _selectedTTSEngine = TTSEngineType.system;
  
  /// 自定义STT引擎URL控制器
  final TextEditingController _customSTTUrlController = TextEditingController();
  
  /// 自定义TTS引擎URL控制器
  final TextEditingController _customTTSUrlController = TextEditingController();
  
  /// API密钥控制器
  final TextEditingController _apiKeyController = TextEditingController();
  
  /// API密钥是否可见
  bool _isApiKeyVisible = false;
  
  /// 当前选择的标签页索引
  int _tabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
  }
  
  @override
  void dispose() {
    _customSTTUrlController.dispose();
    _customTTSUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
  
  /// 2025-03-22: 新增 - 加载语音设置
  Future<void> _loadVoiceSettings() async {
    // TODO: 从设置服务中加载语音设置
    // 示例代码，实际实现需要加载保存的设置
    setState(() {
      _enableSTT = true;
      _enableTTS = true;
      _selectedVoiceServiceType = VoiceServiceType.hybrid;
      _selectedSTTEngine = STTEngineType.system;
      _selectedTTSEngine = TTSEngineType.system;
    });
  }
  
  /// 2025-03-22: 新增 - 保存语音设置
  Future<void> saveSettings() async {
    // TODO: 将当前设置保存到设置服务
    // 示例代码，实际实现需要保存设置到持久化存储
    
    // 显示保存成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音设置已保存')),
      );
    }
  }
  
  /// 2025-03-22: 新增 - 构建语音服务类型选择UI
  Widget _buildVoiceServiceTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '语音服务类型',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VoiceServiceType.values.map((type) {
            final isSelected = _selectedVoiceServiceType == type;
            String label;
            switch (type) {
              case VoiceServiceType.local:
                label = '本地服务';
                break;
              case VoiceServiceType.online:
                label = '在线服务';
                break;
              case VoiceServiceType.hybrid:
                label = '混合模式';
                break;
            }
            
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedVoiceServiceType = type;
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: StandardTheme.accentColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getVoiceServiceDescription(_selectedVoiceServiceType),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取语音服务类型描述
  String _getVoiceServiceDescription(VoiceServiceType type) {
    switch (type) {
      case VoiceServiceType.local:
        return '使用设备本地语音引擎，无需网络，但功能可能受限';
      case VoiceServiceType.online:
        return '使用在线语音服务，功能更强大，但需要网络连接';
      case VoiceServiceType.hybrid:
        return '优先使用本地服务，如果失败则切换到在线服务（推荐）';
    }
  }
  
  /// 2025-03-22: 新增 - 构建STT设置UI
  Widget _buildSTTSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('启用语音识别'),
          subtitle: const Text('允许通过语音输入与AI交互'),
          value: _enableSTT,
          onChanged: (value) {
            setState(() {
              _enableSTT = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (_enableSTT) ...[
          const SizedBox(height: 16),
          const Text(
            'STT引擎选择',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: STTEngineType.values.map((engine) {
              final isSelected = _selectedSTTEngine == engine;
              String label;
              switch (engine) {
                case STTEngineType.system:
                  label = '系统内置';
                  break;
                case STTEngineType.whisper:
                  label = 'OpenAI Whisper';
                  break;
                case STTEngineType.google:
                  label = 'Google STT';
                  break;
                case STTEngineType.custom:
                  label = '自定义引擎';
                  break;
              }
              
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedSTTEngine = engine;
                  });
                },
                backgroundColor: Colors.grey[800],
                selectedColor: StandardTheme.accentColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _getSTTEngineDescription(_selectedSTTEngine),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          
          if (_selectedSTTEngine == STTEngineType.custom) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _customSTTUrlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '自定义STT引擎URL',
                fillColor: Color(0xFF2A2A38),
                filled: true,
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
          
          if (_selectedSTTEngine == STTEngineType.whisper ||
              _selectedSTTEngine == STTEngineType.google) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'API密钥',
                fillColor: const Color(0xFF2A2A38),
                filled: true,
                labelStyle: const TextStyle(color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isApiKeyVisible = !_isApiKeyVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isApiKeyVisible,
              style: const TextStyle(color: Colors.white),
            ),
          ],
          
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 实现STT测试功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('开始语音识别测试...')),
              );
            },
            icon: const Icon(Icons.mic),
            label: const Text('测试语音识别'),
            style: ElevatedButton.styleFrom(
              backgroundColor: StandardTheme.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取STT引擎描述
  String _getSTTEngineDescription(STTEngineType engine) {
    switch (engine) {
      case STTEngineType.system:
        return '使用系统内置的语音识别引擎，无需额外配置';
      case STTEngineType.whisper:
        return 'OpenAI Whisper模型，支持多语言、准确度高，需要API密钥';
      case STTEngineType.google:
        return 'Google语音识别服务，支持多语言、实时识别，需要API密钥';
      case STTEngineType.custom:
        return '自定义语音识别引擎，需要提供API端点URL';
    }
  }
  
  /// 2025-03-22: 新增 - 构建TTS设置UI
  Widget _buildTTSSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('启用语音合成'),
          subtitle: const Text('允许AI通过语音回复'),
          value: _enableTTS,
          onChanged: (value) {
            setState(() {
              _enableTTS = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (_enableTTS) ...[
          const SizedBox(height: 16),
          const Text(
            'TTS引擎选择',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TTSEngineType.values.map((engine) {
              final isSelected = _selectedTTSEngine == engine;
              String label;
              switch (engine) {
                case TTSEngineType.system:
                  label = '系统内置';
                  break;
                case TTSEngineType.google:
                  label = 'Google TTS';
                  break;
                case TTSEngineType.azure:
                  label = 'Azure TTS';
                  break;
                case TTSEngineType.custom:
                  label = '自定义引擎';
                  break;
              }
              
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedTTSEngine = engine;
                  });
                },
                backgroundColor: Colors.grey[800],
                selectedColor: StandardTheme.accentColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _getTTSEngineDescription(_selectedTTSEngine),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          
          if (_selectedTTSEngine == TTSEngineType.custom) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _customTTSUrlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '自定义TTS引擎URL',
                fillColor: Color(0xFF2A2A38),
                filled: true,
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
          
          if (_selectedTTSEngine == TTSEngineType.google ||
              _selectedTTSEngine == TTSEngineType.azure) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'API密钥',
                fillColor: const Color(0xFF2A2A38),
                filled: true,
                labelStyle: const TextStyle(color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isApiKeyVisible = !_isApiKeyVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isApiKeyVisible,
              style: const TextStyle(color: Colors.white),
            ),
          ],
          
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 实现TTS测试功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('开始语音合成测试...')),
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('测试语音合成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: StandardTheme.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取TTS引擎描述
  String _getTTSEngineDescription(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.system:
        return '使用系统内置的语音合成引擎，无需额外配置';
      case TTSEngineType.google:
        return 'Google语音合成服务，支持多种语言和声音，需要API密钥';
      case TTSEngineType.azure:
        return 'Microsoft Azure语音合成服务，提供自然的语音效果，需要API密钥';
      case TTSEngineType.custom:
        return '自定义语音合成引擎，需要提供API端点URL';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return DefaultTabController(
      length: 2,
      initialIndex: _tabIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.grey[900],
            child: TabBar(
              onTap: (index) {
                setState(() {
                  _tabIndex = index;
                });
              },
              tabs: const [
                Tab(
                  icon: Icon(Icons.mic),
                  text: '语音识别',
                ),
                Tab(
                  icon: Icon(Icons.volume_up),
                  text: '语音合成',
                ),
              ],
              indicatorColor: StandardTheme.accentColor,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 语音识别标签页
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVoiceServiceTypeSelection(),
                      const SizedBox(height: 24),
                      _buildSTTSettings(),
                    ],
                  ),
                ),
                
                // 语音合成标签页
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVoiceServiceTypeSelection(),
                      const SizedBox(height: 24),
                      _buildTTSSettings(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
} 