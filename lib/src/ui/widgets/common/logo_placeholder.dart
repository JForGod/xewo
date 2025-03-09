import 'package:flutter/material.dart';

/// Logo占位组件，用于替代缺少的logo.png文件
class LogoPlaceholder extends StatelessWidget {
  final double size;
  final Color color;
  
  const LogoPlaceholder({
    super.key,
    this.size = 100,
    this.color = Colors.blue,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 5),
      ),
      child: Center(
        child: Text(
          'xEwo',
          style: TextStyle(
            color: Colors.white,
            fontSize: size / 3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 