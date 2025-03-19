import '../knowledge_base.dart';

/// 存储接口
abstract class StorageInterface {
  /// 初始化存储
  Future<void> initialize();
  
  /// 存储知识条目
  /// 
  /// 返回知识条目的ID
  Future<String> store(Knowledge knowledge);
  
  /// 按ID检索知识条目
  Future<Knowledge?> retrieve(String id);
  
  /// 按标签检索知识条目
  Future<List<Knowledge>> retrieveByTags(List<String> tags, {int limit = 10});
  
  /// 搜索知识条目
  /// 
  /// [query] 搜索查询文本
  /// [queryEmbedding] 搜索查询的嵌入向量
  /// [options] 查询选项
  Future<List<QueryResult>> search(
    String query, 
    List<double>? queryEmbedding, {
    QueryOptions options = const QueryOptions(),
  });
  
  /// 更新知识条目
  Future<void> update(Knowledge knowledge);
  
  /// 删除知识条目
  Future<void> delete(String id);
  
  /// 清空存储
  Future<void> clear();
  
  /// 获取存储的知识条目数量
  Future<int> count();
  
  /// 获取所有标签
  Future<List<String>> getAllTags();
  
  /// 获取存储统计信息
  Future<Map<String, dynamic>> getStats();
  
  /// 生成文本的嵌入向量
  Future<List<double>> generateEmbedding(String text);
} 