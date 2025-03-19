import 'package:flutter/material.dart';
import 'dart:ui';

/// 安全策略配置组件
/// 
/// 一个具有Glassmorphism风格的安全策略配置组件，用于设置和管理沙盒安全策略
/// 包括安全级别设置、权限管理、网络规则等
class SecurityConfig extends StatefulWidget {
  /// 安全策略数据
  final SecurityPolicyData policyData;
  
  /// 安全策略变更回调
  final Function(SecurityPolicyData) onPolicyChanged;
  
  /// 构造函数
  const SecurityConfig({
    Key? key,
    required this.policyData,
    required this.onPolicyChanged,
  }) : super(key: key);

  @override
  State<SecurityConfig> createState() => _SecurityConfigState();
}

class _SecurityConfigState extends State<SecurityConfig> with SingleTickerProviderStateMixin {
  late SecurityPolicyData _currentPolicy;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _currentPolicy = widget.policyData;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(SecurityConfig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.policyData != oldWidget.policyData) {
      setState(() {
        _currentPolicy = widget.policyData;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSecurityLevelSlider(),
                    const SizedBox(height: 24),
                    _buildPermissionMatrix(),
                    const SizedBox(height: 24),
                    _buildNetworkRules(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.security,
              color: const Color(0xFF3A7BFF).withOpacity(0.9),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '安全策略配置',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        _buildProfileSelector(),
      ],
    );
  }

  /// 构建配置选择器
  Widget _buildProfileSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: _currentPolicy.profileName,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.white.withOpacity(0.7),
        ),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
        underline: Container(
          height: 0,
        ),
        dropdownColor: Colors.black.withOpacity(0.8),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _currentPolicy = _getPresetProfile(newValue);
            });
            widget.onPolicyChanged(_currentPolicy);
          }
        },
        items: ['严格', '标准', '开放', '自定义'].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  /// 构建安全级别滑块
  Widget _buildSecurityLevelSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '安全级别',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            // 背景条
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B), // 红色 (低安全)
                    const Color(0xFFFFC107), // 黄色 (中安全)
                    const Color(0xFF4CAF50), // 绿色 (高安全)
                  ],
                ),
              ),
            ),
            // 滑块
            SliderTheme(
              data: SliderThemeData(
                thumbShape: _GlassThumbShape(
                  enabledThumbRadius: 16,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 24,
                ),
                trackHeight: 8,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white.withOpacity(0.9),
                overlayColor: Colors.white.withOpacity(0.2),
              ),
              child: Slider(
                value: _currentPolicy.securityLevel,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    _currentPolicy = _currentPolicy.copyWith(
                      securityLevel: value,
                      profileName: '自定义',
                    );
                  });
                  widget.onPolicyChanged(_currentPolicy);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '开放',
              style: TextStyle(
                color: const Color(0xFFFF6B6B).withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              '标准',
              style: TextStyle(
                color: const Color(0xFFFFC107).withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              '严格',
              style: TextStyle(
                color: const Color(0xFF4CAF50).withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建权限矩阵
  Widget _buildPermissionMatrix() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '权限管理',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildPermissionToggle(
              '文件系统访问',
              _currentPolicy.fileSystemAccess,
              (value) {
                setState(() {
                  _currentPolicy = _currentPolicy.copyWith(
                    fileSystemAccess: value,
                    profileName: '自定义',
                  );
                });
                widget.onPolicyChanged(_currentPolicy);
              },
            ),
            _buildPermissionToggle(
              '网络访问',
              _currentPolicy.networkAccess,
              (value) {
                setState(() {
                  _currentPolicy = _currentPolicy.copyWith(
                    networkAccess: value,
                    profileName: '自定义',
                  );
                });
                widget.onPolicyChanged(_currentPolicy);
              },
            ),
            _buildPermissionToggle(
              '系统调用',
              _currentPolicy.systemCallsAccess,
              (value) {
                setState(() {
                  _currentPolicy = _currentPolicy.copyWith(
                    systemCallsAccess: value,
                    profileName: '自定义',
                  );
                });
                widget.onPolicyChanged(_currentPolicy);
              },
            ),
            _buildPermissionToggle(
              '进程管理',
              _currentPolicy.processManagement,
              (value) {
                setState(() {
                  _currentPolicy = _currentPolicy.copyWith(
                    processManagement: value,
                    profileName: '自定义',
                  );
                });
                widget.onPolicyChanged(_currentPolicy);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// 构建网络规则
  Widget _buildNetworkRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '网络规则',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildRuleItem(
                '出站连接',
                _currentPolicy.outboundConnection ? '允许' : '禁止',
                (value) {
                  setState(() {
                    _currentPolicy = _currentPolicy.copyWith(
                      outboundConnection: value,
                      profileName: '自定义',
                    );
                  });
                  widget.onPolicyChanged(_currentPolicy);
                },
                _currentPolicy.outboundConnection,
              ),
              const Divider(color: Colors.white24),
              _buildRuleItem(
                '入站连接',
                _currentPolicy.inboundConnection ? '允许' : '禁止',
                (value) {
                  setState(() {
                    _currentPolicy = _currentPolicy.copyWith(
                      inboundConnection: value,
                      profileName: '自定义',
                    );
                  });
                  widget.onPolicyChanged(_currentPolicy);
                },
                _currentPolicy.inboundConnection,
              ),
              const Divider(color: Colors.white24),
              _buildRuleItem(
                'DNS解析',
                _currentPolicy.dnsResolution ? '允许' : '禁止',
                (value) {
                  setState(() {
                    _currentPolicy = _currentPolicy.copyWith(
                      dnsResolution: value,
                      profileName: '自定义',
                    );
                  });
                  widget.onPolicyChanged(_currentPolicy);
                },
                _currentPolicy.dnsResolution,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建动作按钮
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildGlassButton(
          '重置',
          Colors.grey,
          () {
            setState(() {
              _currentPolicy = widget.policyData;
            });
          },
        ),
        const SizedBox(width: 16),
        _buildGlassButton(
          '应用',
          const Color(0xFF3A7BFF),
          () {
            widget.onPolicyChanged(_currentPolicy);
          },
        ),
      ],
    );
  }

  /// 构建权限开关
  Widget _buildPermissionToggle(String name, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3A7BFF),
            inactiveThumbColor: Colors.grey,
            activeTrackColor: const Color(0xFF3A7BFF).withOpacity(0.3),
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// 构建规则项
  Widget _buildRuleItem(String name, String status, Function(bool) onChanged, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (value ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B)).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (value ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B)).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: (value ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B)).withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF3A7BFF),
                inactiveThumbColor: Colors.grey,
                activeTrackColor: const Color(0xFF3A7BFF).withOpacity(0.3),
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建玻璃按钮
  Widget _buildGlassButton(String text, Color color, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 获取预设配置
  SecurityPolicyData _getPresetProfile(String profileName) {
    switch (profileName) {
      case '严格':
        return SecurityPolicyData(
          profileName: '严格',
          securityLevel: 0.9,
          fileSystemAccess: false,
          networkAccess: false,
          systemCallsAccess: false,
          processManagement: false,
          outboundConnection: false,
          inboundConnection: false,
          dnsResolution: true,
        );
      case '标准':
        return SecurityPolicyData(
          profileName: '标准',
          securityLevel: 0.5,
          fileSystemAccess: true,
          networkAccess: true,
          systemCallsAccess: false,
          processManagement: false,
          outboundConnection: true,
          inboundConnection: false,
          dnsResolution: true,
        );
      case '开放':
        return SecurityPolicyData(
          profileName: '开放',
          securityLevel: 0.1,
          fileSystemAccess: true,
          networkAccess: true,
          systemCallsAccess: true,
          processManagement: true,
          outboundConnection: true,
          inboundConnection: true,
          dnsResolution: true,
        );
      default:
        return _currentPolicy;
    }
  }
}

/// 玻璃滑块形状
class _GlassThumbShape extends SliderComponentShape {
  /// 启用状态下的滑块半径
  final double enabledThumbRadius;
  
  /// 禁用状态下的滑块半径
  final double? disabledThumbRadius;
  
  /// 构造函数
  const _GlassThumbShape({
    required this.enabledThumbRadius,
    this.disabledThumbRadius,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
      isEnabled ? enabledThumbRadius : (disabledThumbRadius ?? enabledThumbRadius),
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final radius = enabledThumbRadius;
    
    // 绘制外部阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
    canvas.drawCircle(center, radius + 2, shadowPaint);
    
    // 绘制磨砂玻璃效果
    final thumbPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, radius, thumbPaint);
    
    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    canvas.drawCircle(center, radius, borderPaint);
    
    // 绘制高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3),
      -0.8,
      1.5,
      false,
      highlightPaint,
    );
  }
}

/// 安全策略数据类
class SecurityPolicyData {
  /// 配置文件名称
  final String profileName;
  
  /// 安全级别 (0.0 - 1.0)
  final double securityLevel;
  
  /// 文件系统访问
  final bool fileSystemAccess;
  
  /// 网络访问
  final bool networkAccess;
  
  /// 系统调用访问
  final bool systemCallsAccess;
  
  /// 进程管理
  final bool processManagement;
  
  /// 出站连接
  final bool outboundConnection;
  
  /// 入站连接
  final bool inboundConnection;
  
  /// DNS解析
  final bool dnsResolution;
  
  /// 构造函数
  const SecurityPolicyData({
    required this.profileName,
    required this.securityLevel,
    required this.fileSystemAccess,
    required this.networkAccess,
    required this.systemCallsAccess,
    required this.processManagement,
    required this.outboundConnection,
    required this.inboundConnection,
    required this.dnsResolution,
  });
  
  /// 创建副本
  SecurityPolicyData copyWith({
    String? profileName,
    double? securityLevel,
    bool? fileSystemAccess,
    bool? networkAccess,
    bool? systemCallsAccess,
    bool? processManagement,
    bool? outboundConnection,
    bool? inboundConnection,
    bool? dnsResolution,
  }) {
    return SecurityPolicyData(
      profileName: profileName ?? this.profileName,
      securityLevel: securityLevel ?? this.securityLevel,
      fileSystemAccess: fileSystemAccess ?? this.fileSystemAccess,
      networkAccess: networkAccess ?? this.networkAccess,
      systemCallsAccess: systemCallsAccess ?? this.systemCallsAccess,
      processManagement: processManagement ?? this.processManagement,
      outboundConnection: outboundConnection ?? this.outboundConnection,
      inboundConnection: inboundConnection ?? this.inboundConnection,
      dnsResolution: dnsResolution ?? this.dnsResolution,
    );
  }
} 