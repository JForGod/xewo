import '../context_awareness_service.dart';

/// Java语言解析器
class JavaParser {
  /// 解析Java类
  static List<ContextInfo> parseClasses(String code) {
    final classes = <ContextInfo>[];
    
    // 匹配类定义
    final classRegex = RegExp(
      r'(?:public|protected|private)?\s*(?:static|final|abstract)?\s*(?:class|interface|enum)\s+(\w+)(?:\s+extends\s+(\w+))?(?:\s+implements\s+([\w\s,]+))?\s*{',
      multiLine: true,
    );
    
    final matches = classRegex.allMatches(code);
    
    for (final match in matches) {
      final className = match.group(1)!;
      final extendsClass = match.group(2);
      final interfaces = match.group(3);
      
      // 确定类型（类、接口或枚举）
      String classType = 'class';
      if (code.substring(match.start, match.end).contains('interface')) {
        classType = 'interface';
      } else if (code.substring(match.start, match.end).contains('enum')) {
        classType = 'enum';
      }
      
      // 查找类的结束位置
      final classStart = match.start;
      int classEnd = _findClosingBrace(code, match.end);
      if (classEnd == -1) classEnd = code.length;
      
      // 计算行号和列号
      final lineInfo = _calculateLineAndColumn(code, classStart);
      
      // 解析类成员
      final classBody = code.substring(match.end, classEnd);
      final members = _parseClassMembers(classBody, classStart + match.end);
      
      classes.add(ContextInfo(
        id: 'java_class_${DateTime.now().millisecondsSinceEpoch}_$className',
        type: ContextType.class_,
        name: className,
        range: ContextRange(
          start: classStart,
          end: classEnd,
          line: lineInfo.line,
          column: lineInfo.column,
        ),
        metadata: {
          'type': classType,
          'extends': extendsClass,
          'implements': interfaces?.split(',').map((i) => i.trim()).toList() ?? [],
          'isPublic': code.substring(match.start, match.end).contains('public'),
          'isProtected': code.substring(match.start, match.end).contains('protected'),
          'isPrivate': code.substring(match.start, match.end).contains('private'),
          'isStatic': code.substring(match.start, match.end).contains('static'),
          'isFinal': code.substring(match.start, match.end).contains('final'),
          'isAbstract': code.substring(match.start, match.end).contains('abstract'),
          'language': 'java',
        },
        dependencies: _extractDependencies(extendsClass, interfaces),
        children: members,
        analyzedAt: DateTime.now(),
      ));
    }
    
    return classes;
  }

  /// 解析Java方法
  static List<ContextInfo> parseMethods(String code) {
    final methods = <ContextInfo>[];
    
    // 匹配方法定义
    final methodRegex = RegExp(
      r'(?:@\w+(?:\(.*?\))?\s*)*(?:public|protected|private)?\s*(?:static|final|abstract|synchronized)?\s*(?:<.*?>)?\s*(\w+(?:<.*?>)?)\s+(\w+)\s*\((.*?)\)(?:\s+throws\s+([\w\s,]+))?\s*(?:{|;)',
      multiLine: true,
    );
    
    final matches = methodRegex.allMatches(code);
    
    for (final match in matches) {
      // 排除类内部的方法
      if (_isInsideClass(code, match.start)) continue;
      
      final returnType = match.group(1);
      final methodName = match.group(2)!;
      final parameters = match.group(3);
      final exceptions = match.group(4);
      
      // 查找方法的结束位置
      final methodStart = match.start;
      int methodEnd;
      
      if (code.substring(match.end - 1, match.end) == '{') {
        methodEnd = _findClosingBrace(code, match.end);
      } else {
        // 抽象方法，查找分号
        methodEnd = match.end;
      }
      
      if (methodEnd == -1) methodEnd = code.length;
      
      // 计算行号和列号
      final lineInfo = _calculateLineAndColumn(code, methodStart);
      
      methods.add(ContextInfo(
        id: 'java_method_${DateTime.now().millisecondsSinceEpoch}_$methodName',
        type: ContextType.function,
        name: methodName,
        range: ContextRange(
          start: methodStart,
          end: methodEnd,
          line: lineInfo.line,
          column: lineInfo.column,
        ),
        metadata: {
          'returnType': returnType,
          'parameters': _parseParameters(parameters ?? ''),
          'exceptions': exceptions?.split(',').map((e) => e.trim()).toList() ?? [],
          'isPublic': code.substring(match.start, match.end).contains('public'),
          'isProtected': code.substring(match.start, match.end).contains('protected'),
          'isPrivate': code.substring(match.start, match.end).contains('private'),
          'isStatic': code.substring(match.start, match.end).contains('static'),
          'isFinal': code.substring(match.start, match.end).contains('final'),
          'isAbstract': code.substring(match.start, match.end).contains('abstract'),
          'isSynchronized': code.substring(match.start, match.end).contains('synchronized'),
          'language': 'java',
        },
        dependencies: _extractTypeDependencies(returnType, parameters, exceptions),
        children: [],
        analyzedAt: DateTime.now(),
      ));
    }
    
    return methods;
  }

  /// 解析Java变量
  static List<ContextInfo> parseVariables(String code) {
    final variables = <ContextInfo>[];
    
    // 匹配变量声明
    final variableRegex = RegExp(
      r'(?:public|protected|private)?\s*(?:static|final)?\s*(\w+(?:<.*?>)?)\s+(\w+)(?:\s*=\s*([^;]+))?\s*;',
      multiLine: true,
    );
    
    final matches = variableRegex.allMatches(code);
    
    for (final match in matches) {
      // 排除类内部的变量
      if (_isInsideClass(code, match.start) || _isInsideMethod(code, match.start)) continue;
      
      final type = match.group(1);
      final variableName = match.group(2)!;
      final initialValue = match.group(3);
      
      // 计算行号和列号
      final lineInfo = _calculateLineAndColumn(code, match.start);
      
      variables.add(ContextInfo(
        id: 'java_variable_${DateTime.now().millisecondsSinceEpoch}_$variableName',
        type: ContextType.variable,
        name: variableName,
        range: ContextRange(
          start: match.start,
          end: match.end,
          line: lineInfo.line,
          column: lineInfo.column,
        ),
        metadata: {
          'type': type,
          'initialValue': initialValue,
          'isPublic': code.substring(match.start, match.end).contains('public'),
          'isProtected': code.substring(match.start, match.end).contains('protected'),
          'isPrivate': code.substring(match.start, match.end).contains('private'),
          'isStatic': code.substring(match.start, match.end).contains('static'),
          'isFinal': code.substring(match.start, match.end).contains('final'),
          'language': 'java',
        },
        dependencies: _extractTypeDependencies(type, null, null),
        children: [],
        analyzedAt: DateTime.now(),
      ));
    }
    
    return variables;
  }

  /// 解析类成员
  static List<ContextInfo> _parseClassMembers(String classBody, int offset) {
    final members = <ContextInfo>[];
    
    // 解析类方法
    final methodRegex = RegExp(
      r'(?:@\w+(?:\(.*?\))?\s*)*(?:public|protected|private)?\s*(?:static|final|abstract|synchronized)?\s*(?:<.*?>)?\s*(\w+(?:<.*?>)?)\s+(\w+)\s*\((.*?)\)(?:\s+throws\s+([\w\s,]+))?\s*(?:{|;)',
      multiLine: true,
    );
    
    final methodMatches = methodRegex.allMatches(classBody);
    
    for (final match in methodMatches) {
      final returnType = match.group(1);
      final methodName = match.group(2)!;
      final parameters = match.group(3);
      final exceptions = match.group(4);
      
      // 查找方法的结束位置
      final methodStart = match.start + offset;
      int methodEnd;
      
      if (classBody.substring(match.end - 1, match.end) == '{') {
        methodEnd = _findClosingBrace(classBody, match.end) + offset;
      } else {
        // 抽象方法，查找分号
        methodEnd = match.end + offset;
      }
      
      if (methodEnd == -1) methodEnd = classBody.length + offset;
      
      // 计算行号和列号
      final lineInfo = _calculateLineAndColumn(classBody, match.start);
      
      members.add(ContextInfo(
        id: 'java_method_${DateTime.now().millisecondsSinceEpoch}_$methodName',
        type: ContextType.function,
        name: methodName,
        range: ContextRange(
          start: methodStart,
          end: methodEnd,
          line: lineInfo.line,
          column: lineInfo.column,
        ),
        metadata: {
          'returnType': returnType,
          'parameters': _parseParameters(parameters ?? ''),
          'exceptions': exceptions?.split(',').map((e) => e.trim()).toList() ?? [],
          'isPublic': classBody.substring(match.start, match.end).contains('public'),
          'isProtected': classBody.substring(match.start, match.end).contains('protected'),
          'isPrivate': classBody.substring(match.start, match.end).contains('private'),
          'isStatic': classBody.substring(match.start, match.end).contains('static'),
          'isFinal': classBody.substring(match.start, match.end).contains('final'),
          'isAbstract': classBody.substring(match.start, match.end).contains('abstract'),
          'isSynchronized': classBody.substring(match.start, match.end).contains('synchronized'),
          'language': 'java',
        },
        dependencies: _extractTypeDependencies(returnType, parameters, exceptions),
        children: [],
        analyzedAt: DateTime.now(),
      ));
    }
    
    // 解析类属性
    final fieldRegex = RegExp(
      r'(?:public|protected|private)?\s*(?:static|final)?\s*(\w+(?:<.*?>)?)\s+(\w+)(?:\s*=\s*([^;]+))?\s*;',
      multiLine: true,
    );
    
    final fieldMatches = fieldRegex.allMatches(classBody);
    
    for (final match in fieldMatches) {
      final type = match.group(1);
      final fieldName = match.group(2)!;
      final initialValue = match.group(3);
      
      // 计算行号和列号
      final lineInfo = _calculateLineAndColumn(classBody, match.start);
      
      members.add(ContextInfo(
        id: 'java_field_${DateTime.now().millisecondsSinceEpoch}_$fieldName',
        type: ContextType.variable,
        name: fieldName,
        range: ContextRange(
          start: match.start + offset,
          end: match.end + offset,
          line: lineInfo.line,
          column: lineInfo.column,
        ),
        metadata: {
          'type': type,
          'initialValue': initialValue,
          'isPublic': classBody.substring(match.start, match.end).contains('public'),
          'isProtected': classBody.substring(match.start, match.end).contains('protected'),
          'isPrivate': classBody.substring(match.start, match.end).contains('private'),
          'isStatic': classBody.substring(match.start, match.end).contains('static'),
          'isFinal': classBody.substring(match.start, match.end).contains('final'),
          'language': 'java',
        },
        dependencies: _extractTypeDependencies(type, null, null),
        children: [],
        analyzedAt: DateTime.now(),
      ));
    }
    
    return members;
  }

  /// 查找匹配的闭合大括号
  static int _findClosingBrace(String code, int startPos) {
    int braceCount = 1;
    int pos = startPos;
    
    while (pos < code.length && braceCount > 0) {
      final char = code[pos];
      if (char == '{') {
        braceCount++;
      } else if (char == '}') {
        braceCount--;
      }
      pos++;
    }
    
    return braceCount == 0 ? pos - 1 : -1;
  }

  /// 检查位置是否在类内部
  static bool _isInsideClass(String code, int position) {
    final classRegex = RegExp(r'(?:class|interface|enum)\s+\w+');
    final matches = classRegex.allMatches(code.substring(0, position));
    
    if (matches.isEmpty) return false;
    
    for (final match in matches) {
      final classStart = match.start;
      final openBracePos = code.indexOf('{', classStart);
      if (openBracePos == -1) continue;
      
      final classEnd = _findClosingBrace(code, openBracePos + 1);
      
      if (classEnd != -1 && position > classStart && position < classEnd) {
        return true;
      }
    }
    
    return false;
  }

  /// 检查位置是否在方法内部
  static bool _isInsideMethod(String code, int position) {
    final methodRegex = RegExp(r'\w+\s+\w+\s*\(');
    final matches = methodRegex.allMatches(code.substring(0, position));
    
    if (matches.isEmpty) return false;
    
    for (final match in matches) {
      final methodStart = match.start;
      final openBracePos = code.indexOf('{', methodStart);
      if (openBracePos == -1) continue;
      
      final methodEnd = _findClosingBrace(code, openBracePos + 1);
      
      if (methodEnd != -1 && position > methodStart && position < methodEnd) {
        return true;
      }
    }
    
    return false;
  }

  /// 解析方法参数
  static List<Map<String, String>> _parseParameters(String parametersString) {
    if (parametersString.trim().isEmpty) return [];
    
    final parameters = <Map<String, String>>[];
    final paramList = parametersString.split(',');
    
    for (final param in paramList) {
      final trimmedParam = param.trim();
      if (trimmedParam.isEmpty) continue;
      
      final parts = trimmedParam.split(' ');
      if (parts.length < 2) continue;
      
      final paramType = parts.sublist(0, parts.length - 1).join(' ');
      final paramName = parts.last;
      
      parameters.add({
        'type': paramType,
        'name': paramName,
      });
    }
    
    return parameters;
  }

  /// 提取依赖关系
  static List<String> _extractDependencies(
    String? extendsClass,
    String? interfaces,
  ) {
    final dependencies = <String>[];
    
    if (extendsClass != null) {
      dependencies.add(extendsClass);
    }
    
    if (interfaces != null) {
      dependencies.addAll(interfaces.split(',').map((i) => i.trim()));
    }
    
    return dependencies;
  }

  /// 提取类型依赖关系
  static List<String> _extractTypeDependencies(
    String? returnType,
    String? parameters,
    String? exceptions,
  ) {
    final dependencies = <String>[];
    
    if (returnType != null && !_isPrimitiveType(returnType)) {
      // 处理泛型
      final baseType = returnType.contains('<') ? returnType.substring(0, returnType.indexOf('<')) : returnType;
      dependencies.add(baseType);
      
      // 提取泛型参数
      if (returnType.contains('<')) {
        final genericParams = returnType.substring(returnType.indexOf('<') + 1, returnType.lastIndexOf('>'));
        dependencies.addAll(_extractGenericTypes(genericParams));
      }
    }
    
    if (parameters != null) {
      final paramList = parameters.split(',');
      for (final param in paramList) {
        final parts = param.trim().split(' ');
        if (parts.length >= 2) {
          final paramType = parts.sublist(0, parts.length - 1).join(' ');
          if (!_isPrimitiveType(paramType)) {
            // 处理泛型
            final baseType = paramType.contains('<') ? paramType.substring(0, paramType.indexOf('<')) : paramType;
            dependencies.add(baseType);
            
            // 提取泛型参数
            if (paramType.contains('<')) {
              final genericParams = paramType.substring(paramType.indexOf('<') + 1, paramType.lastIndexOf('>'));
              dependencies.addAll(_extractGenericTypes(genericParams));
            }
          }
        }
      }
    }
    
    if (exceptions != null) {
      dependencies.addAll(exceptions.split(',').map((e) => e.trim()));
    }
    
    return dependencies;
  }

  /// 提取泛型类型
  static List<String> _extractGenericTypes(String genericParams) {
    final types = <String>[];
    int depth = 0;
    int start = 0;
    
    for (int i = 0; i < genericParams.length; i++) {
      if (genericParams[i] == '<') {
        depth++;
      } else if (genericParams[i] == '>') {
        depth--;
      } else if (genericParams[i] == ',' && depth == 0) {
        final type = genericParams.substring(start, i).trim();
        if (!_isPrimitiveType(type)) {
          types.add(type);
        }
        start = i + 1;
      }
    }
    
    final lastType = genericParams.substring(start).trim();
    if (!_isPrimitiveType(lastType)) {
      types.add(lastType);
    }
    
    return types;
  }

  /// 检查是否为原始类型
  static bool _isPrimitiveType(String type) {
    final primitiveTypes = [
      'byte', 'short', 'int', 'long', 'float', 'double', 'boolean', 'char',
      'Byte', 'Short', 'Integer', 'Long', 'Float', 'Double', 'Boolean', 'Character',
      'String', 'Object', 'void', 'Void',
      'List', 'Map', 'Set', 'Collection', 'Iterable',
    ];
    
    return primitiveTypes.contains(type);
  }

  /// 计算行号和列号
  static _LineInfo _calculateLineAndColumn(String code, int offset) {
    int line = 1;
    int column = 1;
    
    for (int i = 0; i < offset; i++) {
      if (code[i] == '\n') {
        line++;
        column = 1;
      } else {
        column++;
      }
    }
    
    return _LineInfo(line, column);
  }
}

/// 行信息
class _LineInfo {
  final int line;
  final int column;
  
  _LineInfo(this.line, this.column);
} 