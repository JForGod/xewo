/// 列表扩展
extension ListExtensions<T> on List<T> {
  /// 获取指定索引的元素，如果索引越界则返回null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) {
      return null;
    }
    return this[index];
  }
  
  /// 获取指定索引的元素，如果索引越界则返回默认值
  T getOrDefault(int index, T defaultValue) {
    if (index < 0 || index >= length) {
      return defaultValue;
    }
    return this[index];
  }
  
  /// 对列表进行分页
  List<List<T>> paginate(int pageSize) {
    if (isEmpty) {
      return [];
    }
    
    final pages = <List<T>>[];
    for (var i = 0; i < length; i += pageSize) {
      final end = (i + pageSize < length) ? i + pageSize : length;
      pages.add(sublist(i, end));
    }
    
    return pages;
  }
  
  /// 获取列表的第一个元素，如果列表为空则返回null
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
  
  /// 获取列表的最后一个元素，如果列表为空则返回null
  T? get lastOrNull {
    if (isEmpty) {
      return null;
    }
    return last;
  }
  
  /// 获取满足条件的第一个元素，如果没有满足条件的元素则返回null
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
  
  /// 获取满足条件的最后一个元素，如果没有满足条件的元素则返回null
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) {
        return this[i];
      }
    }
    return null;
  }
  
  /// 列表是否包含满足条件的元素
  bool containsWhere(bool Function(T) test) {
    return indexWhere(test) != -1;
  }
  
  /// 统计满足条件的元素个数
  int countWhere(bool Function(T) test) {
    var count = 0;
    for (final element in this) {
      if (test(element)) {
        count++;
      }
    }
    return count;
  }
  
  /// 列表分组
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final result = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      if (!result.containsKey(key)) {
        result[key] = [];
      }
      result[key]!.add(element);
    }
    return result;
  }
  
  /// 列表转换为Map
  Map<K, V> toMap<K, V>(K Function(T) keyFunction, V Function(T) valueFunction) {
    final result = <K, V>{};
    for (final element in this) {
      result[keyFunction(element)] = valueFunction(element);
    }
    return result;
  }
  
  /// 随机打乱列表
  List<T> shuffle() {
    final list = List<T>.from(this);
    list.shuffle();
    return list;
  }
  
  /// 移除重复元素
  List<T> distinct() {
    final result = <T>[];
    for (final element in this) {
      if (!result.contains(element)) {
        result.add(element);
      }
    }
    return result;
  }
  
  /// 移除满足条件的重复元素
  List<T> distinctBy<K>(K Function(T) keyFunction) {
    final result = <T>[];
    final keys = <K>{};
    for (final element in this) {
      final key = keyFunction(element);
      if (!keys.contains(key)) {
        keys.add(key);
        result.add(element);
      }
    }
    return result;
  }
  
  /// 检查所有元素是否满足条件
  bool all(bool Function(T) test) {
    for (final element in this) {
      if (!test(element)) {
        return false;
      }
    }
    return true;
  }
  
  /// 检查是否存在元素满足条件
  bool any(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) {
        return true;
      }
    }
    return false;
  }
  
  /// 检查是否所有元素都不满足条件
  bool none(bool Function(T) test) {
    return !any(test);
  }
  
  /// 获取满足条件的元素列表
  List<T> whereNot(bool Function(T) test) {
    return where((element) => !test(element)).toList();
  }
  
  /// 将两个列表合并
  List<T> merge(List<T> other) {
    return [...this, ...other];
  }
  
  /// 获取两个列表的交集
  List<T> intersect(List<T> other) {
    return where((element) => other.contains(element)).toList();
  }
  
  /// 获取当前列表中不在other列表中的元素
  List<T> except(List<T> other) {
    return where((element) => !other.contains(element)).toList();
  }
  
  /// 分割列表为指定数量的子列表
  List<List<T>> chunked(int size) {
    return paginate(size);
  }
  
  /// 获取列表的平均值（仅适用于数字列表）
  double average() {
    if (isEmpty) {
      return 0;
    }
    
    if (T == int || T == double) {
      final sum = fold<num>(0, (prev, element) => prev + (element as num));
      return sum / length;
    }
    
    throw Exception('average() is only applicable to number lists');
  }
  
  /// 获取列表的总和（仅适用于数字列表）
  num sum() {
    if (isEmpty) {
      return 0;
    }
    
    if (T == int || T == double) {
      return fold<num>(0, (prev, element) => prev + (element as num));
    }
    
    throw Exception('sum() is only applicable to number lists');
  }
}

/// Map扩展
extension MapExtensions<K, V> on Map<K, V> {
  /// 获取指定键的值，如果键不存在则返回null
  V? getOrNull(K key) {
    return this[key];
  }
  
  /// 获取指定键的值，如果键不存在则返回默认值
  V getOrDefault(K key, V defaultValue) {
    return this[key] ?? defaultValue;
  }
  
  /// 同时获取多个键的值
  Map<K, V> getMany(Iterable<K> keys) {
    final result = <K, V>{};
    for (final key in keys) {
      if (containsKey(key)) {
        result[key] = this[key] as V;
      }
    }
    return result;
  }
  
  /// 移除多个键
  Map<K, V> removeMany(Iterable<K> keys) {
    final result = Map<K, V>.from(this);
    for (final key in keys) {
      result.remove(key);
    }
    return result;
  }
  
  /// 仅保留指定键
  Map<K, V> only(Iterable<K> keys) {
    final result = <K, V>{};
    for (final key in keys) {
      if (containsKey(key)) {
        result[key] = this[key] as V;
      }
    }
    return result;
  }
  
  /// 转换键
  Map<NK, V> mapKeys<NK>(NK Function(K key, V value) transform) {
    final result = <NK, V>{};
    forEach((key, value) {
      result[transform(key, value)] = value;
    });
    return result;
  }
  
  /// 转换值
  Map<K, NV> mapValues<NV>(NV Function(K key, V value) transform) {
    final result = <K, NV>{};
    forEach((key, value) {
      result[key] = transform(key, value);
    });
    return result;
  }
  
  /// 扁平化Map
  Map<K, V> flatten() {
    final result = <K, V>{};
    
    void process(K? prefix, Map<dynamic, dynamic> map) {
      map.forEach((key, value) {
        final newKey = prefix == null ? key as K : '$prefix.$key' as K;
        
        if (value is Map) {
          process(newKey, value);
        } else {
          result[newKey] = value as V;
        }
      });
    }
    
    process(null, this);
    return result;
  }
  
  /// 过滤满足条件的元素
  Map<K, V> filterEntries(bool Function(K key, V value) test) {
    final result = <K, V>{};
    forEach((key, value) {
      if (test(key, value)) {
        result[key] = value;
      }
    });
    return result;
  }
  
  /// 过滤满足条件的键
  Map<K, V> filterKeys(bool Function(K key) test) {
    final result = <K, V>{};
    forEach((key, value) {
      if (test(key)) {
        result[key] = value;
      }
    });
    return result;
  }
  
  /// 过滤满足条件的值
  Map<K, V> filterValues(bool Function(V value) test) {
    final result = <K, V>{};
    forEach((key, value) {
      if (test(value)) {
        result[key] = value;
      }
    });
    return result;
  }
  
  /// 合并两个Map
  Map<K, V> merge(Map<K, V> other) {
    final result = Map<K, V>.from(this);
    other.forEach((key, value) {
      result[key] = value;
    });
    return result;
  }
}
