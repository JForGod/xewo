import 'package:flutter/material.dart';
import '../../../services/editor/completion_service.dart';

/// 代码补全小部件
class CompletionWidget extends StatelessWidget {
  final LayerLink layerLink;
  final List<CompletionItem> items;
  final ValueChanged<CompletionItem> onSelected;
  
  const CompletionWidget({
    super.key,
    required this.layerLink,
    required this.items,
    required this.onSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      link: layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 300,
            maxHeight: 200,
          ),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: _buildIcon(item.kind),
                title: Text(item.label),
                subtitle: item.detail != null ? Text(item.detail!) : null,
                dense: true,
                onTap: () => onSelected(item),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildIcon(CompletionItemKind kind) {
    IconData iconData;
    Color color;
    
    switch (kind) {
      case CompletionItemKind.method:
      case CompletionItemKind.function:
        iconData = Icons.functions;
        color = Colors.blue;
        break;
      case CompletionItemKind.constructor:
        iconData = Icons.build;
        color = Colors.orange;
        break;
      case CompletionItemKind.field:
      case CompletionItemKind.variable:
        iconData = Icons.data_array;
        color = Colors.green;
        break;
      case CompletionItemKind.class_:
      case CompletionItemKind.interface:
        iconData = Icons.category;
        color = Colors.purple;
        break;
      case CompletionItemKind.module:
        iconData = Icons.folder;
        color = Colors.brown;
        break;
      case CompletionItemKind.property:
        iconData = Icons.settings;
        color = Colors.teal;
        break;
      case CompletionItemKind.keyword:
        iconData = Icons.key;
        color = Colors.red;
        break;
      case CompletionItemKind.snippet:
        iconData = Icons.code;
        color = Colors.indigo;
        break;
      default:
        iconData = Icons.text_fields;
        color = Colors.grey;
    }
    
    return Icon(
      iconData,
      size: 16,
      color: color,
    );
  }
} 