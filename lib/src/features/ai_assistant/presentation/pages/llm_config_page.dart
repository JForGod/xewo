// 2025-03-17: 新增 - LLM配置页面
// 2025-03-20: 修改 - 添加模型选择,移动按钮位置,集成悬浮测试对话框

import 'dart:async';  // 添加此行导入TimeoutException
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/standard_theme.dart';
import '../../../../core/ai_engine/llm/llm_config_service.dart';
import '../../../../core/ai_engine/llm/llm_service_provider.dart';
import '../../../../core/ai_engine/llm/gemini_models.dart';
import '../widgets/floating_test_dialog.dart';

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
  
  /// 是否显示测试对话框
  bool _showTestDialog = false;
  
  /// 当前选择的Gemini模型
  GeminiModel _selectedGeminiModel = GeminiModel.gemini15Pro;
  
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
      if (config.containsKey('model')) {
        final modelId = config['model'] as String;
        _selectedGeminiModel = GeminiModel.fromModelId(modelId) ?? GeminiModel.gemini15Pro;
        _modelController.text = _selectedGeminiModel.modelId;
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
    await _configService!.saveConfig(_selectedProvider!, {
      'model': _selectedGeminiModel.modelId,
    });
    
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
      if (config.containsKey('model')) {
        final modelId = config['model'] as String;
        _selectedGeminiModel = GeminiModel.fromModelId(modelId) ?? GeminiModel.gemini15Pro;
        _modelController.text = _selectedGeminiModel.modelId;
      } else {
        _selectedGeminiModel = GeminiModel.gemini15Pro;
        _modelController.text = _selectedGeminiModel.modelId;
      }
    });
  }
  
  /// 测试连接
  Future<void> _testConnection() async {
    if (_selectedProvider == null || _configService == null) {
      return;
    }
    
    try {
      // 临时保存当前配置
      await _configService!.saveApiKey(
        _selectedProvider!,
        _apiKeyController.text,
      );
      
      // 保存模型配置
      await _configService!.saveConfig(
        _selectedProvider!,
        {'model': _selectedGeminiModel.modelId},
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
      
      bool? success;
      try {
        success = await Future.any([
          llmService.testConnection(),
          Future.delayed(const Duration(seconds: 30)).then((_) => null),
        ]);
      } catch (e) {
        if (e is TimeoutException) {
          throw TimeoutException('API连接测试超时,请检查网络连接或代理设置');
        } else {
          _showTestResult(false, "连接测试错误: ${e.toString()}");
          return;
        }
      }
      
      if (success == null) {
        throw TimeoutException('API连接测试超时,请检查网络连接或代理设置');
      }
      
      if (success) {
        String? sessionResponse;
        try {
          sessionResponse = await Future.any([
            llmService.sessionTest(),
            Future.delayed(const Duration(seconds: 30)).then((_) => null),
          ]);
        } catch (e) {
          sessionResponse = null;
        }
        
        if (sessionResponse == null) {
          throw TimeoutException('会话测试超时,请检查网络连接或代理设置');
        }
        
        _showTestResult(true, "会话测试成功:\n$sessionResponse");
      } else {
        _showTestResult(false, "连接测试失败");
      }
    } on TimeoutException catch (e) {
      _showTestResult(false, e.message ?? "API请求超时");
    } catch (e) {
      _showTestResult(false, "错误：${e.toString()}");
    }
  }
  
  /// 显示测试结果
  void _showTestResult(bool success, String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
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
  
  /// 构建模型选择
  Widget _buildModelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模型选择',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<GeminiModel>(
          value: _selectedGeminiModel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fillColor: Color(0xFF2A2A38),
            filled: true,
          ),
          items: GeminiModel.values.map((model) {
            return DropdownMenuItem(
              value: model,
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      model.modelId,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (model) {
            if (model != null) {
              setState(() {
                _selectedGeminiModel = model;
                _modelController.text = model.modelId;
              });
            }
          },
          isExpanded: true,
          itemHeight: 60,
          dropdownColor: const Color(0xFF2A2A38),
          menuMaxHeight: 300,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          selectedItemBuilder: (BuildContext context) {
            return GeminiModel.values.map<Widget>((GeminiModel model) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  model.modelId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
        ),
        if (_selectedGeminiModel.isExperimental)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '注意：这是一个实验性模型',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '推荐用途：${_selectedGeminiModel.recommendedUse}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
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
        TextFormField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: '请输入API密钥',
            suffixIcon: IconButton(
              icon: Icon(
                _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isApiKeyVisible = !_isApiKeyVisible;
                });
              },
            ),
          ),
          obscureText: !_isApiKeyVisible,
        ),
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
          TextFormField(
            controller: _proxyHostController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '代理主机',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _proxyPortController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '代理端口',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ],
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('LLM配置'),
            actions: [
              // 测试连接按钮
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showTestDialog = true;
                  });
                },
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('测试连接'),
              ),
              const SizedBox(width: 8),
              // 保存配置按钮
              TextButton.icon(
                onPressed: _saveConfig,
                icon: const Icon(Icons.save),
                label: const Text('保存配置'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProviderSelection(),
                const SizedBox(height: 24),
                _buildModelSelection(),
                const SizedBox(height: 24),
                _buildApiKeyInput(),
                const SizedBox(height: 24),
                _buildProxySettings(),
              ],
            ),
          ),
        ),
        if (_showTestDialog)
          FloatingTestDialog(
            onTest: _testConnection,
            onClose: () {
              setState(() {
                _showTestDialog = false;
              });
            },
          ),
      ],
    );
  }
} 