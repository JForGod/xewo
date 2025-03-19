import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final largeFileHandlerProvider = Provider((ref) => LargeFileHandler());

class LargeFileHandler {
  static const int chunkSize = 1024 * 1024; // 1MB
  static const int maxLoadSize = 100 * 1024 * 1024; // 100MB
  
  // 分块加载文件内容
  Future<String> loadLargeFile(String filePath, {
    int? startOffset,
    int? endOffset,
    void Function(double)? onProgress,
  }) async {
    final file = File(filePath);
    final fileSize = await file.length();
    
    // 检查文件大小
    if (fileSize > maxLoadSize) {
      throw Exception('文件过大，超过最大限制 ${maxLoadSize ~/ (1024 * 1024)}MB');
    }
    
    // 如果没有指定范围，则加载整个文件
    startOffset ??= 0;
    endOffset ??= fileSize;
    
    final chunks = <String>[];
    final stream = file.openRead(startOffset, endOffset);
    int loadedSize = 0;
    
    await for (final chunk in stream.transform(StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        loadedSize += data.length;
        if (onProgress != null) {
          onProgress(loadedSize / fileSize);
        }
        sink.add(data);
      },
    ))) {
      chunks.add(String.fromCharCodes(chunk));
    }
    
    return chunks.join();
  }
  
  // 分块保存文件内容
  Future<void> saveLargeFile(String filePath, String content, {
    void Function(double)? onProgress,
  }) async {
    final file = File(filePath);
    final sink = file.openWrite();
    final contentLength = content.length;
    int savedSize = 0;
    
    for (var i = 0; i < contentLength; i += chunkSize) {
      final end = (i + chunkSize < contentLength) ? i + chunkSize : contentLength;
      final chunk = content.substring(i, end);
      await sink.write(chunk);
      
      savedSize += chunk.length;
      if (onProgress != null) {
        onProgress(savedSize / contentLength);
      }
    }
    
    await sink.close();
  }
  
  // 检查是否是大文件
  bool isLargeFile(String filePath) {
    final file = File(filePath);
    return file.lengthSync() > chunkSize;
  }
  
  // 获取文件大小的可读字符串
  String getFileSizeString(String filePath) {
    final size = File(filePath).lengthSync();
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  // 获取文件行数
  Future<int> getLineCount(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return 0;
    }
    
    int lineCount = 0;
    final stream = file.openRead();
    await for (final _ in stream.transform(const LineSplitter())) {
      lineCount++;
    }
    return lineCount;
  }
  
  // 读取指定行范围的内容
  Future<String> readLines(String filePath, {
    required int startLine,
    required int endLine,
    void Function(double)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return '';
    }
    
    final lines = <String>[];
    int currentLine = 0;
    final stream = file.openRead();
    
    await for (final line in stream.transform(const LineSplitter())) {
      currentLine++;
      if (currentLine >= startLine && currentLine <= endLine) {
        lines.add(line);
      }
      if (onProgress != null) {
        onProgress(currentLine / endLine);
      }
      if (currentLine > endLine) {
        break;
      }
    }
    
    return lines.join('\n');
  }
  
  // 搜索大文件
  Future<List<SearchResult>> searchInLargeFile(
    String filePath,
    String searchText, {
    bool caseSensitive = false,
    bool wholeWord = false,
    bool useRegex = false,
    void Function(double)? onProgress,
  }) async {
    final results = <SearchResult>[];
    final file = File(filePath);
    if (!await file.exists()) {
      return results;
    }
    
    final fileSize = await file.length();
    int processedSize = 0;
    int lineNumber = 0;
    int charOffset = 0;
    
    final pattern = useRegex ? RegExp(searchText, caseSensitive: caseSensitive)
        : wholeWord ? RegExp(r'\b' + RegExp.escape(searchText) + r'\b', caseSensitive: caseSensitive)
        : RegExp(RegExp.escape(searchText), caseSensitive: caseSensitive);
    
    final stream = file.openRead();
    await for (final line in stream.transform(const LineSplitter())) {
      lineNumber++;
      processedSize += line.length + 1; // +1 for newline
      
      for (final match in pattern.allMatches(line)) {
        results.add(SearchResult(
          lineNumber: lineNumber,
          lineContent: line,
          startOffset: charOffset + match.start,
          endOffset: charOffset + match.end,
        ));
      }
      
      charOffset += line.length + 1;
      
      if (onProgress != null) {
        onProgress(processedSize / fileSize);
      }
    }
    
    return results;
  }
}

class SearchResult {
  final int lineNumber;
  final String lineContent;
  final int startOffset;
  final int endOffset;
  
  const SearchResult({
    required this.lineNumber,
    required this.lineContent,
    required this.startOffset,
    required this.endOffset,
  });
} 