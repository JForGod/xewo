// 2025-03-20: 新增 - 流式文本显示组件

import 'dart:async';
import 'package:flutter/material.dart';

/// 流式文本显示组件
///
/// 用于实现打字机效果的实时响应
class StreamingTextWidget extends StatefulWidget {
  /// 文本内容
  final String text;
  
  /// 文本样式
  final TextStyle? style;
  
  /// 是否已完成流式显示
  final bool isComplete;
  
  /// 每个字符的显示间隔（毫秒）
  final int charDelay;
  
  /// 构造函数
  const StreamingTextWidget({
    Key? key,
    required this.text,
    this.style,
    this.isComplete = false,
    this.charDelay = 30,
  }) : super(key: key);

  @override
  State<StreamingTextWidget> createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<StreamingTextWidget> with SingleTickerProviderStateMixin {
  late String _displayText;
  int _currentLength = 0;
  Timer? _timer;
  bool _isStreaming = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.isComplete) {
      // 如果已完成，直接显示全部文本
      _displayText = widget.text;
      _currentLength = widget.text.length;
    } else {
      // 否则开始流式显示
      _displayText = '';
      _startStreaming();
    }
  }
  
  @override
  void didUpdateWidget(covariant StreamingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果文本内容变化，更新显示
    if (widget.text != oldWidget.text) {
      if (widget.isComplete) {
        // 如果已完成，直接显示全部文本
        _displayText = widget.text;
        _currentLength = widget.text.length;
        _stopStreaming();
      } else {
        // 否则重新开始流式显示
        _displayText = '';
        _currentLength = 0;
        _startStreaming();
      }
    } else if (widget.isComplete != oldWidget.isComplete && widget.isComplete) {
      // 如果状态从流式变为完成，显示全部文本
      _displayText = widget.text;
      _currentLength = widget.text.length;
      _stopStreaming();
    }
  }
  
  @override
  void dispose() {
    _stopStreaming();
    super.dispose();
  }
  
  /// 开始流式显示
  void _startStreaming() {
    if (_isStreaming) return;
    
    _isStreaming = true;
    _timer?.cancel();
    
    _timer = Timer.periodic(Duration(milliseconds: widget.charDelay), (timer) {
      if (_currentLength < widget.text.length) {
        setState(() {
          _currentLength++;
          _displayText = widget.text.substring(0, _currentLength);
        });
      } else {
        _stopStreaming();
      }
    });
  }
  
  /// 停止流式显示
  void _stopStreaming() {
    _timer?.cancel();
    _timer = null;
    _isStreaming = false;
  }
  
  @override
  Widget build(BuildContext context) {
    return SelectableText(
      _displayText,
      style: widget.style,
    );
  }
} 