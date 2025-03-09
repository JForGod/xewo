import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database/database_service.dart';
import '../../../services/database/query_history_service.dart';
import '../../themes/app_theme.dart';
import '../editor/editor_core.dart';
import 'query_history.dart';
import 'sql_analyzer.dart';
import 'sql_completion.dart';
import '../../../services/formatter/sql_formatter_service.dart';
import '../../../services/database/query_result.dart';

class QueryExecutor extends ConsumerStatefulWidget {
  final String connectionName;
  final DatabaseService databaseService;

  const QueryExecutor({
    Key? key,
    required this.connectionName,
    required this.databaseService,
  }) : super(key: key);

  @override
  ConsumerState<QueryExecutor> createState() => _QueryExecutorState();
}

class _QueryExecutorState extends ConsumerState<QueryExecutor> {
  final _queryController = TextEditingController();
  QueryResult? _result;
  String? _error;
  bool _isExecuting = false;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextEditingController _sqlController = TextEditingController();
  bool _showHistory = false;
  bool _showAnalyzer = false;
  final LayerLink _completionLayerLink = LayerLink();
  OverlayEntry? _completionOverlay;
  int _cursorOffset = 0;
  late final SqlFormatterService _sqlFormatterService;

  @override
  void initState() {
    super.initState();
    _sqlFormatterService = ref.read(sqlFormatterServiceProvider);
    _executeQuery();
  }

  @override
  void didUpdateWidget(QueryExecutor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectionName != oldWidget.connectionName ||
        widget.databaseService != oldWidget.databaseService) {
      _executeQuery();
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _sqlController.dispose();
    _hideCompletion();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _executeQuery() async {
    if (_queryController.text.isEmpty) {
      setState(() {
        _error = 'Query cannot be empty';
        _result = null;
      });
      return;
    }

    setState(() {
      _isExecuting = true;
      _error = null;
    });

    try {
      final result = await widget.databaseService.executeQuery(
        widget.connectionName,
        _queryController.text,
      );
      setState(() {
        _result = result;
        _isExecuting = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _result = null;
        _isExecuting = false;
      });
    }
  }

  void _onHistorySelected(String sql) {
    setState(() {
      _sqlController.text = sql;
      _showHistory = false;
    });
  }

  void _showCompletion(String text, int offset) {
    _hideCompletion();

    // 获取当前光标位置
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context);

    _completionOverlay = OverlayEntry(
      builder: (context) => Positioned(
        child: CompositedTransformFollower(
          link: _completionLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 20),
          child: SqlCompletion(
            connectionName: widget.connectionName,
            text: text,
            offset: offset,
            onSelected: (suggestion) {
              final beforeCursor = _sqlController.text.substring(0, offset);
              final afterCursor = _sqlController.text.substring(offset);
              _sqlController.value = TextEditingValue(
                text: beforeCursor + suggestion + afterCursor,
                selection: TextSelection.collapsed(offset: beforeCursor.length + suggestion.length),
              );
              _hideCompletion();
            },
          ),
        ),
      ),
    );

    overlay.insert(_completionOverlay!);
  }

  void _hideCompletion() {
    _completionOverlay?.remove();
    _completionOverlay = null;
  }

  /// 格式化SQL代码
  Future<void> _formatSql() async {
    final currentText = _sqlController.text;
    if (currentText.trim().isEmpty) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      final formattedSql = await _sqlFormatterService.formatCode(currentText);
      _sqlController.value = TextEditingValue(
        text: formattedSql,
        selection: TextSelection.collapsed(offset: formattedSql.length),
      );
    } catch (e) {
      _showErrorSnackBar('格式化SQL失败: $e');
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 40,
          ),
          child: TextField(
            controller: _queryController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'SQL Query',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isExecuting ? null : _executeQuery,
          child: _isExecuting
              ? const CircularProgressIndicator()
              : const Text('Execute Query'),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
        if (_result != null) ...[
          Text(
            'Execution Time: ${_result!.executionTime.inMilliseconds}ms',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Affected Rows: ${_result!.affectedRows}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _result!.columns
                  .map((col) => DataColumn(label: Text(col)))
                  .toList(),
              rows: _result!.rows
                  .map(
                    (row) => DataRow(
                      cells: row
                          .map((cell) => DataCell(Text(cell.toString())))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: '执行查询',
            onPressed: _isExecuting
                ? null
                : () => _executeQuery(),
          ),
          IconButton(
            icon: const Icon(Icons.format_align_left),
            tooltip: '格式化SQL',
            onPressed: _formatSql,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存查询',
            onPressed: _saveQuery,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '加载查询',
            onPressed: _loadQuery,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              setState(() {
                _showAnalyzer = !_showAnalyzer;
              });
            },
            tooltip: '${_showAnalyzer ? '隐藏' : '显示'}SQL分析器',
          ),
          IconButton(
            icon: Icon(
              _showHistory ? Icons.history_toggle_off : Icons.history,
            ),
            tooltip: _showHistory ? '隐藏历史' : '显示历史',
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuery() async {
    // 实现保存查询功能
    final currentText = _sqlController.text;
    if (currentText.trim().isEmpty) return;
    
    // 这里可以添加保存对话框和保存逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存查询功能即将实现')),
    );
  }

  Future<void> _loadQuery() async {
    // 实现加载查询功能
    // 这里可以添加加载对话框和加载逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('加载查询功能即将实现')),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
} 