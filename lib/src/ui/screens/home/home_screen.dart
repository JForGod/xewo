import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_theme.dart';

/// 功能项模型
class FeatureItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  const FeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// 主页面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 已实现的功能列表
  final List<FeatureItem> _features = [
    const FeatureItem(
      id: 'editor',
      title: '代码编辑器',
      description: '支持语法高亮、代码补全、格式化等功能的高级代码编辑器',
      icon: Icons.code,
      color: Colors.blue,
    ),
    const FeatureItem(
      id: 'database',
      title: 'SQL编辑器',
      description: '支持SQL语法高亮、智能提示、格式化和执行的数据库查询工具',
      icon: Icons.storage,
      color: Colors.green,
    ),
    const FeatureItem(
      id: 'ai',
      title: 'AI助手',
      description: '智能AI助手，提供代码建议、问题解答和智能补全',
      icon: Icons.smart_toy,
      color: Colors.purple,
    ),
    const FeatureItem(
      id: 'projects',
      title: '项目管理',
      description: '管理和组织您的项目，包括文件浏览、创建和导入',
      icon: Icons.folder,
      color: Colors.orange,
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '欢迎使用 xEwo IDE',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              '您的智能编码助手',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24.0),
            
            // 功能列表
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return _buildFeatureCard(feature);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建功能卡片
  Widget _buildFeatureCard(FeatureItem feature) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: () {
          // 导航到对应功能页面
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${feature.title}功能开发中')),
          );
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: feature.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Icon(
                      feature.icon,
                      color: feature.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      feature.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: Text(
                  feature.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 