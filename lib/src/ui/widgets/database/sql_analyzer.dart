import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database/xewo_sql_analyzer.dart';
import '../../themes/app_theme.dart';

/// SQL分析器组件
class SqlAnalyzer extends ConsumerWidget {
  final String connectionName;
  final String query;
  
  const SqlAnalyzer({
    Key? key,
    required this.connectionName,
    required this.query,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyzer = ref.watch(sqlAnalyzerProvider);

    return FutureBuilder<SqlAnalysisResult>(
      future: analyzer.analyzeQuery(connectionName, query),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Error analyzing query: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.issues.isNotEmpty) ...[
              const Text(
                'Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.issues.map((issue) => Text(
                '• $issue',
                style: const TextStyle(color: Colors.red),
              )),
              const SizedBox(height: 16),
            ],
            if (result.executionPlan != null) ...[
              const Text(
                'Execution Plan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(result.executionPlan!),
              const SizedBox(height: 16),
            ],
            const Text(
              'Statistics:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...result.statistics.entries.map((entry) => Text(
              '• ${entry.key}: ${entry.value}',
            )),
            const SizedBox(height: 16),
            if (result.suggestions.isNotEmpty) ...[
              const Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.suggestions.map((suggestion) => Text(
                '• $suggestion',
                style: const TextStyle(color: Colors.blue),
              )),
            ],
          ],
        );
      },
    );
  }
} 