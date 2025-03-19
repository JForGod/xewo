import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';
import '../../../features/ai_assistant/presentation/widgets/floating_assistant.dart';
import '../../../features/ai_assistant/domain/models/assistant_mode.dart';
import '../../../features/ai_assistant/presentation/pages/standard_mode_page.dart';
import '../../../features/ai_assistant/presentation/pages/guardian_mode_page.dart';
import '../../../features/ai_assistant/presentation/pages/pro_mode_page.dart';
import '../../../../main.dart';

/// 学习系统屏幕
class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  bool _isAssistantVisible = false;
  FloatingAssistantState _assistantState = FloatingAssistantState.collapsed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习系统'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isAssistantVisible ? Icons.assistant : Icons.assistant_outlined),
            tooltip: _isAssistantVisible ? '隐藏AI助手' : '显示AI助手',
            onPressed: () {
              setState(() {
                _isAssistantVisible = !_isAssistantVisible;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要内容
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 学习系统标题和描述
                  const SizedBox(height: AppTheme.spacingLg),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '学习系统',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          '正在开发中...',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXl),
                  
                  // 学习路径区域（占位）
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '个性化学习路径',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            '基于您的学习习惯和技能水平，我们将为您提供最适合的学习路径。',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // 这里将来会跳转到学习路径页面
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('学习路径功能开发中...')),
                                );
                              },
                              child: const Text('开始我的学习之旅'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLg),
                  
                  // 热门课程（占位）
                  const Text(
                    '热门课程',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCourseCard(
                          '编程基础入门',
                          '适合零基础学习者的编程入门课程',
                          Icons.code,
                          Colors.blue,
                        ),
                        _buildCourseCard(
                          '数据结构与算法',
                          '深入理解计算机科学的核心概念',
                          Icons.account_tree,
                          Colors.green,
                        ),
                        _buildCourseCard(
                          'Flutter移动应用开发',
                          '从零开始构建跨平台移动应用',
                          Icons.phone_android,
                          Colors.purple,
                        ),
                        _buildCourseCard(
                          '人工智能基础',
                          '了解AI的基本原理和应用',
                          Icons.psychology,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // AI助手悬浮组件
          if (_isAssistantVisible)
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingAssistant(
                initialState: _assistantState,
                onStateChanged: (state) {
                  setState(() {
                    _assistantState = state;
                  });
                },
                collapsedChild: _buildCollapsedAssistant(),
                semiExpandedChild: _buildSemiExpandedAssistant(),
                fullyExpandedChild: _buildFullyExpandedAssistant(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCourseCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(right: AppTheme.spacingMd),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('课程详情功能开发中...')),
                    );
                  },
                  child: const Text('了解更多'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCollapsedAssistant() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[300]!, Colors.blue[700]!],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
  
  Widget _buildSemiExpandedAssistant() {
    return Container(
      width: 200,
      height: 120,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '学习助手',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const Text(
            '点击获取学习建议和帮助',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('学习帮助功能开发中...')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  setState(() {
                    _assistantState = FloatingAssistantState.fullyExpanded;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFullyExpandedAssistant() {
    // 获取当前的助手模式
    final currentMode = ref.watch(currentModeProvider);
    
    // 根据模式显示不同的页面
    switch (currentMode) {
      case AssistantMode.guardian:
        return const GuardianModePage(key: ValueKey('guardian'));
      case AssistantMode.pro:
        return const ProModePage(key: ValueKey('pro'));
      case AssistantMode.standard:
      default:
        return const StandardModePage(key: ValueKey('standard'));
    }
  }
} 