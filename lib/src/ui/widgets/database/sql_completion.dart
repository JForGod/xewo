import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database/sql_completion_service.dart';

class SqlCompletion extends ConsumerStatefulWidget {
  final String connectionName;
  final String text;
  final int offset;
  final Function(String) onSelected;

  const SqlCompletion({
    super.key,
    required this.connectionName,
    required this.text,
    required this.offset,
    required this.onSelected,
  });

  @override
  ConsumerState<SqlCompletion> createState() => _SqlCompletionState();
}

class _SqlCompletionState extends ConsumerState<SqlCompletion> {
  List<CompletionItem>? _suggestions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(SqlCompletion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text || widget.offset != oldWidget.offset) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(sqlCompletionServiceProvider);
      final suggestions = await service.getCompletions(
        connectionName: widget.connectionName,
        text: widget.text,
        offset: widget.offset,
      );
      setState(() {
        _suggestions = suggestions;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 2,
        child: LinearProgressIndicator(),
      );
    }

    if (_suggestions == null || _suggestions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 200,
          maxWidth: 300,
        ),
        child: ListView.builder(
          itemCount: _suggestions!.length,
          itemBuilder: (context, index) {
            final item = _suggestions![index];
            return ListTile(
              dense: true,
              leading: _buildIcon(item.kind),
              title: Text(item.label),
              subtitle: item.detail != null ? Text(item.detail!) : null,
              onTap: () => widget.onSelected(item.insertText),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(CompletionItemKind kind) {
    final icon = switch (kind) {
      CompletionItemKind.keyword => Icons.key,
      CompletionItemKind.table => Icons.table_chart,
      CompletionItemKind.column => Icons.view_column,
      CompletionItemKind.function => Icons.functions,
      CompletionItemKind.operator => Icons.calculate,
      CompletionItemKind.snippet => Icons.code,
    };

    final color = switch (kind) {
      CompletionItemKind.keyword => Colors.blue,
      CompletionItemKind.table => Colors.green,
      CompletionItemKind.column => Colors.orange,
      CompletionItemKind.function => Colors.purple,
      CompletionItemKind.operator => Colors.red,
      CompletionItemKind.snippet => Colors.teal,
    };

    return Icon(icon, color: color, size: 20);
  }
} 