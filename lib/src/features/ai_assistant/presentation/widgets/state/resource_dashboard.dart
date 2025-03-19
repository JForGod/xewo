import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// 资源监控仪表盘
/// 
/// 一个具有Glassmorphism风格的资源监控仪表盘，展示AI助手的实时资源使用情况
/// 包括CPU、内存、网络和存储使用情况
class ResourceDashboard extends StatefulWidget {
  /// 资源数据
  final ResourceData resourceData;
  
  /// 更新间隔
  final Duration updateInterval;
  
  /// 警告阈值 (0.0 - 1.0)
  final double warningThreshold;
  
  /// 危险阈值 (0.0 - 1.0)
  final double dangerThreshold;
  
  /// 构造函数
  const ResourceDashboard({
    Key? key,
    required this.resourceData,
    this.updateInterval = const Duration(seconds: 1),
    this.warningThreshold = 0.7,
    this.dangerThreshold = 0.9,
  }) : super(key: key);

  @override
  State<ResourceDashboard> createState() => _ResourceDashboardState();
}

class _ResourceDashboardState extends State<ResourceDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutQuart,
        );
        
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
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
                  filter: ImageFilter.blur(sigmaX:, sigmaY: 20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        _buildMetricGrid(),
                        _buildSystemHealthIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '资源监控',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSystemHealthColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSystemHealthColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSystemHealthIcon(),
                  color: _getSystemHealthColor(),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getSystemHealthText(),
                  style: TextStyle(
                    color: _getSystemHealthColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建指标网格
  Widget _buildMetricGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMetricCard(
            'CPU',
            widget.resourceData.cpuUsage,
            Icons.memory,
            const Color(0xFF3A7BFF),
          ),
          _buildMetricCard(
            '内存',
            widget.resourceData.memoryUsage,
            Icons.storage,
            const Color(0xFF6B7BFF),
          ),
          _buildMetricCard(
            '网络',
            widget.resourceData.networkUsage,
            Icons.wifi,
            const Color(0xFF4CAF50),
          ),
          _buildMetricCard(
            '存储',
            widget.resourceData.storageUsage,
            Icons.sd_storage,
            const Color(0xFFFFC107),
          ),
        ],
      ),
    );
  }

  /// 构建指标卡片
  Widget _buildMetricCard(String title, double value, IconData icon, Color color) {
    final thresholdColor = _getThresholdColor(value);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: CustomPaint(
                size: const Size(double.infinity, 40),
                painter: MetricChartPainter(
                  value: value,
                  color: color,
                  thresholdColor: thresholdColor,
                  warning: widget.warningThreshold,
                  danger: widget.dangerThreshold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    color: thresholdColor.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildMetricTrend(title),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建指标趋势指示器
  Widget _buildMetricTrend(String metricType) {
    final trend = _getMetricTrend(metricType);
    final isUp = trend > 0;
    final color = isUp ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50);
    
    return Row(
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          color: color.withOpacity(0.9),
          size: 12,
        ),
        const SizedBox(width: 2),
        Text(
          '${trend.abs()}%',
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 构建系统健康指示器
  Widget _buildSystemHealthIndicator() {
    final healthScore = _calculateSystemHealth();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统健康度',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: Stack(
              children: [
                // 背景条
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                // 进度条
                FractionallySizedBox(
                  widthFactor: healthScore,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFFFFC107),
                          const Color(0xFFFF6B6B),
                        ],
                        stops: [
                          0.0,
                          widget.warningThreshold,
                          widget.dangerThreshold,
                        ],
                      ),
                    ),
                  ),
                ),
                // 指示器
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.5 * healthScore - 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSystemHealthColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getSystemHealthColor().withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${(healthScore * 100).toInt()}%',
                      style: TextStyle(
                        color: _getSystemHealthColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取阈值颜色
  Color _getThresholdColor(double value) {
    if (value >= widget.dangerThreshold) {
      return const Color(0xFFFF6B6B); // 危险
    } else if (value >= widget.warningThreshold) {
      return const Color(0xFFFFC107); // 警告
    } else {
      return const Color(0xFF4CAF50); // 正常
    }
  }

  /// 获取系统健康颜色
  Color _getSystemHealthColor() {
    final health = _calculateSystemHealth();
    return _getThresholdColor(1 - health);
  }

  /// 获取系统健康图标
  IconData _getSystemHealthIcon() {
    final health = _calculateSystemHealth();
    if (health > 0.8) {
      return Icons.check_circle;
    } else if (health > 0.6) {
      return Icons.info;
    } else {
      return Icons.warning;
    }
  }

  /// 获取系统健康文本
  String _getSystemHealthText() {
    final health = _calculateSystemHealth();
    if (health > 0.8) {
      return '良好';
    } else if (health > 0.6) {
      return '一般';
    } else {
      return '注意';
    }
  }

  /// 计算系统健康度
  double _calculateSystemHealth() {
    final cpuHealth = 1 - widget.resourceData.cpuUsage;
    final memoryHealth = 1 - widget.resourceData.memoryUsage;
    final networkHealth = 1 - widget.resourceData.networkUsage;
    final storageHealth = 1 - widget.resourceData.storageUsage;
    
    // 加权平均
    return (cpuHealth * 0.4 + memoryHealth * 0.3 + networkHealth * 0.2 + storageHealth * 0.1);
  }

  /// 获取指标趋势
  int _getMetricTrend(String metricType) {
    // 在实际应用中，这里应该返回真实的趋势数据
    // 这里仅为示例，返回一个随机值
    return math.Random().nextInt(10) - 5;
  }
}

/// 资源数据类
class ResourceData {
  /// CPU使用率 (0.0 - 1.0)
  final double cpuUsage;
  
  /// 内存使用率 (0.0 - 1.0)
  final double memoryUsage;
  
  /// 网络使用率 (0.0 - 1.0)
  final double networkUsage;
  
  /// 存储使用率 (0.0 - 1.0)
  final double storageUsage;
  
  /// 历史数据点
  final List<ResourceDataPoint> history;
  
  /// 构造函数
  const ResourceData({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkUsage,
    required this.storageUsage,
    this.history = const [],
  });
}

/// 资源数据点
class ResourceDataPoint {
  /// 时间戳
  final DateTime timestamp;
  
  /// CPU使用率
  final double cpuUsage;
  
  /// 内存使用率
  final double memoryUsage;
  
  /// 网络使用率
  final double networkUsage;
  
  /// 存储使用率
  final double storageUsage;
  
  /// 构造函数
  const ResourceDataPoint({
    required this.timestamp,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkUsage,
    required this.storageUsage,
  });
}

/// 指标图表绘制器
class MetricChartPainter extends CustomPainter {
  /// 当前值
  final double value;
  
  /// 主色调
  final Color color;
  
  /// 阈值颜色
  final Color thresholdColor;
  
  /// 警告阈值
  final double warning;
  
  /// 危险阈值
  final double danger;
  
  /// 构造函数
  const MetricChartPainter({
    required this.value,
    required this.color,
    required this.thresholdColor,
    required this.warning,
    required this.danger,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
      
    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    
    canvas.drawRRect(backgroundRect, backgroundPaint);
    
    // 绘制指标条
    final metricPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.6),
          thresholdColor.withOpacity(0.9),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    final metricRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * value, size.height),
      const Radius.circular(8),
    );
    
    canvas.drawRRect(metricRect, metricPaint);
    
    // 绘制警告和危险阈值线
    final thresholdPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    // 警告线
    canvas.drawLine(
      Offset(size.width * warning, 0),
      Offset(size.width * warning, size.height),
      thresholdPaint,
    );
    
    // 危险线
    canvas.drawLine(
      Offset(size.width * danger, 0),
      Offset(size.width * danger, size.height),
      thresholdPaint,
    );
  }

  @override
  bool shouldRepaint(MetricChartPainter oldDelegate) {
    return oldDelegate.value != value || 
           oldDelegate.color != color ||
           oldDelegate.thresholdColor != thresholdColor;
  }
} 