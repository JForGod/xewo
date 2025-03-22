// 2025-03-22: 新增 - 创建LLM设置标签页，基于现有的LLM配置页面内容

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../themes/standard_theme.dart';
import '../../../widgets/floating_test_dialog.dart';
import '../../../../../../core/ai_engine/llm/llm_config_service.dart';
import '../../../../../../core/ai_engine/llm/llm_service_provider.dart';
import '../../../../../../core/ai_engine/llm/gemini_models.dart';

/// LLM设置标签页
class LLMSettingsTab extends ConsumerStatefulWidget {
  /// 构造函数
  const LLMSettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<LLMSettingsTab> createState() => _LLMSettingsTabState();
}

class _LLMSettingsTabState extends ConsumerState<LLMSettingsTab> {
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
  bool _useProxy = false;
  
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
  
  /// 2025-03-22: 新增 - 加载LLM配置
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载配置失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 2025-03-22: 新增 - 保存LLM配置
  Future<void> saveSettings() async {
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
  }
  
  /// 2025-03-22: 新增 - 切换LLM提供者
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
  
  /// 2025-03-22: 新增 - 测试LLM连接
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
  
  /// 2025-03-22: 新增 - 显示测试结果
  void _showTestResult(bool success, String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
  
  /// 2025-03-22: 新增 - 构建提供者选择UI
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
          runSpacing: 8,
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
  
  /// 2025-03-22: 新增 - 构建模型选择UI
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
  
  /// 2025-03-22: 新增 - 构建API密钥输入UI
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
            fillColor: const Color(0xFF2A2A38),
            filled: true,
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
        if (_devMode)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              '开发者模式已启用，API密钥验证已跳过',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 构建代理设置UI
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
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (_useProxy) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _proxyHostController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '代理主机',
              fillColor: Color(0xFF2A2A38),
              filled: true,
              labelStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _proxyPortController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '代理端口',
              fillColor: Color(0xFF2A2A38),
              filled: true,
              labelStyle: TextStyle(color: Colors.grey),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 构建开发者选项UI
  Widget _buildDeveloperOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '开发者选项',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('开发者模式'),
          subtitle: const Text('跳过API密钥验证'),
          value: _devMode,
          onChanged: (value) {
            setState(() {
              _devMode = value;
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _showTestDialog = true;
            });
          },
          icon: const Icon(Icons.wifi_tethering),
          label: const Text('测试连接'),
          style: ElevatedButton.styleFrom(
            backgroundColor: StandardTheme.accentColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                    const SizedBox(height: 24),
                    _buildDeveloperOptions(),
                  ],
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