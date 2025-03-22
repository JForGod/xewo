// 2025-03-22: 新增 - 创建视觉输入设置标签页，支持图像识别和分析功能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../themes/standard_theme.dart';

/// 视觉模型类型
enum VisionModelType {
  /// 本地轻量级模型
  localLight,
  
  /// 云端高精度模型
  cloudHigh,
  
  /// GPT-4 Vision
  gpt4Vision,
  
  /// Gemini Vision
  geminiVision,
  
  /// 自定义视觉模型
  custom
}

/// 图像处理模式
enum ImageProcessingMode {
  /// 一般模式（低质量，低资源消耗）
  general,
  
  /// 高精度模式（高质量，高资源消耗）
  highPrecision,
  
  /// 节能模式（有限精度，低资源消耗）
  powerSaving
}

/// 视觉输入设置标签页
class VisualInputSettingsTab extends ConsumerStatefulWidget {
  /// 构造函数
  const VisualInputSettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<VisualInputSettingsTab> createState() => _VisualInputSettingsTabState();
}

class _VisualInputSettingsTabState extends ConsumerState<VisualInputSettingsTab> {
  /// 是否启用视觉输入
  bool _enableVisualInput = false;
  
  /// 是否启用图像处理
  bool _enableImageProcessing = false;
  
  /// 是否启用屏幕捕获
  bool _enableScreenCapture = false;
  
  /// 是否启用图像分析
  bool _enableImageAnalysis = false;
  
  /// 当前选择的视觉模型类型
  VisionModelType _selectedVisionModel = VisionModelType.geminiVision;
  
  /// 当前选择的图像处理模式
  ImageProcessingMode _selectedImageProcessingMode = ImageProcessingMode.general;
  
  /// API密钥控制器
  final TextEditingController _apiKeyController = TextEditingController();
  
  /// 自定义模型URL控制器
  final TextEditingController _customModelUrlController = TextEditingController();
  
  /// API密钥是否可见
  bool _isApiKeyVisible = false;
  
  /// 图像分辨率控制器
  final TextEditingController _resolutionController = TextEditingController(text: '720');
  
  /// 图像质量控制器（百分比）
  final TextEditingController _qualityController = TextEditingController(text: '90');
  
  @override
  void initState() {
    super.initState();
    _loadVisualSettings();
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelUrlController.dispose();
    _resolutionController.dispose();
    _qualityController.dispose();
    super.dispose();
  }
  
  /// 2025-03-22: 新增 - 加载视觉设置
  Future<void> _loadVisualSettings() async {
    // TODO: 从设置服务中加载视觉设置
    // 示例代码，实际实现需要加载保存的设置
    setState(() {
      _enableVisualInput = true;
      _enableImageProcessing = true;
      _enableScreenCapture = true;
      _enableImageAnalysis = true;
      _selectedVisionModel = VisionModelType.geminiVision;
      _selectedImageProcessingMode = ImageProcessingMode.general;
    });
  }
  
  /// 2025-03-22: 新增 - 保存视觉设置
  Future<void> saveSettings() async {
    // TODO: 将当前设置保存到设置服务
    // 示例代码，实际实现需要保存设置到持久化存储
    
    // 显示保存成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视觉设置已保存')),
      );
    }
  }
  
  /// 2025-03-22: 新增 - 构建视觉输入开关UI
  Widget _buildVisualInputSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('启用视觉输入'),
          subtitle: const Text('允许AI分析图像内容'),
          value: _enableVisualInput,
          onChanged: (value) {
            setState(() {
              _enableVisualInput = value;
              if (!value) {
                // 禁用子选项
                _enableImageProcessing = false;
                _enableScreenCapture = false;
                _enableImageAnalysis = false;
              }
            });
          },
          tileColor: const Color(0xFF2A2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (_enableVisualInput) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SwitchListTile(
              title: const Text('启用图像处理'),
              subtitle: const Text('处理上传图像以优化分析'),
              value: _enableImageProcessing,
              onChanged: (value) {
                setState(() {
                  _enableImageProcessing = value;
                });
              },
              tileColor: const Color(0xFF2A2A38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SwitchListTile(
              title: const Text('启用屏幕捕获'),
              subtitle: const Text('允许AI分析屏幕内容'),
              value: _enableScreenCapture,
              onChanged: (value) {
                setState(() {
                  _enableScreenCapture = value;
                });
              },
              tileColor: const Color(0xFF2A2A38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SwitchListTile(
              title: const Text('启用图像分析'),
              subtitle: const Text('允许AI检测和描述图像中的内容'),
              value: _enableImageAnalysis,
              onChanged: (value) {
                setState(() {
                  _enableImageAnalysis = value;
                });
              },
              tileColor: const Color(0xFF2A2A38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 构建视觉模型选择UI
  Widget _buildVisionModelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '视觉模型选择',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VisionModelType.values.map((model) {
            final isSelected = _selectedVisionModel == model;
            String label;
            switch (model) {
              case VisionModelType.localLight:
                label = '本地轻量级';
                break;
              case VisionModelType.cloudHigh:
                label = '云端高精度';
                break;
              case VisionModelType.gpt4Vision:
                label = 'GPT-4 Vision';
                break;
              case VisionModelType.geminiVision:
                label = 'Gemini Vision';
                break;
              case VisionModelType.custom:
                label = '自定义模型';
                break;
            }
            
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedVisionModel = model;
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: StandardTheme.accentColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getVisionModelDescription(_selectedVisionModel),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        
        if (_selectedVisionModel == VisionModelType.custom) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customModelUrlController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '自定义模型URL',
              fillColor: Color(0xFF2A2A38),
              filled: true,
              labelStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
        
        if (_selectedVisionModel == VisionModelType.cloudHigh ||
            _selectedVisionModel == VisionModelType.gpt4Vision ||
            _selectedVisionModel == VisionModelType.geminiVision) ...[
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
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取视觉模型描述
  String _getVisionModelDescription(VisionModelType model) {
    switch (model) {
      case VisionModelType.localLight:
        return '使用本地轻量级视觉模型，无需网络连接，但精度和功能有限';
      case VisionModelType.cloudHigh:
        return '使用云端高精度视觉模型，需要网络连接，提供更高的识别精度';
      case VisionModelType.gpt4Vision:
        return '使用OpenAI的GPT-4 Vision模型，需要API密钥，提供先进的图像理解能力';
      case VisionModelType.geminiVision:
        return '使用Google的Gemini Vision模型，需要API密钥，具有强大的多模态理解能力';
      case VisionModelType.custom:
        return '使用自定义视觉模型，需要提供API端点URL';
    }
  }
  
  /// 2025-03-22: 新增 - 构建图像处理模式选择UI
  Widget _buildImageProcessingModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '图像处理模式',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ImageProcessingMode.values.map((mode) {
            final isSelected = _selectedImageProcessingMode == mode;
            String label;
            switch (mode) {
              case ImageProcessingMode.general:
                label = '一般模式';
                break;
              case ImageProcessingMode.highPrecision:
                label = '高精度模式';
                break;
              case ImageProcessingMode.powerSaving:
                label = '节能模式';
                break;
            }
            
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedImageProcessingMode = mode;
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: StandardTheme.accentColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getImageProcessingModeDescription(_selectedImageProcessingMode),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 获取图像处理模式描述
  String _getImageProcessingModeDescription(ImageProcessingMode mode) {
    switch (mode) {
      case ImageProcessingMode.general:
        return '平衡图像质量和资源消耗，适合大多数场景';
      case ImageProcessingMode.highPrecision:
        return '提供最高质量的图像处理，但会消耗更多资源';
      case ImageProcessingMode.powerSaving:
        return '最小化资源消耗，适合电池供电设备，但会降低图像质量';
    }
  }
  
  /// 2025-03-22: 新增 - 构建高级图像设置UI
  Widget _buildAdvancedImageSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '高级图像设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _resolutionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '最大分辨率',
                  hintText: '输入像素高度',
                  fillColor: Color(0xFF2A2A38),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.grey),
                  suffixText: 'px',
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _qualityController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '图像质量',
                  hintText: '输入百分比',
                  fillColor: Color(0xFF2A2A38),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.grey),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '较低的分辨率和质量可以提高处理速度，但会影响图像分析的准确性',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  /// 2025-03-22: 新增 - 构建测试按钮UI
  Widget _buildTestButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: 实现视觉模型测试功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开始视觉模型测试...')),
        );
      },
      icon: const Icon(Icons.camera_alt),
      label: const Text('测试视觉功能'),
      style: ElevatedButton.styleFrom(
        backgroundColor: StandardTheme.accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVisualInputSwitch(),
          if (_enableVisualInput) ...[
            const SizedBox(height: 24),
            _buildVisionModelSelection(),
            const SizedBox(height: 24),
            _buildImageProcessingModeSelection(),
            const SizedBox(height: 24),
            _buildAdvancedImageSettings(),
            const SizedBox(height: 24),
            _buildTestButton(),
          ],
        ],
      ),
    );
  }
} 