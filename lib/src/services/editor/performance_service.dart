import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 性能优化服务
class PerformanceService {
  static const int chunkSize = 5000; // 每个块的行数
  static const int visibleLinesBuffer = 100; // 可见行的缓冲区

  /// 分块加载文本
  Future<List<String>> loadTextInChunks(String text) async {
    final dynamic result = await compute(_splitTextIntoLines, text);
    // 确保返回List<String>类型
    if (result is List) {
      return result.map((line) => line.toString()).toList();
    }
    // 如果结果不是List，返回空列表
    return [];
  }

  /// 获取可见区域的文本
  List<String> getVisibleLines(
    List<String> lines,
    int startLine,
    int endLine,
  ) {
    final start = (startLine - visibleLinesBuffer).clamp(0, lines.length);
    final end = (endLine + visibleLinesBuffer).clamp(0, lines.length);
    return lines.sublist(start, end);
  }

  /// 增量更新文本
  String updateTextIncrementally(
    String oldText,
    String newText,
    int startOffset,
    int endOffset,
  ) {
    if (startOffset < 0 || endOffset > oldText.length) {
      return newText;
    }

    return oldText.replaceRange(startOffset, endOffset, newText);
  }

  /// 延迟处理长文本操作
  Future<T> deferLongOperation<T>({
    required Future<T> Function() operation,
    Duration threshold = const Duration(milliseconds: 16),
  }) async {
    return await compute(
      (message) async {
        final op = message as Future<T> Function();
        return await op();
      },
      operation,
    );
  }
}

/// 在隔离进程中分割文本
List<String> _splitTextIntoLines(String text) {
  final lines = text.split('\n');
  // 确保返回的是List<String>
  return lines.map((line) => line.toString()).toList();
}

/// 性能优化服务提供者
final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService();
}); 