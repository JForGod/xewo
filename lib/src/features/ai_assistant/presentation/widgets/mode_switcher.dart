import 'package:flutter/material.dart';
import 'dart:ui';
import '../themes/app_theme.dart';
import '../themes/standard_theme.dart';
import '../animations/assistant_animations.dart';
import 'assistant_container.dart';
import '../../domain/models/assistant_mode.dart';

class ModeSwitcher extends StatefulWidget {
  final AssistantMode currentMode;
  final Function(AssistantMode) onModeChanged;

  const ModeSwitcher({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  State<ModeSwitcher> createState() => _ModeSwitcherState();
}

class _ModeSwitcherState extends State<ModeSwitcher> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectMode(AssistantMode mode) {
    if (mode != widget.currentMode) {
      widget.onModeChanged(mode);
    }
    // 选择后关闭面板
    setState(() {
      _isExpanded = false;
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 快速切换栏
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AIAssistantTheme.glassShadow(),
              backgroundBlendMode: BlendMode.overlay,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeIcon(AssistantMode.guardian, '🔒', 'AI'),
                const SizedBox(width: 12),
                _buildModeIcon(AssistantMode.standard, '', 'AI'),
                const SizedBox(width: 12),
                _buildModeIcon(AssistantMode.pro, '', 'AI+'),
              ],
            ),
          ),
        ),
        
        // 展开的模式面板
        if (_isExpanded)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _animationController,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AIAssistantTheme.glassShadow(),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Column(
                        children: [
                          const Text(
                            '选择交互模式',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 168,
                            height: 70,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildModeCard(AssistantMode.guardian, '🔒', '监护'),
                                  const SizedBox(width: 8),
                                  _buildModeCard(AssistantMode.standard, '', '标准'),
                                  const SizedBox(width: 8),
                                  _buildModeCard(AssistantMode.pro, '', '专业'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildModeIcon(AssistantMode mode, String emoji, String text) {
    final bool isActive = widget.currentMode == mode;
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive 
            ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 12, spreadRadius: -2)]
            : null,
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              if (emoji.isNotEmpty) TextSpan(text: emoji, style: const TextStyle(fontSize: 10)),
              TextSpan(
                text: text,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildModeCard(AssistantMode mode, String emoji, String label) {
    final isActive = widget.currentMode == mode;
    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: Container(
        width: 50,
        height: 70,
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.15) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20, spreadRadius: -2)]
              : null,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
