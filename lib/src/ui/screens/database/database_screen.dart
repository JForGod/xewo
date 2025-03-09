import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database/database_service.dart';
import '../../widgets/database/query_executor.dart';
import '../../widgets/database/schema_browser.dart';

/// 数据库功能集成页面
class DatabaseScreen extends ConsumerWidget {
  const DatabaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseService = ref.watch(databaseServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库管理'),
      ),
      body: QueryExecutor(
        connectionName: 'default',
        databaseService: databaseService,
      ),
    );
  }
} 