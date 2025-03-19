import 'package:flutter/material.dart';
import 'dart:ui';
import '../themes/app_theme.dart';

class GestureTrail extends StatefulWidget {
  final Color? color;
  final double strokeWidth;
  final AssistantMode mode;

  const GestureTrail({
    Key? key,
    this.color,
    this.strokeWidth = 5.0,
    this.mode = AssistantMode.standard,
  }) : super(key: key);

  @override
  State<GestureTrail> createState() => _GestureTrailState();
}

class _GestureTrailState extends State<GestureTrail> {
  final List<Offset?> _points = [];
  final List<_TrailPoint> _trails = [];

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AIAssistantTheme.getPrimaryColorByMode(widget.mode);
    
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _points.clear();
          _points.add(details.localPosition);
          _trails.add(_TrailPoint(
            position: details.localPosition,
            timestamp: DateTime.now(),
          ));
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _points.add(details.localPosition);
          _trails.add(_TrailPoint(
            position: details.localPosition,
            timestamp: DateTime.now(),
          ));
          
          // 清理超过2秒的轨迹点
          final now = DateTime.now();
          _trails.removeWhere((point) {
            return now.difference(point.timestamp).inMilliseconds > 2000;
          });
        });
      },
      onPanEnd: (details) {
        setState(() {
          _points.add(null);
        });
        
        // 2秒后清空轨迹
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _trails.clear();
            });
          }
        });
      },
      child: CustomPaint(
        painter: _GestureTrailPainter(
          points: _points,
          trails: _trails,
          color: color,
          strokeWidth: widget.strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _TrailPoint {
  final Offset position;
  final DateTime timestamp;
  
  _TrailPoint({
    required this.position,
    required this.timestamp,
  });
}

class _GestureTrailPainter extends CustomPainter {
  final List<Offset?> points;
  final List<_TrailPoint> trails;
  final Color color;
  final double strokeWidth;
  
  _GestureTrailPainter({
    required this.points,
    required this.trails,
    required this.color,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
      
    // 绘制主轨迹
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
    
    // 绘制轨迹点淡出效果
    final now = DateTime.now();
    for (var trail in trails) {
      final age = now.difference(trail.timestamp).inMilliseconds;
      final opacity = (1.0 - (age / 2000)).clamp(0.0, 1.0);
      
      if (opacity > 0) {
        final fadePaint = Paint()
          ..color = color.withOpacity(opacity * 0.3)
          ..strokeWidth = strokeWidth * 2 * opacity
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(trail.position, strokeWidth * opacity, fadePaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(_GestureTrailPainter oldDelegate) {
    return true;
  }
}
