import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../main.dart';
import '../../../features/ai_assistant/domain/models/assistant_mode.dart';
import '../../../features/ai_assistant/presentation/pages/guardian_mode_page.dart';
import '../../../features/ai_assistant/presentation/pages/standard_mode_page.dart';
import '../../../features/ai_assistant/presentation/pages/pro_mode_page.dart';

/// 2025-03-15: 添加AI助手悬浮按钮组件，用于在主程序中显示AI助手
class AIAssistantFloatingButton extends ConsumerStatefulWidget {
  const AIAssistantFloatingButton({super.key});

  @override
  ConsumerState<AIAssistantFloatingButton> createState() => _AIAssistantFloatingButtonState();
}

class _AIAssistantFloatingButtonState extends ConsumerState<AIAssistantFloatingButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isMinimized = false;
  
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

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(assistantVisibilityProvider);
    final screenSize = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // AI助手悬浮按钮
        Positioned(
          right: 20,
          bottom: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _getButtonColor(ref),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: _getPrimaryColorByMode(ref).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  ref.read(assistantVisibilityProvider.notifier).state = !isVisible;
                  if (isVisible) {
                    _animationController.reverse();
                  } else {
                    _animationController.forward();
                    setState(() {
                      _isMinimized = false;
                    });
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getPrimaryColorByMode(ref).withOpacity(0.7),
                        _getPrimaryColorByMode(ref).withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isVisible ? Icons.close : Icons.smart_toy,
                        color: Colors.white,
                        size: 24,
                        key: ValueKey(isVisible),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // AI助手覆盖层
        if (isVisible) _buildAIAssistantOverlay(ref, screenSize),
      ],
    );
  }
  
  Widget _buildAIAssistantOverlay(WidgetRef ref, Size screenSize) {
    final currentMode = ref.watch(currentModeProvider);
    
    // 计算合适的尺寸，确保不会超出屏幕
    final width = screenSize.width < 600 ? screenSize.width * 0.8 : 380.0;
    final height = screenSize.height < 800 ? screenSize.height * 0.7 : 600.0;
    
    // 如果是最小化状态，显示最小化版本
    if (_isMinimized) {
      return _buildMinimizedAssistant(ref);
    }
    
    // 根据当前模式显示对应的页面
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          right: 20,
          bottom: 80,
          width: width,
          height: height,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: _animationController,
              child: Stack(
                children: [
                  // 主内容
                  child!,
                  
                  // 最小化按钮
                  Positioned(
                    top: 8,
                    right: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isMinimized = true;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: _getAssistantPageByMode(currentMode),
    );
  }
  
  Widget _buildMinimizedAssistant(WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    
    return Positioned(
      right: 20,
      bottom: 80,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isMinimized = false;
          });
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getPrimaryColorByMode(ref),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getModeEmoji(currentMode),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _getAssistantPageByMode(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.guardian:
        return const GuardianModePage();
      case AssistantMode.standard:
        return const StandardModePage();
      case AssistantMode.pro:
        return const ProModePage();
      default:
        return const StandardModePage();
    }
  }
  
  Color _getButtonColor(WidgetRef ref) {
    final isVisible = ref.watch(assistantVisibilityProvider);
    if (isVisible) {
      return Colors.grey.withOpacity(0.3);
    } else {
      return _getPrimaryColorByMode(ref).withOpacity(0.2);
    }
  }
  
  Color _getPrimaryColorByMode(WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    switch (currentMode) {
      case AssistantMode.guardian:
        return Colors.purple;
      case AssistantMode.pro:
        return Colors.green;
      case AssistantMode.standard:
      default:
        return Colors.blue;
    }
  }
  
  String _getModeEmoji(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.guardian:
        return '🔒';
      case AssistantMode.pro:
        return '🚀';
      case AssistantMode.standard:
      default:
        return '💬';
    }
  }
} 