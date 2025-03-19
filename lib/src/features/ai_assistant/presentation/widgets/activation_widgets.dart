import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class HotkeyOverlay extends StatelessWidget {
  final String hotkey;
  final VoidCallback? onTap;

  const HotkeyOverlay({
    Key? key,
    required this.hotkey,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: AIAssistantTheme.glassShadow(),
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: Text(
          hotkey,
          style: const TextStyle(
            fontFamily: 'SF Mono',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class VoiceActivationIndicator extends StatefulWidget {
  final bool isListening;
  final VoidCallback? onTap;

  const VoiceActivationIndicator({
    Key? key,
    this.isListening = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<VoiceActivationIndicator> createState() => _VoiceActivationIndicatorState();
}

class _VoiceActivationIndicatorState extends State<VoiceActivationIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    if (widget.isListening) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceActivationIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isListening)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final opacity = (0.3 * (1 - _scaleAnimation.value)).clamp(0.0, 1.0);
                return Container(
                  width: 48 * _scaleAnimation.value,
                  height: 48 * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.isListening
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🎙️',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GestureActivationZone extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const GestureActivationZone({
    Key? key,
    this.isActive = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: -4,
                  )
                ]
              : null,
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
              '手势激活区域',
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
}

class EdgeTrigger extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final EdgePosition position;

  const EdgeTrigger({
    Key? key,
    this.isActive = false,
    this.onTap,
    this.position = EdgePosition.left,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isVertical = position == EdgePosition.left || position == EdgePosition.right;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isVertical ? (isActive ? 8 : 4) : 120,
        height: isVertical ? 120 : (isActive ? 8 : 4),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isActive ? 4 : 2),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: -2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            isVertical ? 'AI' : 'AI',
            style: TextStyle(
              color: Colors.white.withOpacity(isActive ? 0.8 : 0.4),
              fontSize: isActive ? 12 : 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

enum EdgePosition {
  left,
  right,
  top,
  bottom,
}
