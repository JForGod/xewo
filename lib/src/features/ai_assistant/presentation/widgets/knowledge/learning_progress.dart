import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// 学习进度展示
/// 
/// 一个具有Glassmorphism风格的学习进度展示组件，显示各维度的学习进度
/// 包括环形进度条和雷达图等多种可视化方式
class LearningProgress extends StatefulWidget {
  /// 学习进度数据
  final LearningProgressData progressData;
  
  /// 是否展开
  final bool isExpanded;
  
  /// 展开状态变更回调
  final Function(bool) onExpandChanged;
  
  /// 构造函数
  const LearningProgress({
    Key? key,
    required this.progressData,
    this.isExpanded = true,
    required this.onExpandChanged,
  }) : super(key: key);

  @override
  State<LearningProgress> createState() => _LearningProgressState();
}

class _LearningProgressState extends State<LearningProgress> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    
    _animationController.forward();
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
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: widget.isExpanded 
                      ? CrossFadeState.showFirst 
                      : CrossFadeState.showSecond,
                  firstChild: _buildExpandedContent(),
                  secondChild: const SizedBox(height: 0),
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
                  Icons.school,
                  color: const Color(0xFF3A7BFF).withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '学习进度',
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
                _buildOverallProgressIndicator(),
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

  /// 构建总体进度指示器
  Widget _buildOverallProgressIndicator() {
    final overallProgress = widget.progressData.overallProgress;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: CircularProgressPainter(
              progress: overallProgress * _progressAnimation.value,
              color: _getProgressColor(overallProgress),
            ),
            child: Center(
              child: Text(
                '${(overallProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
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
          _buildDimensionProgress(),
          const SizedBox(height: 16),
          Text(
            '能力分布',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildRadarChart(),
          const SizedBox(height: 16),
          Text(
            '最近学习',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildRecentLearningList(),
        ],
      ),
    );
  }

  /// 构建维度进度
  Widget _buildDimensionProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '维度进展',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.progressData.dimensions.map((dimension) => 
          _buildDimensionItem(dimension),
        ),
      ],
    );
  }

  /// 构建维度项
  Widget _buildDimensionItem(LearningDimension dimension) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dimension.name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                '${(dimension.progress * 100).toInt()}%',
                style: TextStyle(
                  color: _getProgressColor(dimension.progress).withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: dimension.progress * _progressAnimation.value,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(dimension.progress),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建雷达图
  Widget _buildRadarChart() {
    return SizedBox(
      height: 200,
      child: Center(
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(200, 200),
              painter: RadarChartPainter(
                data: widget.progressData.skills,
                animation: _progressAnimation.value,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建最近学习列表
  Widget _buildRecentLearningList() {
    return Column(
      children: widget.progressData.recentActivities.map((activity) => 
        _buildActivityItem(activity),
      ).toList(),
    );
  }

  /// 构建活动项
  Widget _buildActivityItem(LearningActivity activity) {
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
                color: _getActivityColor(activity.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getActivityColor(activity.type).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: _getActivityColor(activity.type).withOpacity(0.9),
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
                    activity.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.timestamp,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3A7BFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3A7BFF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '+${activity.points}',
                style: TextStyle(
                  color: const Color(0xFF3A7BFF).withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取进度颜色
  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return const Color(0xFFFF6B6B); // 红色
    } else if (progress < 0.7) {
      return const Color(0xFFFFC107); // 黄色
    } else {
      return const Color(0xFF4CAF50); // 绿色
    }
  }

  /// 获取活动颜色
  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.learned:
        return const Color(0xFF4CAF50); // 绿色
      case ActivityType.practiced:
        return const Color(0xFF3A7BFF); // 蓝色
      case ActivityType.quizzed:
        return const Color(0xFFFFC107); // 黄色
      case ActivityType.discovered:
        return const Color(0xFFFF6B6B); // 红色
    }
  }

  /// 获取活动图标
  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.learned:
        return Icons.book;
      case ActivityType.practiced:
        return Icons.fitness_center;
      case ActivityType.quizzed:
        return Icons.quiz;
      case ActivityType.discovered:
        return Icons.explore;
    }
  }
}

/// 圆形进度绘制器
class CircularProgressPainter extends CustomPainter {
  /// 进度值 (0.0 - 1.0)
  final double progress;
  
  /// 颜色
  final Color color;
  
  /// 构造函数
  const CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
      
    canvas.drawCircle(center, radius - 2, backgroundPaint);
    
    // 绘制进度圆环
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2, // 从顶部开始
      2 * math.pi * progress, // 进度弧长
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// 雷达图绘制器
class RadarChartPainter extends CustomPainter {
  /// 技能数据
  final List<Skill> data;
  
  /// 动画值
  final double animation;
  
  /// 构造函数
  const RadarChartPainter({
    required this.data,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    
    // 计算每个技能的角度
    final angleStep = 2 * math.pi / data.length;
    
    // 绘制背景多边形
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
      
    final backgroundVertices = List.generate(data.length, (i) {
      final angle = -math.pi / 2 + i * angleStep;
      return center + Offset(
        radius * math.cos(angle),
        radius * math.sin(angle),
      );
    });
    
    final backgroundPath = Path()..addPolygon(backgroundVertices, true);
    canvas.drawPath(backgroundPath, backgroundPaint);
    
    // 绘制背景网格
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    // 绘制同心圆
    for (int i = 1; i <= 4; i++) {
      final gridRadius = radius * i / 4;
      canvas.drawCircle(center, gridRadius, gridPaint);
    }
    
    // 绘制径向线
    for (int i = 0; i < data.length; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final point = center + Offset(
        radius * math.cos(angle),
        radius * math.sin(angle),
      );
      
      canvas.drawLine(center, point, gridPaint);
      
      // 绘制标签
      final labelPoint = center + Offset(
        (radius + 15) * math.cos(angle),
        (radius + 15) * math.sin(angle),
      );
      
      final textSpan = TextSpan(
        text: data[i].name,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 10,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      
      final textOffset = Offset(
        labelPoint.dx - textPainter.width / 2,
        labelPoint.dy - textPainter.height / 2,
      );
      
      textPainter.paint(canvas, textOffset);
    }
    
    // 绘制数据多边形
    final dataPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3A7BFF).withOpacity(0.7),
          const Color(0xFF3A7BFF).withOpacity(0.3),
        ],
        center: Alignment.center,
        radius: 1.0,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
      
    final dataVertices = List.generate(data.length, (i) {
      final angle = -math.pi / 2 + i * angleStep;
      final value = data[i].value * animation; // 应用动画
      return center + Offset(
        radius * value * math.cos(angle),
        radius * value * math.sin(angle),
      );
    });
    
    final dataPath = Path()..addPolygon(dataVertices, true);
    canvas.drawPath(dataPath, dataPaint);
    
    // 绘制数据点
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    for (final point in dataVertices) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(RadarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.animation != animation;
  }
}

/// 学习进度数据类
class LearningProgressData {
  /// 总体进度 (0.0 - 1.0)
  final double overallProgress;
  
  /// 学习维度
  final List<LearningDimension> dimensions;
  
  /// 技能列表
  final List<Skill> skills;
  
  /// 最近活动
  final List<LearningActivity> recentActivities;
  
  /// 构造函数
  const LearningProgressData({
    required this.overallProgress,
    required this.dimensions,
    required this.skills,
    required this.recentActivities,
  });
}

/// 学习维度类
class LearningDimension {
  /// 维度名称
  final String name;
  
  /// 进度值 (0.0 - 1.0)
  final double progress;
  
  /// 构造函数
  const LearningDimension({
    required this.name,
    required this.progress,
  });
}

/// 技能类
class Skill {
  /// 技能名称
  final String name;
  
  /// 技能值 (0.0 - 1.0)
  final double value;
  
  /// 构造函数
  const Skill({
    required this.name,
    required this.value,
  });
}

/// 学习活动类
class LearningActivity {
  /// 活动标题
  final String title;
  
  /// 时间戳
  final String timestamp;
  
  /// 获得的点数
  final int points;
  
  /// 活动类型
  final ActivityType type;
  
  /// 构造函数
  const LearningActivity({
    required this.title,
    required this.timestamp,
    required this.points,
    required this.type,
  });
}

/// 活动类型枚举
enum ActivityType {
  /// 学习
  learned,
  
  /// 练习
  practiced,
  
  /// 测验
  quizzed,
  
  /// 发现
  discovered,
} 