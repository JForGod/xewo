import 'dart:async';
import 'dart:math' as math;
import 'dart:collection';

import 'package:xewo/src/core/ai_engine/learning/learning_engine.dart';

/// 无监督学习策略接口
abstract class UnsupervisedLearningStrategy {
  /// 初始化策略
  Future<void> initialize();
  
  /// 训练模型
  Future<Map<String, dynamic>> train(List<Map<String, dynamic>> trainingData);
  
  /// 转换数据
  Future<dynamic> transform(Map<String, dynamic> input);
  
  /// 评估模型
  Future<Map<String, dynamic>> evaluate(List<Map<String, dynamic>> testData);
  
  /// 保存模型
  Future<void> saveModel(String path);
  
  /// 加载模型
  Future<void> loadModel(String path);
}

/// K均值聚类无监督学习策略
class KMeansClusteringStrategy implements UnsupervisedLearningStrategy {
  /// 聚类数量
  final int _k;
  
  /// 最大迭代次数
  final int _maxIterations;
  
  /// 收敛阈值
  final double _convergenceThreshold;
  
  /// 初始化方法
  final String _initMethod;
  
  /// 聚类中心
  List<List<double>> _centroids = [];
  
  /// 随机数生成器
  final math.Random _random = math.Random();
  
  /// 创建K均值聚类策略
  KMeansClusteringStrategy({
    required int k,
    int maxIterations = 100,
    double convergenceThreshold = 1e-4,
    String initMethod = 'random',
  }) : 
    _k = k,
    _maxIterations = maxIterations,
    _convergenceThreshold = convergenceThreshold,
    _initMethod = initMethod;
  
  @override
  Future<void> initialize() async {
    // 初始化聚类中心
    _centroids = [];
  }
  
  @override
  Future<Map<String, dynamic>> train(List<Map<String, dynamic>> trainingData) async {
    if (trainingData.isEmpty) {
      return {'error': '训练数据为空'};
    }
    
    // 提取特征
    final features = _extractFeatures(trainingData);
    if (features.isEmpty) {
      return {'error': '无法提取特征'};
    }
    
    // 特征维度
    final featureDimension = features.first.length;
    
    // 初始化聚类中心
    _initializeCentroids(features, featureDimension);
    
    // K均值聚类迭代
    int iteration = 0;
    double prevInertia = double.infinity;
    
    for (iteration = 0; iteration < _maxIterations; iteration++) {
      // 分配样本到最近的聚类中心
      final clusters = _assignToClusters(features);
      
      // 更新聚类中心
      final newCentroids = _updateCentroids(features, clusters, featureDimension);
      
      // 计算惯性（样本到其聚类中心的距离平方和）
      final inertia = _calculateInertia(features, clusters);
      
      // 检查收敛
      if ((prevInertia - inertia).abs() < _convergenceThreshold) {
        break;
      }
      prevInertia = inertia;
      
      // 更新聚类中心
      _centroids = newCentroids;
    }
    
    // 计算最终聚类分配
    final finalClusters = _assignToClusters(features);
    
    // 计算聚类评估指标
    final silhouetteScore = _calculateSilhouetteScore(features, finalClusters);
    
    return {
      'iterations': iteration + 1,
      'inertia': _calculateInertia(features, finalClusters),
      'silhouette_score': silhouetteScore,
      'cluster_sizes': _calculateClusterSizes(finalClusters),
    };
  }
  
  @override
  Future<dynamic> transform(Map<String, dynamic> input) async {
    final features = _extractInputFeatures(input);
    
    // 找到最近的聚类中心
    int nearestCluster = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < _centroids.length; i++) {
      final distance = _calculateDistance(features, _centroids[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestCluster = i;
      }
    }
    
    return {
      'cluster': nearestCluster,
      'distance': minDistance,
    };
  }
  
  @override
  Future<Map<String, dynamic>> evaluate(List<Map<String, dynamic>> testData) async {
    if (testData.isEmpty) {
      return {'error': '测试数据为空'};
    }
    
    // 提取特征
    final features = _extractFeatures(testData);
    if (features.isEmpty) {
      return {'error': '无法提取特征'};
    }
    
    // 分配样本到最近的聚类中心
    final clusters = _assignToClusters(features);
    
    // 计算评估指标
    final inertia = _calculateInertia(features, clusters);
    final silhouetteScore = _calculateSilhouetteScore(features, clusters);
    final clusterSizes = _calculateClusterSizes(clusters);
    
    return {
      'inertia': inertia,
      'silhouette_score': silhouetteScore,
      'cluster_sizes': clusterSizes,
    };
  }
  
  @override
  Future<void> saveModel(String path) async {
    // 在实际应用中，这里应该将聚类中心保存到文件
    print('保存K均值聚类模型到: $path');
  }
  
  @override
  Future<void> loadModel(String path) async {
    // 在实际应用中，这里应该从文件加载聚类中心
    print('从 $path 加载K均值聚类模型');
  }
  
  /// 提取特征矩阵
  List<List<double>> _extractFeatures(List<Map<String, dynamic>> data) {
    final features = <List<double>>[];
    
    for (final item in data) {
      if (item.containsKey('features')) {
        final featureList = item['features'] as List<dynamic>;
        features.add(featureList.map((e) => e as double).toList());
      }
    }
    
    return features;
  }
  
  /// 提取输入特征
  List<double> _extractInputFeatures(Map<String, dynamic> input) {
    if (input.containsKey('features')) {
      final featureList = input['features'] as List<dynamic>;
      return featureList.map((e) => e as double).toList();
    }
    
    throw ArgumentError('输入数据缺少特征字段');
  }
  
  /// 初始化聚类中心
  void _initializeCentroids(List<List<double>> features, int featureDimension) {
    _centroids = [];
    
    if (_initMethod == 'random') {
      // 随机选择K个样本作为初始聚类中心
      final indices = List.generate(features.length, (i) => i);
      indices.shuffle(_random);
      
      for (int i = 0; i < _k && i < indices.length; i++) {
        _centroids.add(List.from(features[indices[i]]));
      }
    } else if (_initMethod == 'kmeans++') {
      // K-means++初始化
      // 随机选择第一个聚类中心
      final firstIndex = _random.nextInt(features.length);
      _centroids.add(List.from(features[firstIndex]));
      
      // 选择剩余的聚类中心
      for (int i = 1; i < _k; i++) {
        // 计算每个样本到最近聚类中心的距离
        final distances = <double>[];
        double totalDistance = 0.0;
        
        for (final feature in features) {
          double minDistance = double.infinity;
          for (final centroid in _centroids) {
            final distance = _calculateDistance(feature, centroid);
            minDistance = math.min(minDistance, distance);
          }
          distances.add(minDistance * minDistance);
          totalDistance += minDistance * minDistance;
        }
        
        // 按距离的平方加权随机选择下一个聚类中心
        double r = _random.nextDouble() * totalDistance;
        int nextCentroidIndex = 0;
        double sum = 0.0;
        
        for (int j = 0; j < distances.length; j++) {
          sum += distances[j];
          if (sum >= r) {
            nextCentroidIndex = j;
            break;
          }
        }
        
        _centroids.add(List.from(features[nextCentroidIndex]));
      }
    } else {
      // 默认随机初始化
      for (int i = 0; i < _k; i++) {
        final centroid = List.generate(featureDimension, (_) => _random.nextDouble() * 10.0 - 5.0);
        _centroids.add(centroid);
      }
    }
  }
  
  /// 计算两个向量之间的欧几里得距离
  double _calculateDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('向量维度不匹配');
    }
    
    double sumSquared = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sumSquared += diff * diff;
    }
    
    return math.sqrt(sumSquared);
  }
  
  /// 将样本分配到最近的聚类中心
  List<int> _assignToClusters(List<List<double>> features) {
    final clusters = List.filled(features.length, 0);
    
    for (int i = 0; i < features.length; i++) {
      double minDistance = double.infinity;
      int nearestCluster = 0;
      
      for (int j = 0; j < _centroids.length; j++) {
        final distance = _calculateDistance(features[i], _centroids[j]);
        if (distance < minDistance) {
          minDistance = distance;
          nearestCluster = j;
        }
      }
      
      clusters[i] = nearestCluster;
    }
    
    return clusters;
  }
  
  /// 更新聚类中心
  List<List<double>> _updateCentroids(
    List<List<double>> features,
    List<int> clusters,
    int featureDimension,
  ) {
    final newCentroids = List.generate(
      _k,
      (_) => List.filled(featureDimension, 0.0),
    );
    final counts = List.filled(_k, 0);
    
    // 累加每个聚类中的样本
    for (int i = 0; i < features.length; i++) {
      final cluster = clusters[i];
      counts[cluster]++;
      
      for (int j = 0; j < featureDimension; j++) {
        newCentroids[cluster][j] += features[i][j];
      }
    }
    
    // 计算平均值
    for (int i = 0; i < _k; i++) {
      if (counts[i] > 0) {
        for (int j = 0; j < featureDimension; j++) {
          newCentroids[i][j] /= counts[i];
        }
      } else {
        // 如果聚类为空，随机重新初始化
        for (int j = 0; j < featureDimension; j++) {
          newCentroids[i][j] = _random.nextDouble() * 10.0 - 5.0;
        }
      }
    }
    
    return newCentroids;
  }
  
  /// 计算惯性（样本到其聚类中心的距离平方和）
  double _calculateInertia(List<List<double>> features, List<int> clusters) {
    double inertia = 0.0;
    
    for (int i = 0; i < features.length; i++) {
      final cluster = clusters[i];
      final distance = _calculateDistance(features[i], _centroids[cluster]);
      inertia += distance * distance;
    }
    
    return inertia;
  }
  
  /// 计算轮廓系数
  double _calculateSilhouetteScore(List<List<double>> features, List<int> clusters) {
    if (features.isEmpty) return 0.0;
    
    double totalSilhouette = 0.0;
    
    for (int i = 0; i < features.length; i++) {
      final a = _calculateAverageIntraClusterDistance(i, features, clusters);
      final b = _calculateAverageNearestClusterDistance(i, features, clusters);
      
      if (a == 0.0 && b == 0.0) {
        totalSilhouette += 0.0;
      } else {
        totalSilhouette += (b - a) / math.max(a, b);
      }
    }
    
    return totalSilhouette / features.length;
  }
  
  /// 计算样本到同一聚类中其他样本的平均距离
  double _calculateAverageIntraClusterDistance(
    int sampleIndex,
    List<List<double>> features,
    List<int> clusters,
  ) {
    final cluster = clusters[sampleIndex];
    double totalDistance = 0.0;
    int count = 0;
    
    for (int i = 0; i < features.length; i++) {
      if (i != sampleIndex && clusters[i] == cluster) {
        totalDistance += _calculateDistance(features[sampleIndex], features[i]);
        count++;
      }
    }
    
    return count > 0 ? totalDistance / count : 0.0;
  }
  
  /// 计算样本到最近的其他聚类中样本的平均距离
  double _calculateAverageNearestClusterDistance(
    int sampleIndex,
    List<List<double>> features,
    List<int> clusters,
  ) {
    final cluster = clusters[sampleIndex];
    final clusterDistances = <int, double>{};
    final clusterCounts = <int, int>{};
    
    for (int i = 0; i < features.length; i++) {
      if (clusters[i] != cluster) {
        final otherCluster = clusters[i];
        final distance = _calculateDistance(features[sampleIndex], features[i]);
        
        clusterDistances[otherCluster] = (clusterDistances[otherCluster] ?? 0.0) + distance;
        clusterCounts[otherCluster] = (clusterCounts[otherCluster] ?? 0) + 1;
      }
    }
    
    // 计算每个聚类的平均距离
    final averageDistances = <int, double>{};
    clusterDistances.forEach((cluster, totalDistance) {
      final count = clusterCounts[cluster] ?? 0;
      if (count > 0) {
        averageDistances[cluster] = totalDistance / count;
      }
    });
    
    // 返回最近聚类的平均距离
    return averageDistances.isEmpty ? 0.0 : averageDistances.values.reduce(math.min);
  }
  
  /// 计算每个聚类的大小
  Map<int, int> _calculateClusterSizes(List<int> clusters) {
    final sizes = <int, int>{};
    
    for (final cluster in clusters) {
      sizes[cluster] = (sizes[cluster] ?? 0) + 1;
    }
    
    return sizes;
  }
}

/// 主成分分析无监督学习策略
class PCAStrategy implements UnsupervisedLearningStrategy {
  /// 目标维度
  final int _nComponents;
  
  /// 是否标准化
  final bool _standardize;
  
  /// 投影矩阵
  List<List<double>> _components = [];
  
  /// 特征均值
  List<double> _mean = [];
  
  /// 特征标准差
  List<double> _std = [];
  
  /// 解释方差比
  List<double> _explainedVarianceRatio = [];
  
  /// 随机数生成器
  final math.Random _random = math.Random();
  
  /// 创建主成分分析策略
  PCAStrategy({
    required int nComponents,
    bool standardize = true,
  }) : 
    _nComponents = nComponents,
    _standardize = standardize;
  
  @override
  Future<void> initialize() async {
    // 初始化PCA参数
    _components = [];
    _mean = [];
    _std = [];
    _explainedVarianceRatio = [];
  }
  
  @override
  Future<Map<String, dynamic>> train(List<Map<String, dynamic>> trainingData) async {
    if (trainingData.isEmpty) {
      return {'error': '训练数据为空'};
    }
    
    // 提取特征
    final features = _extractFeatures(trainingData);
    if (features.isEmpty) {
      return {'error': '无法提取特征'};
    }
    
    // 特征维度
    final featureDimension = features.first.length;
    if (_nComponents > featureDimension) {
      return {'error': '目标维度不能大于特征维度'};
    }
    
    // 在实际应用中，这里应该实现PCA的训练算法
    // 简化版本，仅打印训练信息
    print('训练PCA模型，样本数量: ${features.length}，特征维度: $featureDimension，目标维度: $_nComponents');
    
    // 模拟PCA结果
    _mean = List.generate(featureDimension, (_) => 0.0);
    _std = List.generate(featureDimension, (_) => 1.0);
    _components = List.generate(
      _nComponents,
      (_) => List.generate(featureDimension, (_) => _random.nextDouble() * 2.0 - 1.0),
    );
    _explainedVarianceRatio = List.generate(
      _nComponents,
      (i) => 1.0 / (_nComponents - i),
    );
    
    // 归一化解释方差比
    double sum = _explainedVarianceRatio.fold(0.0, (a, b) => a + b);
    for (int i = 0; i < _nComponents; i++) {
      _explainedVarianceRatio[i] /= sum;
    }
    
    return {
      'n_components': _nComponents,
      'explained_variance_ratio': _explainedVarianceRatio,
      'total_explained_variance': _explainedVarianceRatio.fold(0.0, (a, b) => a + b),
    };
  }
  
  @override
  Future<dynamic> transform(Map<String, dynamic> input) async {
    final features = _extractInputFeatures(input);
    
    // 标准化
    final standardizedFeatures = _standardize ? _standardizeFeatures(features) : features;
    
    // 投影到主成分空间
    final transformed = List.filled(_nComponents, 0.0);
    for (int i = 0; i < _nComponents; i++) {
      for (int j = 0; j < features.length; j++) {
        transformed[i] += standardizedFeatures[j] * _components[i][j];
      }
    }
    
    return {
      'transformed': transformed,
    };
  }
  
  @override
  Future<Map<String, dynamic>> evaluate(List<Map<String, dynamic>> testData) async {
    if (testData.isEmpty) {
      return {'error': '测试数据为空'};
    }
    
    // 提取特征
    final features = _extractFeatures(testData);
    if (features.isEmpty) {
      return {'error': '无法提取特征'};
    }
    
    // 在实际应用中，这里应该评估PCA模型
    // 简化版本，返回解释方差比
    return {
      'explained_variance_ratio': _explainedVarianceRatio,
      'total_explained_variance': _explainedVarianceRatio.fold(0.0, (a, b) => a + b),
    };
  }
  
  @override
  Future<void> saveModel(String path) async {
    // 在实际应用中，这里应该将PCA模型参数保存到文件
    print('保存PCA模型到: $path');
  }
  
  @override
  Future<void> loadModel(String path) async {
    // 在实际应用中，这里应该从文件加载PCA模型参数
    print('从 $path 加载PCA模型');
  }
  
  /// 提取特征矩阵
  List<List<double>> _extractFeatures(List<Map<String, dynamic>> data) {
    final features = <List<double>>[];
    
    for (final item in data) {
      if (item.containsKey('features')) {
        final featureList = item['features'] as List<dynamic>;
        features.add(featureList.map((e) => e as double).toList());
      }
    }
    
    return features;
  }
  
  /// 提取输入特征
  List<double> _extractInputFeatures(Map<String, dynamic> input) {
    if (input.containsKey('features')) {
      final featureList = input['features'] as List<dynamic>;
      return featureList.map((e) => e as double).toList();
    }
    
    throw ArgumentError('输入数据缺少特征字段');
  }
  
  /// 标准化特征
  List<double> _standardizeFeatures(List<double> features) {
    if (features.length != _mean.length) {
      throw ArgumentError('特征维度不匹配');
    }
    
    final standardized = List<double>.filled(features.length, 0.0);
    for (int i = 0; i < features.length; i++) {
      standardized[i] = _std[i] > 0.0 ? (features[i] - _mean[i]) / _std[i] : 0.0;
    }
    
    return standardized;
  }
}

/// 无监督学习策略工厂
class UnsupervisedLearningStrategyFactory {
  /// 创建无监督学习策略
  static UnsupervisedLearningStrategy createStrategy(
    String type, {
    Map<String, dynamic> config = const {},
  }) {
    switch (type.toLowerCase()) {
      case 'kmeans':
        return KMeansClusteringStrategy(
          k: config['k'] ?? 3,
          maxIterations: config['maxIterations'] ?? 100,
          convergenceThreshold: config['convergenceThreshold'] ?? 1e-4,
          initMethod: config['initMethod'] ?? 'random',
        );
      case 'pca':
        return PCAStrategy(
          nComponents: config['nComponents'] ?? 2,
          standardize: config['standardize'] ?? true,
        );
      default:
        throw ArgumentError('不支持的无监督学习策略类型: $type');
    }
  }
} 