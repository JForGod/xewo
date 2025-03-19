// 2025-03-17: 新增 - LLM配置页面

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/standard_theme.dart';
import '../../../../core/ai_engine/llm/llm_config_service.dart';
import '../../../../core/ai_engine/llm/llm_service_provider.dart';

/// LLM配置页面
class LLMConfigPage extends ConsumerStatefulWidget {
  /// 构造函数
  const LLMConfigPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LLMConfigPage> createState() => _LLMConfigPageState();
}

class _LLMConfigPageState extends ConsumerState<LLMConfigPage> {
  /// LLM配置服务
  LLMConfigService? _configService;
  
  /// 当前选择的提供者
  LLMProvider? _selectedProvider;
  
  /// 是否正在加载
  bool _isLoading = true;
  
  /// API密钥控制器
  final TextEditingController _apiKeyController = TextEditingController();
  
  /// 模型控制器
  final TextEditingController _modelController = TextEditingController();
  
  /// 代理主机控制器
  final TextEditingController _proxyHostController = TextEditingController(text: '127.0.0.1');
  
  /// 代理端口控制器
  final TextEditingController _proxyPortController = TextEditingController(text: '1080');
  
  /// API密钥是否可见
  bool _isApiKeyVisible = false;
  
  /// 是否使用代理
  bool _useProxy = false;  // 默认不使用代理
  
  /// 开发者模式（跳过API验证）
  bool _devMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadConfig();
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    super.dispose();
  }
  
  /// 加载配置
  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _configService = ref.read(llmConfigServiceProvider);
      _selectedProvider = _configService!.getCurrentProvider();
      
      // 加载API密钥
      final apiKey = _configService!.getApiKey(_selectedProvider!);
      if (apiKey != null) {
        _apiKeyController.text = apiKey;
      }
      
      // 加载模型配置
      final config = _configService!.getConfig(_selectedProvider!);
      final availableModels = _configService!.getAvailableModels(_selectedProvider!);
      
      if (config.containsKey('model') && availableModels.contains(config['model'])) {
        _modelController.text = config['model'] as String;
      } else {
        // 如果保存的模型不在可用列表中，使用第一个可用模型
        if (availableModels.isNotEmpty) {
          _modelController.text = availableModels.first;
        }
      }
      
      // 加载代理配置
      final proxyConfig = _configService!.getProxyConfig();
      _useProxy = proxyConfig['useProxy'] as bool? ?? false;
      _proxyHostController.text = proxyConfig['proxyHost'] as String? ?? '127.0.0.1';
      _proxyPortController.text = (proxyConfig['proxyPort'] as int? ?? 1080).toString();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载配置失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 保存配置
  Future<void> _saveConfig() async {
    if (_selectedProvider == null) {
      return;
    }
    
    final apiKey = _apiKeyController.text.trim();
    
    // 如果在开发者模式下，允许跳过API密钥验证
    if (apiKey.isEmpty && !_devMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的API密钥')),
      );
      return;
    }
    
    // 保存API密钥
    await _configService!.saveApiKey(_selectedProvider!, apiKey);
    
    // 保存模型配置
    final model = _modelController.text.trim();
    if (model.isNotEmpty) {
      await _configService!.saveConfig(_selectedProvider!, {'model': model});
    }
    
    // 保存代理配置
    await _configService!.saveProxyConfig(
      useProxy: _useProxy,
      proxyHost: _proxyHostController.text.trim(),
      proxyPort: int.tryParse(_proxyPortController.text.trim()) ?? 1080,
    );
    
    // 确保应用当前提供者设置
    await _configService!.setCurrentProvider(_selectedProvider!);
    
    // 重置激活的服务以便重新创建
    await _configService!.resetActiveService();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('配置已保存')),
    );
    
    setState(() {
      _isLoading = false;
    });
  }
  
  /// 切换提供者
  void _changeProvider(LLMProvider provider) {
    setState(() {
      _selectedProvider = provider;
      
      // 加载当前提供者的API密钥
      final apiKey = _configService!.getApiKey(provider);
      _apiKeyController.text = apiKey ?? '';
      
      // 加载当前提供者的模型配置
      final config = _configService!.getConfig(provider);
      final availableModels = _configService!.getAvailableModels(provider);
      
      // 检查保存的模型是否在可用列表中
      if (config.containsKey('model') && availableModels.contains(config['model'])) {
        _modelController.text = config['model'] as String;
      } else {
        // 如果保存的模型不在可用列表中，使用第一个可用模型
        if (availableModels.isNotEmpty) {
          _modelController.text = availableModels.first;
        } else {
          _modelController.text = '';
        }
      }
    });
  }
  
  /// 测试连接
  Future<void> _testConnection() async {
    if (_selectedProvider == null || _configService == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 临时保存当前配置
      await _configService!.saveApiKey(
        _selectedProvider!,
        _apiKeyController.text,
      );
      
      // 保存模型配置
      await _configService!.saveConfig(
        _selectedProvider!,
        {'model': _modelController.text},
      );
      
      // 保存代理配置
      int proxyPort = 1080;
      try {
        proxyPort = int.parse(_proxyPortController.text);
      } catch (e) {
        // 使用默认值
      }
      
      await _configService!.saveProxyConfig(
        useProxy: _useProxy,
        proxyHost: _proxyHostController.text,
        proxyPort: proxyPort,
      );
      
      // 设置当前提供者
      await _configService!.setCurrentProvider(_selectedProvider!);
      
      // 尝试初始化LLM服务
      final llmService = await _configService!.getActiveLLMService();
      
      // 直接测试连接
      final success = await llmService.testConnection();
      
      if (success) {
        _showTestResult(true, "连接测试成功！");
        
        // 如果连接成功，尝试进行会话测试
        try {
          final sessionResponse = await llmService.sessionTest();
          _showTestResult(true, "会话测试成功:\n$sessionResponse");
        } catch (sessionError) {
          _showTestResult(false, "连接成功但会话测试失败：${sessionError.toString()}");
        }
      } else {
        _showTestResult(false, "连接测试失败");
      }
    } catch (e) {
      _showTestResult(false, "错误：${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showTestResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? '连接成功' : '连接失败'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM服务配置'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildConfigForm(),
    );
  }
  
  /// 构建配置表单
  Widget _buildConfigForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProviderSelection(),
          const SizedBox(height: 24),
          _buildApiKeyInput(),
          const SizedBox(height: 16),
          _buildModelSelection(),
          const SizedBox(height: 16),
          _buildProxySettings(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  /// 构建提供者选择
  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LLM提供者',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: LLMProvider.values.map((provider) {
            final isSelected = _selectedProvider == provider;
            return ChoiceChip(
              label: Text(LLMConfigService.getProviderDisplayName(provider)),
              selected: isSelected,
              onSelected: (_) => _changeProvider(provider),
              backgroundColor: Colors.grey[800],
              selectedColor: StandardTheme.accentColor,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  /// 构建API密钥输入
  Widget _buildApiKeyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API密钥',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            hintText: '输入API密钥',
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isApiKeyVisible = !_isApiKeyVisible;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      _apiKeyController.text = data.text!;
                    }
                  },
                ),
              ],
            ),
          ),
          obscureText: !_isApiKeyVisible,
        ),
        const SizedBox(height: 8),
        Text(
          _getApiKeyHelp(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  /// 构建模型选择
  Widget _buildModelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模型',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedProvider != null) 
          Builder(
            builder: (context) {
              final availableModels = _configService!.getAvailableModels(_selectedProvider!);
              // 确保当前选中的模型在可用列表中
              final modelValue = availableModels.contains(_modelController.text) 
                  ? _modelController.text 
                  : availableModels.isNotEmpty 
                      ? availableModels.first 
                      : '';
                      
              if (modelValue != _modelController.text) {
                _modelController.text = modelValue;
              }
              
              return DropdownButtonFormField<String>(
                value: modelValue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: availableModels
                    .map((model) => DropdownMenuItem(
                          value: model,
                          child: Text(model),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _modelController.text = value;
                    });
                  }
                },
              );
            }
          )
        else
          const Text('未选择提供者'),
      ],
    );
  }
  
  /// 构建代理设置
  Widget _buildProxySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '代理设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('使用代理'),
          value: _useProxy,
          onChanged: (value) {
            setState(() {
              _useProxy = value;
            });
          },
        ),
        if (_useProxy) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _proxyHostController,
            decoration: const InputDecoration(
              labelText: '代理地址',
              hintText: '127.0.0.1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _proxyPortController,
            decoration: const InputDecoration(
              labelText: '代理端口',
              hintText: '1080',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '注意：使用Gemini API时通常需要配置代理',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('开发者模式'),
          subtitle: const Text('跳过API密钥验证，用于本地开发'),
          value: _devMode,
          onChanged: (value) {
            setState(() {
              _devMode = value;
            });
          },
        ),
      ],
    );
  }
  
  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _testConnection,
          style: OutlinedButton.styleFrom(
            foregroundColor: StandardTheme.accentColor,
          ),
          child: const Text('测试连接'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _saveConfig,
          style: ElevatedButton.styleFrom(
            backgroundColor: StandardTheme.accentColor,
          ),
          child: const Text('保存配置'),
        ),
      ],
    );
  }
  
  /// 获取API密钥帮助文本
  String _getApiKeyHelp() {
    if (_selectedProvider == null) {
      return '';
    }
    
    switch (_selectedProvider!) {
      case LLMProvider.gemini:
        return '请在Google AI Studio获取Gemini API密钥:\nhttps://makersuite.google.com/app/apikey';
      case LLMProvider.openAI:
        return '请在OpenAI平台获取API密钥:\nhttps://platform.openai.com/api-keys';
      case LLMProvider.mock:
        return '模拟服务无需真实API密钥，可输入任意值';
      case LLMProvider.custom:
        return '请根据您的自定义服务提供商要求输入API密钥';
    }
  }
} 