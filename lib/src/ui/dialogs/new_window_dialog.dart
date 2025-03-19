import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../../state/providers/editor_provider.dart';

class NewWindowDialog extends ConsumerWidget {
  const NewWindowDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final recentProjects = editorState.recentProjects ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '新建窗口',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // 主要操作按钮
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.home,
                    label: '欢迎页',
                    onPressed: () {
                      Navigator.pop(context, {
                        'action': 'welcome',
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.folder_open,
                    label: '打开项目',
                    onPressed: () {
                      Navigator.pop(context, {
                        'action': 'open_project',
                      });
                    },
                  ),
                ),
              ],
            ),
            
            if (recentProjects.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '最近的项目',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // 最近项目列表
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recentProjects.length,
                  itemBuilder: (context, index) {
                    final projectPath = recentProjects[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(path.basename(projectPath)),
                      subtitle: Text(projectPath),
                      onTap: () {
                        Navigator.pop(context, {
                          'action': 'open_recent',
                          'path': projectPath,
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
} 