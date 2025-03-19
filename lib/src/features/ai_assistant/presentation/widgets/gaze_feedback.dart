import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../themes/app_theme.dart';

class GazeFeedback extends StatefulWidget {
  final Offset? gazePosition;
  final double radius;
  final Color? color;
  final bool showCrosshair;
  final AssistantMode mode;

  const GazeFeedback({
    Key? key,
    this.gazePosition,
    this.radius = 30.0,
    this.color,
    this.showCrosshair = true,
    this.mode = AssistantMode.standard,
  }) : super(key: key);

  @override
  State<GazeFeedback> createState() => _GazeFeedbackState();
}

class _GazeFeedbackState extends State<GazeFeedback> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gazePosition == null) {
      return const SizedBox.shrink();
    }
    
    final color = widget.color ?? AIAssistantTheme.getPrimaryColorByMode(widget.mode);
    
    return Positioned(
      left: widget.gazePosition!.dx - widget.radius,
      top: widget.gazePosition!.dy - widget.radius,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // 脉冲圆环
              Container(
                width: widget.radius * 2 * _pulseAnimation.value,
                height: widget.radius * 2 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(_opacityAnimation.value),
                    width: 2,
                  ),
                ),
              ),
              
              // 中心点
              Positioned(
                left: widget.radius * (_pulseAnimation.value - 0.5),
                top: widget.radius * (_pulseAnimation.value - 0.5),
                child: Container(
                  width: widget.radius,
                  height: widget.radius,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                    border: Border.all(
                      color: color.withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              
              // 十字准线
              if (widget.showCrosshair)
                Positioned(
                  left: widget.radius * (_pulseAnimation.value - 0.5),
                  top: widget.radius * (_pulseAnimation.value - 0.5),
                  child: CustomPaint(
                    painter: _CrosshairPainter(
                      color: color,
                      opacity: _opacityAnimation.value,
                    ),
                    size: Size(widget.radius, widget.radius),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;
  final double opacity;
  
  _CrosshairPainter({
    required this.color,
    required this.opacity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 水平线
    canvas.drawLine(
      Offset(center.dx - radius / 2, center.dy),
      Offset(center.dx + radius / 2, center.dy),
      paint,
    );
    
    // 垂直线
    canvas.drawLine(
      Offset(center.dx, center.dy - radius / 2),
      Offset(center.dx, center.dy + radius / 2),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) {
    return opacity != oldDelegate.opacity || color != oldDelegate.color;
  }
}
