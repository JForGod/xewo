import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../common/logo_placeholder.dart';

class AiAssistantPanel extends StatelessWidget {       
  const AiAssistantPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppTheme.neutral200),
        ),
      ),
      child: Column(
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd), 
            decoration: BoxDecoration(
              color: AppTheme.primary50,
              border: Border(
                bottom: BorderSide(color: AppTheme.neutral200),
              ),
            ),
            child: Row(
              children: [
                const LogoPlaceholder(size: 32, color: Colors.blue),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'xEwo AI助手',
                        style: AppTheme.titleMedium,
                      ),
                      Text(
                        '您的智能编码伙伴',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                  tooltip: '设置',
                ),
              ],
            ),
          ),

          // 聊天区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.smart_toy,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'AI助手已准备就绪',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      '有什么可以帮助您的？',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 输入区域
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.neutral200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 250,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '输入您的问题...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.neutral100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd,
                          vertical: AppTheme.spacingSm,
                        ),
                        isDense: true,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                  color: Colors.blue,
                  tooltip: '发送',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 