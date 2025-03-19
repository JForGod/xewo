import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class VideoInteraction extends StatefulWidget {
  final bool isActive;
  final double width;
  final double height;
  final Color? borderColor;
  final Widget? placeholder;
  final AssistantMode mode;

  const VideoInteraction({
    Key? key,
    this.isActive = false,
    this.width = 240.0,
    this.height = 180.0,
    this.borderColor,
    this.placeholder,
    this.mode = AssistantMode.standard,
  }) : super(key: key);

  @override
  State<VideoInteraction> createState() => _VideoInteractionState();
}

class _VideoInteractionState extends State<VideoInteraction> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _borderAnimation = Tween<double>(begin: 1.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.isActive) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(VideoInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.repeat(reverse: true);
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
    final borderColor = widget.borderColor ?? AIAssistantTheme.getPrimaryColorByMode(widget.mode);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive
                  ? borderColor.withOpacity(0.8)
                  : Colors.white.withOpacity(0.3),
              width: widget.isActive
                  ? _borderAnimation.value
                  : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // 视频流占位符
                widget.placeholder ?? Center(
                  child: Icon(
                    Icons.videocam_off,
                    color: Colors.white.withOpacity(0.5),
                    size: 32,
                  ),
                ),
                
                // 录制指示器
                if (widget.isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  
                // 底部控制栏
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.mic,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        Icon(
                          Icons.videocam,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        Icon(
                          Icons.settings,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
