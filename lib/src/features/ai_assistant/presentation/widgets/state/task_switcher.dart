import 'package:flutter/material.dart';
import 'dart:ui';

/// 任务切换面板
/// 
/// 一个具有Glassmorphism风格的任务切换面板，展示和管理AI助手的当前运行任务
/// 支持多任务卡片展示和切换
class TaskSwitcher extends StatefulWidget {
  /// 任务列表
  final List<AssistantTask> tasks;
  
  /// 当前活跃任务ID
  final String activeTaskId;
  
  /// 任务切换回调
  final Function(String taskId) onTaskSwitch;
  
  /// 任务关闭回调
  final Function(String taskId) onTaskClose;
  
  /// 构造函数
  const TaskSwitcher({
    Key? key,
    required this.tasks,
    required this.activeTaskId,
    required this.onTaskSwitch,
    required this.onTaskClose,
  }) : super(key: key);

  @override
  State<TaskSwitcher> createState() => _TaskSwitcherState();
}

class _TaskSwitcherState extends State<TaskSwitcher> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
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
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 16),
                      _buildTaskGrid(),
                    ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '任务管理',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: Colors.white.withOpacity(0.9),
          ),
          onPressed: () {
            // 创建新任务的逻辑
          },
        ),
      ],
    );
  }

  /// 构建任务网格
  Widget _buildTaskGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        final isActive = task.id == widget.activeTaskId;
        
        return _buildTaskCard(task, isActive);
      },
    );
  }

  /// 构建任务卡片
  Widget _buildTaskCard(AssistantTask task, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
            ? const Color(0xFF3A7BFF).withOpacity(0.5) 
            : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        color: isActive 
            ? const Color(0xFF3A7BFF).withOpacity(0.2) 
            : Colors.white.withOpacity(0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onTaskSwitch(task.id),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getTaskIcon(task.type),
                            color: Colors.white.withOpacity(0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          task.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildResourceIndicator(task),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  onPressed: () => widget.onTaskClose(task.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建资源指示器
  Widget _buildResourceIndicator(AssistantTask task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          '资源使用',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        // 资源波形图
        SizedBox(
          height: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CustomPaint(
              size: const Size(double.infinity, 16),
              painter: ResourceWavePainter(
                cpuUsage: task.cpuUsage,
                memoryUsage: task.memoryUsage,
                primaryColor: const Color(0xFF3A7BFF),
                secondaryColor: const Color(0xFF6B7BFF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取任务类型对应的图标
  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.chat:
        return Icons.chat_bubble_outline;
      case TaskType.analysis:
        return Icons.analytics_outlined;
      case TaskType.search:
        return Icons.search;
      case TaskType.creation:
        return Icons.create_outlined;
    }
  }
}

/// 助手任务类
class AssistantTask {
  /// 任务ID
  final String id;
  
  /// 任务标题
  final String title;
  
  /// 任务描述
  final String description;
  
  /// 任务类型
  final TaskType type;
  
  /// CPU使用率
  final double cpuUsage;
  
  /// 内存使用率
  final double memoryUsage;
  
  /// 构造函数
  const AssistantTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
  });
}

/// 任务类型枚举
enum TaskType {
  /// 对话任务
  chat,
  
  /// 分析任务
  analysis,
  
  /// 搜索任务
  search,
  
  /// 创作任务
  creation,
}

/// 资源波形绘制器
class ResourceWavePainter extends CustomPainter {
  /// CPU使用率
  final double cpuUsage;
  
  /// 内存使用率
  final double memoryUsage;
  
  /// 主色调
  final Color primaryColor;
  
  /// 次色调
  final Color secondaryColor;
  
  /// 构造函数
  ResourceWavePainter({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制CPU使用率波形
    final cpuPaint = Paint()
      ..color = primaryColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cpuPath = Path();
    final cpuPoints = _generateWavePoints(size, cpuUsage);
    
    cpuPath.moveTo(cpuPoints[0].dx, cpuPoints[0].dy);
    for (int i = 1; i < cpuPoints.length; i++) {
      cpuPath.lineTo(cpuPoints[i].dx, cpuPoints[i].dy);
    }
    
    canvas.drawPath(cpuPath, cpuPaint);
    
    // 绘制内存使用率波形
    final memoryPaint = Paint()
      ..color = secondaryColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final memoryPath = Path();
    final memoryPoints = _generateWavePoints(size, memoryUsage, offset: 5);
    
    memoryPath.moveTo(memoryPoints[0].dx, memoryPoints[0].dy);
    for (int i = 1; i < memoryPoints.length; i++) {
      memoryPath.lineTo(memoryPoints[i].dx, memoryPoints[i].dy);
    }
    
    canvas.drawPath(memoryPath, memoryPaint);
  }

  /// 生成波形点
  List<Offset> _generateWavePoints(Size size, double usage, {double offset = 0}) {
    const int segments = 20;
    final points = <Offset>[];
    
    for (int i = 0; i <= segments; i++) {
      final x = size.width * i / segments;
      final randomFactor = 0.2 * (i % 3 - 1); // 添加一些随机变化
      final usageFactor = usage * (1 + randomFactor);
      final y = size.height - (size.height * usageFactor) + offset;
      
      points.add(Offset(x, y.clamp(0, size.height)));
    }
    
    return points;
  }

  @override
  bool shouldRepaint(ResourceWavePainter oldDelegate) {
    return oldDelegate.cpuUsage != cpuUsage || 
           oldDelegate.memoryUsage != memoryUsage;
  }
}