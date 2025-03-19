import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_theme.dart';
import '../themes/standard_theme.dart';
import '../../providers/conversation_provider.dart';

enum InteractionMode {
  voice,
  gesture,
  gaze,
  video,
  text,
}

class MultimodalControls extends ConsumerStatefulWidget {
  final InteractionMode currentMode;
  final Function(InteractionMode) onModeChanged;
  final String hintText;
  final Function(String) onSubmit;

  const MultimodalControls({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
    this.hintText = '输入消息...',
    required this.onSubmit,
  }) : super(key: key);

  @override
  ConsumerState<MultimodalControls> createState() => _MultimodalControlsState();
}

class _MultimodalControlsState extends ConsumerState<MultimodalControls> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;
  
  // 添加文本输入相关属性
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isComposing = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    
    // 添加文本变更监听
    _textController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }
  
  /// 处理文本变更
  void _handleTextChange() {
    setState(() {
      _isComposing = _textController.text.isNotEmpty;
    });
  }
  
  /// 发送消息
  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    widget.onSubmit(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 模式切换面板
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: _isExpanded ? _buildExpandedModeSelector() : _buildQuickModeSelector(),
        ),
        
        // 当前模式控件
        if (!_isExpanded) const SizedBox(height: 16),
        if (!_isExpanded) AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentModeWidget(),
        ),
      ],
    );
  }

  Widget _buildQuickModeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeButton(InteractionMode.voice, '🎙️'),
        const SizedBox(width: 8),
        _buildModeButton(InteractionMode.gesture, '👋'),
        const SizedBox(width: 8),
        _buildModeButton(InteractionMode.gaze, '👁️'),
        const SizedBox(width: 8),
        _buildModeButton(InteractionMode.video, '📹'),
        const SizedBox(width: 8),
        _buildModeButton(InteractionMode.text, '💬'),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _isExpanded ? Icons.close : Icons.expand_more,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '选择交互模式',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _buildModeCard(InteractionMode.voice, '🎙️', '语音'),
            _buildModeCard(InteractionMode.gesture, '👋', '手势'),
            _buildModeCard(InteractionMode.gaze, '👁️', '视线'),
            _buildModeCard(InteractionMode.video, '📹', '视频'),
            _buildModeCard(InteractionMode.text, '💬', '文字'),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton(InteractionMode mode, String icon) {
    final bool isActive = widget.currentMode == mode;
    
    return GestureDetector(
      onTap: () {
        if (widget.currentMode != mode) {
          // 触发模式切换动画
          _animationController.reset();
          _animationController.forward();
          
          widget.onModeChanged(mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive 
              ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 12)]
              : null,
          border: Border.all(
            color: isActive ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(InteractionMode mode, String icon, String label) {
    final bool isActive = widget.currentMode == mode;
    
    return GestureDetector(
      onTap: () {
        if (widget.currentMode != mode) {
          // 触发模式切换动画
          _animationController.reset();
          _animationController.forward();
          
          widget.onModeChanged(mode);
          
          // 切换后折叠面板
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              _isExpanded = false;
            });
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive 
              ? [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 12)]
              : null,
          border: Border.all(
            color: isActive ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentModeWidget() {
    switch (widget.currentMode) {
      case InteractionMode.voice:
        return _buildVoiceWidget();
      case InteractionMode.gesture:
        return _buildGestureWidget();
      case InteractionMode.gaze:
        return _buildGazeWidget();
      case InteractionMode.video:
        return _buildVideoWidget();
      case InteractionMode.text:
        return _buildTextWidget();
    }
  }

  Widget _buildVoiceWidget() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        key: const ValueKey('voice'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPulsingCircle(),
            const SizedBox(height: 16),
            const Text(
              '点击开始语音输入',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingCircle() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 脉冲动画层
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 60 + (value * 20),
                height: 60 + (value * 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1 * (1 - value)),
                  shape: BoxShape.circle,
                ),
              );
            },
            onEnd: () {
              setState(() {
                // 重新触发动画
              });
            },
          ),
          // 中心图标
          const Center(
            child: Text(
              '🎙️',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureWidget() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        key: const ValueKey('gesture'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '👋',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '手势识别已准备就绪',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGazeWidget() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        key: const ValueKey('gaze'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '👁️',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '视线追踪需要校准',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('开始校准'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoWidget() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        key: const ValueKey('video'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.videocam,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '点击开启摄像头',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWidget() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        key: const ValueKey('text'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: StandardTheme.primaryColor),
              onPressed: () {
                // 附件功能实现
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('附件功能暂未实现')),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                onSubmitted: (text) {
                  if (_isComposing) {
                    widget.onSubmit(text);
                  }
                },
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _isComposing
                  ? IconButton(
                      icon: const Icon(Icons.send, color: StandardTheme.accentColor),
                      onPressed: _handleSubmit,
                    )
                  : IconButton(
                      icon: Transform.rotate(
                        angle: -math.pi / 4,
                        child: Icon(
                          Icons.mic,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      onPressed: () {
                        // 语音输入功能
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('语音输入功能暂未实现')),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
