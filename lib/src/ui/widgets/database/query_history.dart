import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database/query_history_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class QueryHistory extends ConsumerStatefulWidget {
  final String connectionName;
  final Function(String) onQuerySelected;

  const QueryHistory({
    super.key,
    required this.connectionName,
    required this.onQuerySelected,
  });

  @override
  ConsumerState<QueryHistory> createState() => _QueryHistoryState();
}

class _QueryHistoryState extends ConsumerState<QueryHistory> {
  String _searchKeyword = '';
  bool _showStarredOnly = false;

  @override
  Widget build(BuildContext context) {
    final historyService = ref.watch(queryHistoryServiceProvider);
    List<QueryRecord> records;

    if (_showStarredOnly) {
      records = historyService.getStarredRecords();
    } else if (_searchKeyword.isNotEmpty) {
      records = historyService.searchRecords(_searchKeyword);
    } else {
      records = historyService.getConnectionRecords(widget.connectionName);
    }

    return Column(
      children: [
        // 搜索和过滤
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '搜索查询历史...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchKeyword = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('收藏'),
                selected: _showStarredOnly,
                onSelected: (value) {
                  setState(() {
                    _showStarredOnly = value;
                  });
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '清除历史',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('清除历史记录'),
                      content: const Text('是否要清除所有查询历史？\n收藏的记录将被保留。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await historyService.clearHistory();
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // 历史记录列表
        Expanded(
          child: ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                child: ListTile(
                  title: Text(
                    record.sql,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '执行时间：${record.executionTime.inMilliseconds}ms • ${timeago.format(record.timestamp, locale: 'zh')}',
                  ),
                  leading: IconButton(
                    icon: Icon(
                      record.isStarred ? Icons.star : Icons.star_border,
                      color: record.isStarred ? Colors.amber : null,
                    ),
                    onPressed: () {
                      historyService.toggleStar(record.id);
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: '复制',
                        onPressed: () {
                          widget.onQuerySelected(record.sql);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: '删除',
                        onPressed: () {
                          historyService.deleteRecord(record.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    widget.onQuerySelected(record.sql);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 