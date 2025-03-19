import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// 沙盒状态组件
/// 
/// 一个具有Glassmorphism风格的沙盒状态组件，展示沙盒环境的运行状态
/// 包括活跃沙盒、资源使用、安全事件等
class SandboxStatus extends StatefulWidget {
  /// 沙盒数据
  final SandboxData sandboxData;
  
  /// 是否展开
  final bool isExpanded;
  
  /// 展开状态变更回调
  final Function(bool) onExpandChanged;
  
  /// 构造函数
  const SandboxStatus({
    Key? key,
    required this.sandboxData,
    this.isExpanded = false,
    required this.onExpandChanged,
  }) : super(key: key);

  @override
  State<SandboxStatus> createState() => _SandboxStatusState();
}

class _SandboxStatusState extends State<SandboxStatus> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightFactor;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _heightFactor = _animationController.drive(CurveTween(curve: Curves.easeInOut));
    
    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(SandboxStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        heightFactor: _heightFactor.value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildExpandedContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return InkWell(
      onTap: () => widget.onExpandChanged(!widget.isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  '沙盒环境',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator() {
    Color color;
    String text;
    
    if (widget.sandboxData.securityLevel == SecurityLevel.high) {
      color = const Color(0xFF4CAF50); // 高安全级别
      text = '安全';
    } else if (widget.sandboxData.securityLevel == SecurityLevel.medium) {
      color = const Color(0xFFFFC107); // 中安全级别
      text = '标准';
    } else {
      color = const Color(0xFFFF6B6B); // 低安全级别
      text = '开放';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSecurityIcon(),
            color: color.withOpacity(0.9),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建展开内容
  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveSandboxes(),
          const SizedBox(height: 16),
          _buildResourceUsage(),
          const SizedBox(height: 16),
          _buildSecurityEvents(),
        ],
      ),
    );
  }

  /// 构建活跃沙盒
  Widget _buildActiveSandboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '活跃沙盒 (${widget.sandboxData.activeSandboxes.length})',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: widget.sandboxData.activeSandboxes.map((sandbox) =>
            _buildSandboxItem(sandbox),
          ).toList(),
        ),
      ],
    );
  }

  /// 构建沙盒项
  Widget _buildSandboxItem(ActiveSandbox sandbox) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getSandboxTypeColor(sandbox.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getSandboxTypeColor(sandbox.type).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  _getSandboxTypeIcon(sandbox.type),
                  color: _getSandboxTypeColor(sandbox.type).withOpacity(0.9),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sandbox.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '工具: ${sandbox.tool} • 运行时间: ${sandbox.runningTime}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建资源使用
  Widget _buildResourceUsage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '资源使用',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildResourceItem(
                'CPU',
                widget.sandboxData.cpuUsage,
                const Color(0xFF3A7BFF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResourceItem(
                '内存',
                widget.sandboxData.memoryUsage,
                const Color(0xFF6B7BFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildResourceItem(
                '网络',
                widget.sandboxData.networkUsage,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResourceItem(
                '磁盘',
                widget.sandboxData.diskUsage,
                const Color(0xFFFFC107),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建资源项
  Widget _buildResourceItem(String name, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建安全事件
  Widget _buildSecurityEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '安全事件',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                '今日: ${widget.sandboxData.securityEvents.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: widget.sandboxData.securityEvents.map((event) =>
            _buildSecurityEventItem(event),
          ).toList(),
        ),
      ],
    );
  }

  /// 构建安全事件项
  Widget _buildSecurityEventItem(SecurityEvent event) {
    Color severityColor;
    
    switch (event.severity) {
      case EventSeverity.low:
        severityColor = const Color(0xFF4CAF50); // 低风险
        break;
      case EventSeverity.medium:
        severityColor = const Color(0xFFFFC107); // 中风险
        break;
      case EventSeverity.high:
        severityColor = const Color(0xFFFF6B6B); // 高风险
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: severityColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: severityColor.withOpacity(0.2),
                border: Border.all(
                  color: severityColor.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  _getEventIcon(event.type),
                  color: severityColor.withOpacity(0.9),
                  size: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.timestamp,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取安全图标
  IconData _getSecurityIcon() {
    switch (widget.sandboxData.securityLevel) {
      case SecurityLevel.high:
        return Icons.security;
      case SecurityLevel.medium:
        return Icons.shield;
      case SecurityLevel.low:
        return Icons.shield_outlined;
    }
  }

  /// 获取沙盒类型颜色
  Color _getSandboxTypeColor(SandboxType type) {
    switch (type) {
      case SandboxType.container:
        return const Color(0xFF3A7BFF); // 蓝色
      case SandboxType.vm:
        return const Color(0xFF4CAF50); // 绿色
      case SandboxType.process:
        return const Color(0xFFFFC107); // 黄色
    }
  }

  /// 获取沙盒类型图标
  IconData _getSandboxTypeIcon(SandboxType type) {
    switch (type) {
      case SandboxType.container:
        return Icons.category;
      case SandboxType.vm:
        return Icons.computer;
      case SandboxType.process:
        return Icons.memory;
    }
  }

  /// 获取事件图标
  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.accessViolation:
        return Icons.no_encryption;
      case EventType.resourceLimit:
        return Icons.warning;
      case EventType.networkAccess:
        return Icons.wifi;
    }
  }
}

/// 沙盒数据类
class SandboxData {
  /// 安全级别
  final SecurityLevel securityLevel;
  
  /// CPU使用率 (0.0 - 1.0)
  final double cpuUsage;
  
  /// 内存使用率 (0.0 - 1.0)
  final double memoryUsage;
  
  /// 网络使用率 (0.0 - 1.0)
  final double networkUsage;
  
  /// 磁盘使用率 (0.0 - 1.0)
  final double diskUsage;
  
  /// 活跃沙盒列表
  final List<ActiveSandbox> activeSandboxes;
  
  /// 安全事件列表
  final List<SecurityEvent> securityEvents;
  
  /// 构造函数
  const SandboxData({
    required this.securityLevel,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkUsage,
    required this.diskUsage,
    required this.activeSandboxes,
    required this.securityEvents,
  });
}

/// 活跃沙盒类
class ActiveSandbox {
  /// 沙盒ID
  final String id;
  
  /// 沙盒名称
  final String name;
  
  /// 沙盒类型
  final SandboxType type;
  
  /// 工具名称
  final String tool;
  
  /// 运行时间
  final String runningTime;
  
  /// 构造函数
  const ActiveSandbox({
    required this.id,
    required this.name,
    required this.type,
    required this.tool,
    required this.runningTime,
  });
}

/// 安全事件类
class SecurityEvent {
  /// 事件标题
  final String title;
  
  /// 事件描述
  final String description;
  
  /// 时间戳
  final String timestamp;
  
  /// 事件类型
  final EventType type;
  
  /// 事件严重级别
  final EventSeverity severity;
  
  /// 构造函数
  const SecurityEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.severity,
  });
}

/// 沙盒类型枚举
enum SandboxType {
  /// 容器
  container,
  
  /// 虚拟机
  vm,
  
  /// 进程
  process,
}

/// 事件类型枚举
enum EventType {
  /// 访问违规
  accessViolation,
  
  /// 资源限制
  resourceLimit,
  
  /// 网络访问
  networkAccess,
}

/// 事件严重程度枚举
enum EventSeverity {
  /// 低风险
  low,
  
  /// 中风险
  medium,
  
  /// 高风险
  high,
}

/// 安全级别枚举
enum SecurityLevel {
  /// 低安全级别
  low,
  
  /// 中安全级别
  medium,
  
  /// 高安全级别
  high,
} 