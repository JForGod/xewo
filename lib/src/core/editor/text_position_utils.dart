import 'package:flutter/material.dart';

class TextPositionUtils {
  static TextPosition getTextPositionFromOffset(
    TextEditingController controller,
    Offset globalPosition,
    RenderBox renderBox,
  ) {
    final localPosition = renderBox.globalToLocal(globalPosition);
    
    // 获取文本布局
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: controller.text,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    painter.layout();
    
    // 获取最接近点击位置的文本位置
    return painter.getPositionForOffset(localPosition);
  }

  static Offset getOffsetForPosition(
    TextPosition position,
    TextEditingController controller,
    RenderBox renderBox,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: controller.text,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    painter.layout();
    
    // 获取文本位置对应的偏移量
    return painter.getOffsetForCaret(position, Rect.zero);
  }
} 