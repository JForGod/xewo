import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

enum MessageType {
  assistant,
  user,
  system,
}

class MessageBubble extends StatelessWidget {
  final String message;
  final MessageType type;
  final DateTime? timestamp;
  final Widget? avatar;
  final AssistantMode mode;
  final VoidCallback? onTap;
  
  const MessageBubble({
    Key? key,
    required this.message,
    this.type = MessageType.assistant,
    this.timestamp,
    this.avatar,
    this.mode = AssistantMode.standard,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MessageType.user:
        return _buildUserMessage();
      case MessageType.system:
        return _buildSystemMessage();
      case MessageType.assistant:
      default:
        return _buildAssistantMessage();
    }
  }

  Widget _buildAssistantMessage() {
    final primaryColor = AIAssistantTheme.getPrimaryColorByMode(mode);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          avatar ?? Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                mode == AssistantMode.pro ? 'AI+' : 'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mode == AssistantMode.pro ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // 消息内容
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(timestamp!),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage() {
    final accentColor = mode == AssistantMode.guardian
        ? const Color(0xFFE06CA0)
        : mode == AssistantMode.pro
            ? const Color(0xFF6FD08C)
            : const Color(0xFF82D2B4);
            
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 消息内容
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(timestamp!),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // 头像
          avatar ?? Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '👤',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  }
  
  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
}
