import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../themes/app_theme.dart';

class VoiceWaveForm extends StatefulWidget {
  final bool isActive;
  final Color? color;
  final int barCount;
  final double height;
  final AssistantMode mode;

  const VoiceWaveForm({
    Key? key,
    this.isActive = false,
    this.color,
    this.barCount = 12,
    this.height = 30.0,
    this.mode = AssistantMode.standard,
  }) : super(key: key);

  @override
  State<VoiceWaveForm> createState() => _VoiceWaveFormState();
}

class _VoiceWaveFormState extends State<VoiceWaveForm> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (_) => AnimationController(
        duration: Duration(milliseconds: 300 + _random.nextInt(700)),
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && widget.isActive) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
    
    if (widget.barCount != oldWidget.barCount) {
      _disposeAnimations();
      _initializeAnimations();
      if (widget.isActive) {
        _startAnimations();
      }
    }
  }

  void _disposeAnimations() {
    for (var controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AIAssistantTheme.getPrimaryColorByMode(widget.mode);
    
    return Container(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          widget.barCount,
          (index) => _buildBar(index, color),
        ),
      ),
    );
  }

  Widget _buildBar(int index, Color color) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        final value = widget.isActive ? _animations[index].value : 0.1;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 3,
          height: widget.height * value,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      },
    );
  }
}
