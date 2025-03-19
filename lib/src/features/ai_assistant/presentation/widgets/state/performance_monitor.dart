import 'package:flutter/material.dart';
import 'dart:ui';

/// 性能监视器
/// 
/// 一个具有Glassmorphism风格的性能监视器，展示AI助手的实时性能状态
/// 包括响应时间、操作延迟、优化建议等
class PerformanceMonitor extends StatefulWidget {
  /// 性能数据
  final PerformanceData performanceData;
  
  /// 是否展开
  final bool isExpanded;
  
  /// 展开状态切换回调
  final Function(bool) onExpandChanged;
  
  /// 构造函数
  const PerformanceMonitor({
    Key? key,
    required this.performanceData,
    this.isExpanded = false,
    required this.onExpandChanged,
  }) : super(key: key);

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(PerformanceMonitor oldWidget) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Column(
                    children: [
                      _buildPerformanceMetrics(),
                      _buildOptimizationSuggestions(),
                    ],
                  ),
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
                  Icons.speed,
                  color: const Color(0xFF3A7BFF).withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '性能监控',
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
                _buildPerformanceIndicator(),
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

  /// 构建性能指标
  Widget _buildPerformanceMetrics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '实时性能',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricItem(
            '响应时间',
            '${widget.performanceData.responseTime}ms',
            widget.performanceData.responseTimeRating,
          ),
          const SizedBox(height: 8),
          _buildMetricItem(
            '任务执行',
            '${widget.performanceData.taskExecutionTime}ms',
            widget.performanceData.taskExecutionRating,
          ),
          const SizedBox(height: 8),
          _buildMetricItem(
            '上下文切换',
            '${widget.performanceData.contextSwitchTime}ms',
            widget.performanceData.contextSwitchRating,
          ),
          const SizedBox(height: 8),
          _buildMetricItem(
            'UI渲染',
            '${widget.performanceData.uiRenderTime}ms',
            widget.performanceData.uiRenderRating,
          ),
        ],
      ),
    );
  }

  /// 构建优化建议
  Widget _buildOptimizationSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '优化建议',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.performanceData.optimizationSuggestions.map((suggestion) => _buildSuggestionItem(suggestion)),
        ],
      ),
    );
  }

  /// 构建性能指示器
  Widget _buildPerformanceIndicator() {
    final rating = widget.performanceData.overallRating;
    Color color;
    String text;
    
    if (rating > 0.8) {
      color = const Color(0xFF4CAF50); // 好
      text = '良好';
    } else if (rating > 0.6) {
      color = const Color(0xFFFFC107); // 中
      text = '一般';
    } else {
      color = const Color(0xFFFF6B6B); // 差
      text = '需优化';
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
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建指标项
  Widget _buildMetricItem(String name, String value, double rating) {
    Color ratingColor;
    IconData ratingIcon;
    
    if (rating > 0.8) {
      ratingColor = const Color(0xFF4CAF50); // 好
      ratingIcon = Icons.check_circle;
    } else if (rating > 0.6) {
      ratingColor = const Color(0xFFFFC107); // 中
      ratingIcon = Icons.info;
    } else {
      ratingColor = const Color(0xFFFF6B6B); // 差
      ratingIcon = Icons.warning;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              ratingIcon,
              color: ratingColor.withOpacity(0.9),
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建建议项
  Widget _buildSuggestionItem(OptimizationSuggestion suggestion) {
    Color priorityColor;
    
    switch (suggestion.priority) {
      case SuggestionPriority.high:
        priorityColor = const Color(0xFFFF6B6B); // 高优先级
        break;
      case SuggestionPriority.medium:
        priorityColor = const Color(0xFFFFC107); // 中优先级
        break;
      case SuggestionPriority.low:
        priorityColor = const Color(0xFF4CAF50); // 低优先级
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: priorityColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 性能数据类
class PerformanceData {
  /// 响应时间 (毫秒)
  final int responseTime;
  
  /// 任务执行时间 (毫秒)
  final int taskExecutionTime;
  
  /// 上下文切换时间 (毫秒)
  final int contextSwitchTime;
  
  /// UI渲染时间 (毫秒)
  final int uiRenderTime;
  
  /// 响应时间评级 (0.0 - 1.0)
  final double responseTimeRating;
  
  /// 任务执行评级 (0.0 - 1.0)
  final double taskExecutionRating;
  
  /// 上下文切换评级 (0.0 - 1.0)
  final double contextSwitchRating;
  
  /// UI渲染评级 (0.0 - 1.0)
  final double uiRenderRating;
  
  /// 优化建议
  final List<OptimizationSuggestion> optimizationSuggestions;

  /// 构造函数
  const PerformanceData({
    required this.responseTime,
    required this.taskExecutionTime,
    required this.contextSwitchTime,
    required this.uiRenderTime,
    required this.responseTimeRating,
    required this.taskExecutionRating,
    required this.contextSwitchRating,
    required this.uiRenderRating,
    required this.optimizationSuggestions,
  });
  
  /// 获取总体评级
  double get overallRating {
    return (responseTimeRating * 0.3 + 
            taskExecutionRating * 0.3 + 
            contextSwitchRating * 0.2 + 
            uiRenderRating * 0.2);
  }
}

/// 优化建议类
class OptimizationSuggestion {
  /// 标题
  final String title;
  
  /// 描述
  final String description;
  
  /// 优先级
  final SuggestionPriority priority;
  
  /// 构造函数
  const OptimizationSuggestion({
    required this.title,
    required this.description,
    required this.priority,
  });
}

/// 建议优先级枚举
enum SuggestionPriority {
  /// 高优先级
  high,
  
  /// 中优先级
  medium,
  
  /// 低优先级
  low,
} 