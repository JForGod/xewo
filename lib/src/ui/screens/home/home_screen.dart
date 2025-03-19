import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';
import '../coding/coding_screen.dart';
import '../learning/learning_screen.dart';
import '../../../../main.dart';
import '../../../features/ai_assistant/domain/models/assistant_mode.dart';
import '../../../features/ai_assistant/presentation/pages/ai_assistant_entry.dart';

/// 用户模式枚举
enum UserMode {
  standard('标准模式', '基础的代码补全和提示'),
  professional('专业模式', '高级的代码分析和重构建议'),
  guardian('监护模式', '适合初学者的引导和教学');

  final String label;
  final String description;
  const UserMode(this.label, this.description);
}

/// 用户模式状态管理
final userModeProvider = StateProvider<UserMode>((ref) => UserMode.standard);

/// 功能项模型
class FeatureItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Set<UserMode> supportedModes;
  
  const FeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.supportedModes = const {UserMode.standard, UserMode.professional, UserMode.guardian},
  });
}

/// 预定义功能项列表
final List<FeatureItem> allFeatures = [
  FeatureItem(
    id: 'smart_coding',
    title: '智能编程',
    description: '基于AI的代码补全，重构建议和错误修复',
    icon: Icons.code,
    color: Colors.blue,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'ai_assistant',
    title: 'AI助手',
    description: '自然语言交互，帮助你更快地解决问题',
    icon: Icons.smart_toy,
    color: Colors.green,
  ),
  FeatureItem(
    id: 'knowledge_graph',
    title: '知识图谱',
    description: '智能代码分析和项目依赖可视化',
    icon: Icons.account_tree,
    color: Colors.purple,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'dev_tools',
    title: '开发工具',
    description: '丰富的开发工具集成',
    icon: Icons.build,
    color: Colors.orange,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'learning',
    title: '学习系统',
    description: '个性化学习路径和教程',
    icon: Icons.school,
    color: Colors.teal,
    supportedModes: {UserMode.guardian},
  ),
  FeatureItem(
    id: 'collaboration',
    title: '团队协作',
    description: '高效的团队协作功能',
    icon: Icons.groups,
    color: Colors.indigo,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'debug_console',
    title: '调试控制台',
    description: '强大的调试工具，断点管理，变量监控，性能分析',
    icon: Icons.terminal,
    color: Colors.grey[700]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'code_review',
    title: '代码审查',
    description: '智能代码审查，质量检测，最佳实践建议',
    icon: Icons.rate_review,
    color: Colors.amber,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'project_templates',
    title: '项目模板',
    description: '快速创建标准化项目，丰富的模板库',
    icon: Icons.folder_special,
    color: Colors.cyan,
    supportedModes: {UserMode.standard, UserMode.guardian},
  ),
  FeatureItem(
    id: 'interactive_tutorial',
    title: '交互教程',
    description: '手把手教学，实时反馈，循序渐进',
    icon: Icons.lightbulb,
    color: Colors.amber[700]!,
    supportedModes: {UserMode.guardian},
  ),
  FeatureItem(
    id: 'git_integration',
    title: 'Git集成',
    description: '版本控制，分支管理，代码协作',
    icon: Icons.source,
    color: Colors.orange[800]!,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'remote_dev',
    title: '远程开发',
    description: '远程协作，云端开发环境，实时同步',
    icon: Icons.cloud_done,
    color: Colors.lightBlue,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'plugin_market',
    title: '插件市场',
    description: '丰富的插件生态，自定义扩展功能',
    icon: Icons.extension,
    color: Colors.deepPurple,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'code_snippets',
    title: '代码片段',
    description: '常用代码片段管理，快速复用',
    icon: Icons.content_paste,
    color: Colors.green[700]!,
    supportedModes: {UserMode.standard, UserMode.guardian},
  ),
  FeatureItem(
    id: 'performance_monitor',
    title: '性能监控',
    description: '实时性能分析，资源占用监控，优化建议',
    icon: Icons.speed,
    color: Colors.red,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'documentation',
    title: '文档中心',
    description: '智能文档生成，API参考，使用指南',
    icon: Icons.description,
    color: Colors.blue[700]!,
    supportedModes: {UserMode.standard, UserMode.guardian},
  ),
  FeatureItem(
    id: 'architecture_design',
    title: '架构设计',
    description: '系统架构设计，组件关系图，架构决策记录',
    icon: Icons.architecture,
    color: Colors.blueGrey[700]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'system_modeling',
    title: '系统建模',
    description: 'UML建模，数据流图，状态图设计工具',
    icon: Icons.schema,
    color: Colors.indigo[600]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'tech_stack_analyzer',
    title: '技术栈分析',
    description: '技术选型分析，依赖评估，兼容性检查',
    icon: Icons.analytics,
    color: Colors.deepPurple[600]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'ui_design',
    title: 'UI设计工具',
    description: '界面设计，原型制作，设计系统管理',
    icon: Icons.design_services,
    color: Colors.pink[400]!,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'design_system',
    title: '设计系统',
    description: '组件库，样式指南，设计token管理',
    icon: Icons.style,
    color: Colors.deepOrange[400]!,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'design_preview',
    title: '设计预览',
    description: '实时预览，响应式测试，主题切换',
    icon: Icons.preview,
    color: Colors.purple[400]!,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'test_management',
    title: '测试管理',
    description: '测试用例管理，自动化测试，测试报告',
    icon: Icons.rule,
    color: Colors.green[600]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'quality_assurance',
    title: '质量保证',
    description: '代码质量检测，性能测试，安全扫描',
    icon: Icons.verified,
    color: Colors.teal[600]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'ci_cd',
    title: 'CI/CD',
    description: '持续集成，自动部署，流水线管理',
    icon: Icons.sync,
    color: Colors.blue[800]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'container_management',
    title: '容器管理',
    description: 'Docker集成，容器编排，服务管理',
    icon: Icons.view_compact,
    color: Colors.cyan[700]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'requirement_management',
    title: '需求管理',
    description: '需求收集，用户故事，任务分解',
    icon: Icons.assignment,
    color: Colors.amber[700]!,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'project_planning',
    title: '项目规划',
    description: '项目计划，进度追踪，资源分配',
    icon: Icons.calendar_today,
    color: Colors.brown[600]!,
    supportedModes: {UserMode.standard, UserMode.professional},
  ),
  FeatureItem(
    id: 'security_testing',
    title: '安全测试',
    description: '漏洞扫描，渗透测试，安全审计',
    icon: Icons.security,
    color: Colors.red[700]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'compliance_check',
    title: '合规检查',
    description: '代码合规性检查，许可证管理，安全标准',
    icon: Icons.gavel,
    color: Colors.grey[800]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'database_design',
    title: '数据库设计',
    description: '数据库模型设计，性能优化，迁移管理',
    icon: Icons.storage,
    color: Colors.blue[900]!,
    supportedModes: {UserMode.professional},
  ),
  FeatureItem(
    id: 'data_visualization',
    title: '数据可视化',
    description: '数据分析图表，实时监控，报表生成',
    icon: Icons.insert_chart,
    color: Colors.lightBlue[700]!,
    supportedModes: {UserMode.professional},
  ),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(userModeProvider);
    final features = allFeatures.where((f) => f.supportedModes.contains(currentMode)).toList();

    Widget buildFeatureCard(FeatureItem feature, BoxConstraints constraints) {
      final isSmall = constraints.maxWidth < 600;
      
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            if (feature.id == 'smart_coding') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CodingScreen(),
                ),
              );
            } else if (feature.id == 'ai_assistant') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AIAssistantEntry(),
                ),
              );
            } else if (feature.id == 'learning') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LearningScreen(),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmall ? 16 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  feature.icon,
                  size: isSmall ? 32 : 48,
                  color: feature.color,
                ),
                SizedBox(height: isSmall ? 12 : 16),
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmall ? 6 : 8),
                Text(
                  feature.description,
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和模式切换区域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '欢迎使用 xEwo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '你的智能编程助手 - ${currentMode.label}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              _buildModeSelector(context, ref),
            ],
          ),
          const SizedBox(height: 32),
          
          // 功能卡片网格
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.extent(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.3,
                children: features.map((feature) => buildFeatureCard(
                  feature,
                  constraints,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<UserMode>(
        initialValue: ref.read(userModeProvider),
        onSelected: (mode) {
          ref.read(userModeProvider.notifier).state = mode;
          
          // 同步更新AI助手模式
          switch (mode) {
            case UserMode.guardian:
              ref.read(currentModeProvider.notifier).state = AssistantMode.guardian;
              break;
            case UserMode.professional:
              ref.read(currentModeProvider.notifier).state = AssistantMode.pro;
              break;
            case UserMode.standard:
              ref.read(currentModeProvider.notifier).state = AssistantMode.standard;
              break;
          }
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ref.read(userModeProvider).label),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        itemBuilder: (context) => UserMode.values.map((mode) => PopupMenuItem(
          value: mode,
          child: ListTile(
            title: Text(mode.label),
            subtitle: Text(mode.description),
            selected: ref.read(userModeProvider) == mode,
          ),
        )).toList(),
      ),
    );
  }
} 