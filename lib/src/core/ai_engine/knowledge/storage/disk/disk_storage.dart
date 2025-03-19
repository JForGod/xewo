import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../knowledge_base.dart';
import '../storage_interface.dart';
import '../memory/memory_storage.dart';

/// 磁盘存储实现
class DiskStorage implements StorageInterface {
  /// 内存存储实例（作为缓存）
  final MemoryStorage _memoryStorage = MemoryStorage();
  
  /// 存储根目录
  late final String _rootDir;
  
  /// 知识目录
  late final String _knowledgeDir;
  
  /// 向量目录
  late final String _vectorDir;
  
  /// 索引文件路径
  late final String _indexFilePath;
  
  /// 标签索引文件路径
  late final String _tagIndexFilePath;
  
  /// 统计信息文件路径
  late final String _statsFilePath;
  
  /// 初始化状态
  bool _isInitialized = false;
  
  /// 保存队列
  final List<Future<void>> _saveQueue = [];
  
  /// 构造函数
  DiskStorage();
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 获取应用文档目录
    final appDir = await getApplicationDocumentsDirectory();
    _rootDir = path.join(appDir.path, 'ai_assistant', 'knowledge');
    
    // 创建必要的目录
    _knowledgeDir = path.join(_rootDir, 'entries');
    _vectorDir = path.join(_rootDir, 'vectors');
    _indexFilePath = path.join(_rootDir, 'index.json');
    _tagIndexFilePath = path.join(_rootDir, 'tag_index.json');
    _statsFilePath = path.join(_rootDir, 'stats.json');
    
    await _createDirectoriesIfNeeded();
    
    // 加载索引和数据
    await _loadFromDisk();
    
    _isInitialized = true;
  }
  
  /// 创建必要的目录
  Future<void> _createDirectoriesIfNeeded() async {
    final rootDir = Directory(_rootDir);
    if (!await rootDir.exists()) {
      await rootDir.create(recursive: true);
    }
    
    final knowledgeDir = Directory(_knowledgeDir);
    if (!await knowledgeDir.exists()) {
      await knowledgeDir.create(recursive: true);
    }
    
    final vectorDir = Directory(_vectorDir);
    if (!await vectorDir.exists()) {
      await vectorDir.create(recursive: true);
    }
  }
  
  /// 从磁盘加载数据
  Future<void> _loadFromDisk() async {
    try {
      // 加载索引文件
      final indexFile = File(_indexFilePath);
      if (await indexFile.exists()) {
        final indexContent = await indexFile.readAsString();
        final indexData = jsonDecode(indexContent) as List<dynamic>;
        
        // 加载知识条目
        for (final id in indexData) {
          final knowledgeFile = File(path.join(_knowledgeDir, '$id.json'));
          if (await knowledgeFile.exists()) {
            final knowledgeContent = await knowledgeFile.readAsString();
            final knowledgeData = jsonDecode(knowledgeContent) as Map<String, dynamic>;
            
            // 加载向量（如果存在）
            List<double>? embedding;
            final vectorFile = File(path.join(_vectorDir, '$id.json'));
            if (await vectorFile.exists()) {
              final vectorContent = await vectorFile.readAsString();
              final vectorData = jsonDecode(vectorContent) as List<dynamic>;
              embedding = vectorData.cast<double>();
            }
            
            // 创建知识对象并添加到内存存储
            final knowledge = Knowledge.fromMap(knowledgeData);
            final updatedKnowledge = knowledge.copyWith(embedding: embedding);
            await _memoryStorage.store(updatedKnowledge);
          }
        }
      }
    } catch (e) {
      print('从磁盘加载知识数据时出错: $e');
    }
  }
  
  /// 保存索引到磁盘
  Future<void> _saveIndexToDisk() async {
    try {
      final indexFile = File(_indexFilePath);
      final stats = await _memoryStorage.getStats();
      final knowledgeIds = (await _getAllKnowledgeIds()).toList();
      
      // 保存索引
      await indexFile.writeAsString(jsonEncode(knowledgeIds));
      
      // 保存标签索引
      final tagIndexFile = File(_tagIndexFilePath);
      final allTags = await _memoryStorage.getAllTags();
      final tagIndex = <String, List<String>>{};
      
      for (final tag in allTags) {
        final knowledgeWithTag = await _memoryStorage.retrieveByTags([tag], limit: 1000);
        tagIndex[tag] = knowledgeWithTag.map((k) => k.id).toList();
      }
      
      await tagIndexFile.writeAsString(jsonEncode(tagIndex));
      
      // 保存统计信息
      final statsFile = File(_statsFilePath);
      await statsFile.writeAsString(jsonEncode(stats));
    } catch (e) {
      print('保存索引到磁盘时出错: $e');
    }
  }
  
  /// 将知识条目保存到磁盘
  Future<void> _saveKnowledgeToDisk(Knowledge knowledge) async {
    try {
      // 保存知识条目
      final knowledgeFile = File(path.join(_knowledgeDir, '${knowledge.id}.json'));
      final knowledgeData = knowledge.toMap();
      // 从知识数据中移除嵌入向量（单独存储）
      knowledgeData.remove('embedding');
      await knowledgeFile.writeAsString(jsonEncode(knowledgeData));
      
      // 保存向量（如果存在）
      if (knowledge.embedding != null && knowledge.embedding!.isNotEmpty) {
        final vectorFile = File(path.join(_vectorDir, '${knowledge.id}.json'));
        await vectorFile.writeAsString(jsonEncode(knowledge.embedding));
      }
    } catch (e) {
      print('保存知识条目到磁盘时出错: $e');
    }
  }
  
  /// 从磁盘删除知识条目
  Future<void> _deleteKnowledgeFromDisk(String id) async {
    try {
      // 删除知识文件
      final knowledgeFile = File(path.join(_knowledgeDir, '$id.json'));
      if (await knowledgeFile.exists()) {
        await knowledgeFile.delete();
      }
      
      // 删除向量文件
      final vectorFile = File(path.join(_vectorDir, '$id.json'));
      if (await vectorFile.exists()) {
        await vectorFile.delete();
      }
    } catch (e) {
      print('从磁盘删除知识条目时出错: $e');
    }
  }
  
  /// 获取所有知识条目ID
  Future<Set<String>> _getAllKnowledgeIds() async {
    final ids = <String>{};
    
    try {
      final knowledgeDir = Directory(_knowledgeDir);
      final entities = await knowledgeDir.list().toList();
      
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          final fileName = path.basename(entity.path);
          final id = fileName.substring(0, fileName.length - 5); // 移除 '.json'
          ids.add(id);
        }
      }
    } catch (e) {
      print('获取所有知识条目ID时出错: $e');
    }
    
    return ids;
  }
  
  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// 添加保存任务到队列
  Future<void> _enqueueSaveTask(Future<void> Function() task) async {
    final completer = Completer<void>();
    _saveQueue.add(completer.future);
    
    try {
      await task();
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _saveQueue.remove(completer.future);
    }
  }
  
  /// 等待所有保存任务完成
  Future<void> _waitForSaveTasks() async {
    if (_saveQueue.isEmpty) return;
    await Future.wait(_saveQueue);
  }
  
  @override
  Future<String> store(Knowledge knowledge) async {
    await _ensureInitialized();
    
    // 先存储到内存
    final id = await _memoryStorage.store(knowledge);
    
    // 再保存到磁盘
    await _enqueueSaveTask(() async {
      final updatedKnowledge = knowledge.copyWith(id: id);
      await _saveKnowledgeToDisk(updatedKnowledge);
      await _saveIndexToDisk();
    });
    
    return id;
  }
  
  @override
  Future<Knowledge?> retrieve(String id) async {
    await _ensureInitialized();
    return _memoryStorage.retrieve(id);
  }
  
  @override
  Future<List<Knowledge>> retrieveByTags(List<String> tags, {int limit = 10}) async {
    await _ensureInitialized();
    return _memoryStorage.retrieveByTags(tags, limit: limit);
  }
  
  @override
  Future<List<QueryResult>> search(
    String query, 
    List<double>? queryEmbedding, {
    QueryOptions options = const QueryOptions(),
  }) async {
    await _ensureInitialized();
    return _memoryStorage.search(query, queryEmbedding, options: options);
  }
  
  @override
  Future<void> update(Knowledge knowledge) async {
    await _ensureInitialized();
    
    // 更新内存存储
    await _memoryStorage.update(knowledge);
    
    // 保存到磁盘
    await _enqueueSaveTask(() async {
      await _saveKnowledgeToDisk(knowledge);
      await _saveIndexToDisk();
    });
  }
  
  @override
  Future<void> delete(String id) async {
    await _ensureInitialized();
    
    // 从内存存储中删除
    await _memoryStorage.delete(id);
    
    // 从磁盘删除
    await _enqueueSaveTask(() async {
      await _deleteKnowledgeFromDisk(id);
      await _saveIndexToDisk();
    });
  }
  
  @override
  Future<void> clear() async {
    await _ensureInitialized();
    
    // 清空内存存储
    await _memoryStorage.clear();
    
    // 清空磁盘存储
    await _enqueueSaveTask(() async {
      try {
        // 删除所有知识文件
        final knowledgeDir = Directory(_knowledgeDir);
        if (await knowledgeDir.exists()) {
          await knowledgeDir.delete(recursive: true);
          await knowledgeDir.create();
        }
        
        // 删除所有向量文件
        final vectorDir = Directory(_vectorDir);
        if (await vectorDir.exists()) {
          await vectorDir.delete(recursive: true);
          await vectorDir.create();
        }
        
        // 重置索引文件
        final indexFile = File(_indexFilePath);
        if (await indexFile.exists()) {
          await indexFile.writeAsString('[]');
        }
        
        // 重置标签索引文件
        final tagIndexFile = File(_tagIndexFilePath);
        if (await tagIndexFile.exists()) {
          await tagIndexFile.writeAsString('{}');
        }
        
        // 重置统计信息文件
        final statsFile = File(_statsFilePath);
        if (await statsFile.exists()) {
          await statsFile.writeAsString('{}');
        }
      } catch (e) {
        print('清空磁盘存储时出错: $e');
      }
    });
  }
  
  @override
  Future<int> count() async {
    await _ensureInitialized();
    return _memoryStorage.count();
  }
  
  @override
  Future<List<String>> getAllTags() async {
    await _ensureInitialized();
    return _memoryStorage.getAllTags();
  }
  
  @override
  Future<Map<String, dynamic>> getStats() async {
    await _ensureInitialized();
    final stats = await _memoryStorage.getStats();
    
    // 添加磁盘存储特有的统计信息
    try {
      var totalSize = 0;
      
      // 计算知识文件大小
      final knowledgeDir = Directory(_knowledgeDir);
      if (await knowledgeDir.exists()) {
        await for (final entity in knowledgeDir.list(recursive: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      // 计算向量文件大小
      final vectorDir = Directory(_vectorDir);
      if (await vectorDir.exists()) {
        await for (final entity in vectorDir.list(recursive: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      stats['diskUsage'] = totalSize;
      stats['diskUsageFormatted'] = _formatSize(totalSize);
    } catch (e) {
      print('获取磁盘使用统计信息时出错: $e');
    }
    
    return stats;
  }
  
  /// 格式化文件大小
  String _formatSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return size.toStringAsFixed(2) + ' ' + suffixes[i];
  }
  
  @override
  Future<List<double>> generateEmbedding(String text) async {
    throw UnimplementedError('磁盘存储不支持生成嵌入向量');
  }
  
  /// 关闭存储
  Future<void> close() async {
    // 等待所有保存任务完成
    await _waitForSaveTasks();
  }
}

/// 磁盘存储提供者
final diskStorageProvider = Provider<StorageInterface>((ref) {
  return DiskStorage();
}); 