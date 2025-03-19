import 'dart:async';

/// 安全级别
enum SecurityLevel {
  /// 低安全级别
  low,
  
  /// 中安全级别
  medium,
  
  /// 高安全级别
  high,
  
  /// 最高安全级别
  maximum,
}

/// 权限类型
enum PermissionType {
  /// 文件读取
  fileRead,
  
  /// 文件写入
  fileWrite,
  
  /// 网络访问
  networkAccess,
  
  /// 系统调用
  systemCall,
  
  /// 进程管理
  processManagement,
  
  /// 内存访问
  memoryAccess,
  
  /// 设备访问
  deviceAccess,
}

/// 网络规则类型
enum NetworkRuleType {
  /// 允许所有
  allowAll,
  
  /// 仅允许指定域名
  allowDomains,
  
  /// 仅允许指定IP
  allowIPs,
  
  /// 仅允许指定端口
  allowPorts,
  
  /// 禁止所有
  denyAll,
}

/// 安全策略
class SecurityPolicy {
  /// 安全级别
  final SecurityLevel level;
  
  /// 策略名称
  final String name;
  
  /// 策略描述
  final String description;
  
  /// 权限映射
  final Map<PermissionType, bool> permissions;
  
  /// 网络规则
  final NetworkRuleType networkRule;
  
  /// 允许的域名列表
  final List<String> allowedDomains;
  
  /// 允许的IP列表
  final List<String> allowedIPs;
  
  /// 允许的端口列表
  final List<int> allowedPorts;
  
  /// 最大文件大小（字节）
  final int maxFileSize;
  
  /// 最大内存使用量（字节）
  final int maxMemoryUsage;
  
  /// 最大CPU使用率（0-100）
  final double maxCpuUsage;
  
  /// 最大网络带宽（字节/秒）
  final int maxNetworkBandwidth;
  
  /// 超时时间（毫秒）
  final int timeoutMs;
  
  /// 是否启用日志记录
  final bool enableLogging;
  
  /// 是否启用审计
  final bool enableAudit;
  
  /// 自定义规则
  final Map<String, dynamic> customRules;
  
  /// 构造函数
  SecurityPolicy({
    this.level = SecurityLevel.medium,
    this.name = 'default',
    this.description = '默认安全策略',
    Map<PermissionType, bool>? permissions,
    this.networkRule = NetworkRuleType.allowDomains,
    this.allowedDomains = const [],
    this.allowedIPs = const [],
    this.allowedPorts = const [],
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxMemoryUsage = 100 * 1024 * 1024, // 100MB
    this.maxCpuUsage = 50.0,
    this.maxNetworkBandwidth = 1024 * 1024, // 1MB/s
    this.timeoutMs = 30000,
    this.enableLogging = true,
    this.enableAudit = true,
    this.customRules = const {},
  }) : permissions = permissions ?? _getDefaultPermissions(level);
  
  /// 从Map创建安全策略
  factory SecurityPolicy.fromMap(Map<String, dynamic> map) {
    return SecurityPolicy(
      level: SecurityLevel.values.byName(map['level'] ?? 'medium'),
      name: map['name'] ?? 'default',
      description: map['description'] ?? '默认安全策略',
      permissions: (map['permissions'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(PermissionType.values.byName(key), value as bool),
      ),
      networkRule: NetworkRuleType.values.byName(map['networkRule'] ?? 'allowDomains'),
      allowedDomains: List<String>.from(map['allowedDomains'] ?? []),
      allowedIPs: List<String>.from(map['allowedIPs'] ?? []),
      allowedPorts: List<int>.from(map['allowedPorts'] ?? []),
      maxFileSize: map['maxFileSize'] ?? 10 * 1024 * 1024,
      maxMemoryUsage: map['maxMemoryUsage'] ?? 100 * 1024 * 1024,
      maxCpuUsage: (map['maxCpuUsage'] ?? 50.0) as double,
      maxNetworkBandwidth: map['maxNetworkBandwidth'] ?? 1024 * 1024,
      timeoutMs: map['timeoutMs'] ?? 30000,
      enableLogging: map['enableLogging'] ?? true,
      enableAudit: map['enableAudit'] ?? true,
      customRules: Map<String, dynamic>.from(map['customRules'] ?? {}),
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'name': name,
      'description': description,
      'permissions': permissions.map((key, value) => MapEntry(key.name, value)),
      'networkRule': networkRule.name,
      'allowedDomains': allowedDomains,
      'allowedIPs': allowedIPs,
      'allowedPorts': allowedPorts,
      'maxFileSize': maxFileSize,
      'maxMemoryUsage': maxMemoryUsage,
      'maxCpuUsage': maxCpuUsage,
      'maxNetworkBandwidth': maxNetworkBandwidth,
      'timeoutMs': timeoutMs,
      'enableLogging': enableLogging,
      'enableAudit': enableAudit,
      'customRules': customRules,
    };
  }
  
  /// 复制并修改
  SecurityPolicy copyWith({
    SecurityLevel? level,
    String? name,
    String? description,
    Map<PermissionType, bool>? permissions,
    NetworkRuleType? networkRule,
    List<String>? allowedDomains,
    List<String>? allowedIPs,
    List<int>? allowedPorts,
    int? maxFileSize,
    int? maxMemoryUsage,
    double? maxCpuUsage,
    int? maxNetworkBandwidth,
    int? timeoutMs,
    bool? enableLogging,
    bool? enableAudit,
    Map<String, dynamic>? customRules,
  }) {
    return SecurityPolicy(
      level: level ?? this.level,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? Map.from(this.permissions),
      networkRule: networkRule ?? this.networkRule,
      allowedDomains: allowedDomains ?? List.from(this.allowedDomains),
      allowedIPs: allowedIPs ?? List.from(this.allowedIPs),
      allowedPorts: allowedPorts ?? List.from(this.allowedPorts),
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxMemoryUsage: maxMemoryUsage ?? this.maxMemoryUsage,
      maxCpuUsage: maxCpuUsage ?? this.maxCpuUsage,
      maxNetworkBandwidth: maxNetworkBandwidth ?? this.maxNetworkBandwidth,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      enableLogging: enableLogging ?? this.enableLogging,
      enableAudit: enableAudit ?? this.enableAudit,
      customRules: customRules ?? Map.from(this.customRules),
    );
  }
  
  /// 检查权限
  bool hasPermission(PermissionType permission) {
    return permissions[permission] ?? false;
  }
  
  /// 检查网络访问
  bool canAccessNetwork(String target) {
    switch (networkRule) {
      case NetworkRuleType.allowAll:
        return true;
      
      case NetworkRuleType.allowDomains:
        return allowedDomains.any((domain) => 
            target.toLowerCase().endsWith(domain.toLowerCase()));
      
      case NetworkRuleType.allowIPs:
        return allowedIPs.contains(target);
      
      case NetworkRuleType.allowPorts:
        try {
          final port = int.parse(target.split(':').last);
          return allowedPorts.contains(port);
        } catch (_) {
          return false;
        }
      
      case NetworkRuleType.denyAll:
        return false;
    }
  }
  
  /// 检查文件大小
  bool checkFileSize(int size) {
    return size <= maxFileSize;
  }
  
  /// 检查内存使用量
  bool checkMemoryUsage(int usage) {
    return usage <= maxMemoryUsage;
  }
  
  /// 检查CPU使用率
  bool checkCpuUsage(double usage) {
    return usage <= maxCpuUsage;
  }
  
  /// 检查网络带宽
  bool checkNetworkBandwidth(int bandwidth) {
    return bandwidth <= maxNetworkBandwidth;
  }
  
  /// 获取默认权限
  static Map<PermissionType, bool> _getDefaultPermissions(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.low:
        return {
          PermissionType.fileRead: true,
          PermissionType.fileWrite: true,
          PermissionType.networkAccess: true,
          PermissionType.systemCall: true,
          PermissionType.processManagement: true,
          PermissionType.memoryAccess: true,
          PermissionType.deviceAccess: true,
        };
      
      case SecurityLevel.medium:
        return {
          PermissionType.fileRead: true,
          PermissionType.fileWrite: false,
          PermissionType.networkAccess: true,
          PermissionType.systemCall: false,
          PermissionType.processManagement: false,
          PermissionType.memoryAccess: true,
          PermissionType.deviceAccess: false,
        };
      
      case SecurityLevel.high:
        return {
          PermissionType.fileRead: true,
          PermissionType.fileWrite: false,
          PermissionType.networkAccess: false,
          PermissionType.systemCall: false,
          PermissionType.processManagement: false,
          PermissionType.memoryAccess: false,
          PermissionType.deviceAccess: false,
        };
      
      case SecurityLevel.maximum:
        return {
          PermissionType.fileRead: false,
          PermissionType.fileWrite: false,
          PermissionType.networkAccess: false,
          PermissionType.systemCall: false,
          PermissionType.processManagement: false,
          PermissionType.memoryAccess: false,
          PermissionType.deviceAccess: false,
        };
    }
  }
  
  /// 获取预定义策略
  static SecurityPolicy getPredefinedPolicy(String name) {
    switch (name.toLowerCase()) {
      case 'readonly':
        return SecurityPolicy(
          level: SecurityLevel.high,
          name: 'readonly',
          description: '只读策略',
          permissions: {
            PermissionType.fileRead: true,
            PermissionType.fileWrite: false,
            PermissionType.networkAccess: false,
            PermissionType.systemCall: false,
            PermissionType.processManagement: false,
            PermissionType.memoryAccess: false,
            PermissionType.deviceAccess: false,
          },
          networkRule: NetworkRuleType.denyAll,
        );
      
      case 'network_only':
        return SecurityPolicy(
          level: SecurityLevel.medium,
          name: 'network_only',
          description: '仅网络访问策略',
          permissions: {
            PermissionType.fileRead: false,
            PermissionType.fileWrite: false,
            PermissionType.networkAccess: true,
            PermissionType.systemCall: false,
            PermissionType.processManagement: false,
            PermissionType.memoryAccess: false,
            PermissionType.deviceAccess: false,
          },
          networkRule: NetworkRuleType.allowDomains,
          allowedDomains: ['api.example.com'],
        );
      
      case 'development':
        return SecurityPolicy(
          level: SecurityLevel.low,
          name: 'development',
          description: '开发环境策略',
          permissions: {
            PermissionType.fileRead: true,
            PermissionType.fileWrite: true,
            PermissionType.networkAccess: true,
            PermissionType.systemCall: true,
            PermissionType.processManagement: true,
            PermissionType.memoryAccess: true,
            PermissionType.deviceAccess: true,
          },
          networkRule: NetworkRuleType.allowAll,
          maxFileSize: 100 * 1024 * 1024, // 100MB
          maxMemoryUsage: 1024 * 1024 * 1024, // 1GB
          maxCpuUsage: 90.0,
          maxNetworkBandwidth: 10 * 1024 * 1024, // 10MB/s
        );
      
      case 'production':
        return SecurityPolicy(
          level: SecurityLevel.high,
          name: 'production',
          description: '生产环境策略',
          permissions: {
            PermissionType.fileRead: true,
            PermissionType.fileWrite: false,
            PermissionType.networkAccess: true,
            PermissionType.systemCall: false,
            PermissionType.processManagement: false,
            PermissionType.memoryAccess: false,
            PermissionType.deviceAccess: false,
          },
          networkRule: NetworkRuleType.allowDomains,
          allowedDomains: ['api.production.com'],
          maxFileSize: 5 * 1024 * 1024, // 5MB
          maxMemoryUsage: 50 * 1024 * 1024, // 50MB
          maxCpuUsage: 30.0,
          maxNetworkBandwidth: 1024 * 1024, // 1MB/s
          enableAudit: true,
        );
      
      default:
        return SecurityPolicy();
    }
  }
  
  /// 验证策略配置
  bool validate() {
    // 检查基本参数
    if (name.isEmpty) return false;
    if (maxFileSize < 0) return false;
    if (maxMemoryUsage < 0) return false;
    if (maxCpuUsage < 0 || maxCpuUsage > 100) return false;
    if (maxNetworkBandwidth < 0) return false;
    if (timeoutMs < 0) return false;
    
    // 检查网络规则配置
    switch (networkRule) {
      case NetworkRuleType.allowDomains:
        if (allowedDomains.isEmpty) return false;
        break;
      
      case NetworkRuleType.allowIPs:
        if (allowedIPs.isEmpty) return false;
        break;
      
      case NetworkRuleType.allowPorts:
        if (allowedPorts.isEmpty) return false;
        break;
      
      default:
        break;
    }
    
    return true;
  }
  
  /// 合并策略
  SecurityPolicy merge(SecurityPolicy other) {
    // 选择更严格的安全级别
    final newLevel = level.index > other.level.index ? level : other.level;
    
    // 合并权限（与操作）
    final newPermissions = <PermissionType, bool>{};
    for (final permission in PermissionType.values) {
      newPermissions[permission] = 
          (permissions[permission] ?? false) && (other.permissions[permission] ?? false);
    }
    
    // 合并网络规则（选择更严格的规则）
    final newNetworkRule = networkRule.index > other.networkRule.index 
        ? networkRule 
        : other.networkRule;
    
    // 合并允许列表（取交集）
    final newAllowedDomains = allowedDomains.toSet()
        .intersection(other.allowedDomains.toSet())
        .toList();
    
    final newAllowedIPs = allowedIPs.toSet()
        .intersection(other.allowedIPs.toSet())
        .toList();
    
    final newAllowedPorts = allowedPorts.toSet()
        .intersection(other.allowedPorts.toSet())
        .toList();
    
    // 选择更小的限制值
    final newMaxFileSize = maxFileSize < other.maxFileSize 
        ? maxFileSize 
        : other.maxFileSize;
    
    final newMaxMemoryUsage = maxMemoryUsage < other.maxMemoryUsage 
        ? maxMemoryUsage 
        : other.maxMemoryUsage;
    
    final newMaxCpuUsage = maxCpuUsage < other.maxCpuUsage 
        ? maxCpuUsage 
        : other.maxCpuUsage;
    
    final newMaxNetworkBandwidth = maxNetworkBandwidth < other.maxNetworkBandwidth 
        ? maxNetworkBandwidth 
        : other.maxNetworkBandwidth;
    
    // 选择更小的超时时间
    final newTimeoutMs = timeoutMs < other.timeoutMs 
        ? timeoutMs 
        : other.timeoutMs;
    
    // 合并自定义规则
    final newCustomRules = <String, dynamic>{
      ...customRules,
      ...other.customRules,
    };
    
    return SecurityPolicy(
      level: newLevel,
      name: '${name}_merged_${other.name}',
      description: '合并策略: $name + ${other.name}',
      permissions: newPermissions,
      networkRule: newNetworkRule,
      allowedDomains: newAllowedDomains,
      allowedIPs: newAllowedIPs,
      allowedPorts: newAllowedPorts,
      maxFileSize: newMaxFileSize,
      maxMemoryUsage: newMaxMemoryUsage,
      maxCpuUsage: newMaxCpuUsage,
      maxNetworkBandwidth: newMaxNetworkBandwidth,
      timeoutMs: newTimeoutMs,
      enableLogging: enableLogging || other.enableLogging,
      enableAudit: enableAudit || other.enableAudit,
      customRules: newCustomRules,
    );
  }
} 