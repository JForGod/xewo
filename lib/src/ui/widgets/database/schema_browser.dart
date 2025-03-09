import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database/database_service.dart';

class SchemaBrowser extends ConsumerStatefulWidget {
  final String connectionName;

  const SchemaBrowser({
    super.key,
    required this.connectionName,
  });

  @override
  ConsumerState<SchemaBrowser> createState() => _SchemaBrowserState();
}

class _SchemaBrowserState extends ConsumerState<SchemaBrowser> {
  Map<String, dynamic>? _schema;
  String? _error;
  bool _isLoading = false;
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _loadSchema();
  }

  Future<void> _loadSchema() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final schema = await databaseService.getSchema(widget.connectionName);
      setState(() {
        _schema = schema;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSchema,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_schema == null || _schema!.isEmpty) {
      return const Center(
        child: Text('没有找到数据表'),
      );
    }

    return Row(
      children: [
        // 表列表
        SizedBox(
          width: 200,
          child: Card(
            child: ListView.builder(
              itemCount: _schema!.length,
              itemBuilder: (context, index) {
                final tableName = _schema!.keys.elementAt(index);
                return ListTile(
                  title: Text(tableName),
                  selected: tableName == _selectedTable,
                  onTap: () {
                    setState(() {
                      _selectedTable = tableName;
                    });
                  },
                );
              },
            ),
          ),
        ),
        
        // 表详情
        if (_selectedTable != null) ...[
          const VerticalDivider(),
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _selectedTable!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('列名')),
                          DataColumn(label: Text('类型')),
                          DataColumn(label: Text('可空')),
                          DataColumn(label: Text('主键')),
                        ],
                        rows: (_schema![_selectedTable] as List)
                            .map((column) => DataRow(
                              cells: [
                                DataCell(Text(column['name'].toString())),
                                DataCell(Text(column['type'].toString())),
                                DataCell(Text(!column['notnull'] ? '是' : '否')),
                                DataCell(Text(column['pk'] ? '是' : '否')),
                              ],
                            ))
                            .toList(),
                      ),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // TODO: 导出表结构
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('导出结构'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: 导出数据
                          },
                          icon: const Icon(Icons.import_export),
                          label: const Text('导出数据'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
} 