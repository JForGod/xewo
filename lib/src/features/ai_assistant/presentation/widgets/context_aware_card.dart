import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../themes/animations.dart';

class ContextAwareCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? child;
  final bool isActive;
  final bool showAnimation;
  final AssistantMode mode;

  const ContextAwareCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
    this.child,
    this.isActive = false,
    this.showAnimation = true,
    this.mode = AssistantMode.standard,
  }) : super(key: key);

  @override
  State<ContextAwareCard> createState() => _ContextAwareCardState();
}

class _ContextAwareCardState extends State<ContextAwareCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    if (widget.showAnimation && widget.isActive) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(ContextAwareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.showAnimation && widget.isActive) {
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
    final primaryColor = widget.color ?? AIAssistantTheme.getPrimaryColorByMode(widget.mode);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showAnimation && widget.isActive
              ? _scaleAnimation.value
              : _isHovered
                  ? 1.02
                  : 1.0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? primaryColor.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isActive
                        ? primaryColor.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: widget.isActive || _isHovered
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: -2,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.icon,
                            color: primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                      ],
                    ),
                    if (widget.child != null) ...[
                      const SizedBox(height: 12),
                      widget.child!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
