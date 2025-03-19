import 'package:flutter/material.dart';
import 'dart:ui';
import '../themes/app_theme.dart';
import 'assistant_container.dart';
import '../../domain/models/assistant_mode.dart';

enum FloatingAssistantState {
  collapsed,
  semiExpanded,
  fullyExpanded,
}

class FloatingAssistant extends StatefulWidget {
  final FloatingAssistantState initialState;
  final Widget collapsedChild;
  final Widget semiExpandedChild;
  final Widget fullyExpandedChild;
  final Function(FloatingAssistantState)? onStateChanged;

  const FloatingAssistant({
    Key? key,
    this.initialState = FloatingAssistantState.collapsed,
    required this.collapsedChild,
    required this.semiExpandedChild,
    required this.fullyExpandedChild,
    this.onStateChanged,
  }) : super(key: key);

  @override
  State<FloatingAssistant> createState() => _FloatingAssistantState();
}

class _FloatingAssistantState extends State<FloatingAssistant> with SingleTickerProviderStateMixin {
  late FloatingAssistantState _currentState;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _cycleState() {
    setState(() {
      switch (_currentState) {
        case FloatingAssistantState.collapsed:
          _currentState = FloatingAssistantState.semiExpanded;
          break;
        case FloatingAssistantState.semiExpanded:
          _currentState = FloatingAssistantState.fullyExpanded;
          break;
        case FloatingAssistantState.fullyExpanded:
          _currentState = FloatingAssistantState.collapsed;
          break;
      }
      
      if (widget.onStateChanged != null) {
        widget.onStateChanged!(_currentState);
      }
    });
  }

  Widget _buildAssistantByState() {
    switch (_currentState) {
      case FloatingAssistantState.collapsed:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: AIAssistantTheme.glassShadow(),
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: widget.collapsedChild,
            ),
          ),
        );
      case FloatingAssistantState.semiExpanded:
        return Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AIAssistantTheme.glassShadow(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: widget.semiExpandedChild,
            ),
          ),
        );
      case FloatingAssistantState.fullyExpanded:
        return Container(
          width: 320,
          height: 450,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AIAssistantTheme.glassShadow(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.fullyExpandedChild,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: _cycleState,
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
            
            // 智能边缘吸附
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            
            if (_position.dx < 20) {
              _position = Offset(0, _position.dy);
            } else if (_position.dx > screenWidth - 80) {
              _position = Offset(screenWidth - 60, _position.dy);
            }
            
            if (_position.dy < 20) {
              _position = Offset(_position.dx, 0);
            } else if (_position.dy > screenHeight - 80) {
              _position = Offset(_position.dx, screenHeight - 60);
            }
          });
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: _buildAssistantByState(),
              ),
            );
          },
        ),
      ),
    );
  }
}
