import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xewo/src/services/core/logger_service.dart';
import 'package:xewo/src/services/core/settings_service.dart';

/// 括号匹配服务
class BracketMatchingService {
  final LoggerService _logger;
  final SettingsService _settings;
  
  /// 构造函数
  BracketMatchingService(this._logger, this._settings);
  
  /// 括号对映射
  final Map<String, String> _bracketPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '<': '>',
  };
  
  /// 反向括号对映射
  late final Map<String, String> _reverseBracketPairs = 
      Map.fromEntries(_bracketPairs.entries.map((e) => MapEntry(e.value, e.key)));
  
  bool _enabled = true;
  
  /// 检查是否启用
  bool isEnabled() => _enabled;
  
  /// 设置启用状态
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
  
  /// 检查是否启用自动闭合括号
  bool isAutoClosingEnabled() {
    return _settings.getBoolValue('editor.autoClosingBrackets', true);
  }
  
  /// 获取匹配的括号位置
  List<int> getHighlightPositions(String text, int cursorPosition) {
    if (!_enabled || cursorPosition < 0 || cursorPosition > text.length) {
      return [];
    }
    
    // 检查光标前的字符
    if (cursorPosition > 0) {
      final char = text[cursorPosition - 1];
      if (_bracketPairs.containsKey(char)) {
        // 找到开括号，寻找对应的闭括号
        final closingBracket = _bracketPairs[char]!;
        final matchingPosition = _findMatchingClosingBracket(
          text, 
          cursorPosition, 
          char, 
          closingBracket,
        );
        
        if (matchingPosition != -1) {
          return [cursorPosition - 1, matchingPosition];
        }
      } else if (_bracketPairs.containsValue(char)) {
        // 找到闭括号，寻找对应的开括号
        final openingBracket = _getKeyByValue(_bracketPairs, char);
        if (openingBracket != null) {
          final matchingPosition = _findMatchingOpeningBracket(
            text, 
            cursorPosition - 2, 
            openingBracket, 
            char,
          );
          
          if (matchingPosition != -1) {
            return [matchingPosition, cursorPosition - 1];
          }
        }
      }
    }
    
    // 检查光标处的字符
    if (cursorPosition < text.length) {
      final char = text[cursorPosition];
      if (_bracketPairs.containsKey(char)) {
        // 找到开括号，寻找对应的闭括号
        final closingBracket = _bracketPairs[char]!;
        final matchingPosition = _findMatchingClosingBracket(
          text, 
          cursorPosition + 1, 
          char, 
          closingBracket,
        );
        
        if (matchingPosition != -1) {
          return [cursorPosition, matchingPosition];
        }
      } else if (_bracketPairs.containsValue(char)) {
        // 找到闭括号，寻找对应的开括号
        final openingBracket = _getKeyByValue(_bracketPairs, char);
        if (openingBracket != null) {
          final matchingPosition = _findMatchingOpeningBracket(
            text, 
            cursorPosition - 1, 
            openingBracket, 
            char,
          );
          
          if (matchingPosition != -1) {
            return [matchingPosition, cursorPosition];
          }
        }
      }
    }
    
    return [];
  }
  
  /// 寻找匹配的闭括号
  int _findMatchingClosingBracket(
    String text, 
    int startPosition, 
    String openBracket, 
    String closeBracket,
  ) {
    int count = 1;
    for (int i = startPosition; i < text.length; i++) {
      if (text[i] == openBracket) {
        count++;
      } else if (text[i] == closeBracket) {
        count--;
        if (count == 0) {
          return i;
        }
      }
    }
    return -1;
  }
  
  /// 寻找匹配的开括号
  int _findMatchingOpeningBracket(
    String text, 
    int startPosition, 
    String openBracket, 
    String closeBracket,
  ) {
    int count = 1;
    for (int i = startPosition; i >= 0; i--) {
      if (text[i] == closeBracket) {
        count++;
      } else if (text[i] == openBracket) {
        count--;
        if (count == 0) {
          return i;
        }
      }
    }
    return -1;
  }
  
  /// 根据值获取键
  String? _getKeyByValue(Map<String, String> map, String value) {
    for (final entry in map.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }
  
  /// 获取匹配的括号对
  List<BracketPair> findAllBracketPairs(String text) {
    final pairs = <BracketPair>[];
    final stack = <_BracketInfo>[];
    
    for (int i = 0; i < text.length; i++) {
      // 跳过字符串和注释
      i = _skipStringAndComment(text, i);
      if (i >= text.length) break;
      
      final char = text[i];
      
      // 处理开括号
      if (_bracketPairs.containsKey(char)) {
        stack.add(_BracketInfo(char, i));
      }
      // 处理闭括号
      else if (_reverseBracketPairs.containsKey(char)) {
        final openBracket = _reverseBracketPairs[char]!;
        
        // 查找匹配的开括号
        if (stack.isNotEmpty && stack.last.bracket == openBracket) {
          final info = stack.removeLast();
          pairs.add(BracketPair(info.position, i, info.bracket, char));
        }
      }
    }
    
    return pairs;
  }
  
  /// 处理括号输入
  String handleBracketInput(String text, int cursorPosition, String bracket) {
    if (!isAutoClosingEnabled()) {
      return text.substring(0, cursorPosition) + bracket + text.substring(cursorPosition);
    }
    
    // 如果是开括号，自动添加闭括号
    if (_bracketPairs.containsKey(bracket)) {
      final closeBracket = _bracketPairs[bracket]!;
      
      // 检查是否已经有闭括号
      if (cursorPosition < text.length && text[cursorPosition] == closeBracket) {
        // 如果下一个字符已经是闭括号，只移动光标
        return text;
      }
      
      // 添加开闭括号对
      return text.substring(0, cursorPosition) + bracket + closeBracket + text.substring(cursorPosition);
    }
    
    // 如果是闭括号，检查是否需要跳过
    if (_reverseBracketPairs.containsKey(bracket)) {
      // 如果下一个字符已经是这个闭括号，只移动光标
      if (cursorPosition < text.length && text[cursorPosition] == bracket) {
        return text;
      }
    }
    
    // 默认行为：插入字符
    return text.substring(0, cursorPosition) + bracket + text.substring(cursorPosition);
  }
  
  /// 处理退格键
  String handleBackspace(String text, int cursorPosition) {
    if (!isAutoClosingEnabled() || cursorPosition <= 0 || cursorPosition >= text.length) {
      return cursorPosition > 0 
          ? text.substring(0, cursorPosition - 1) + text.substring(cursorPosition)
          : text;
    }
    
    final charBefore = text[cursorPosition - 1];
    final charAfter = text[cursorPosition];
    
    // 检查是否在括号对之间
    if (_bracketPairs.containsKey(charBefore) && _bracketPairs[charBefore] == charAfter) {
      // 删除括号对
      return text.substring(0, cursorPosition - 1) + text.substring(cursorPosition + 1);
    }
    
    // 默认行为：删除前一个字符
    return text.substring(0, cursorPosition - 1) + text.substring(cursorPosition);
  }
  
  /// 跳过字符串和注释
  int _skipStringAndComment(String text, int position) {
    int pos = position;
    
    while (pos < text.length) {
      final char = text[pos];
      
      // 检查是否在字符串内
      if (char == '"' || char == "'" || char == '`') {
        pos = _skipString(text, pos, char);
      }
      // 检查是否在单行注释内
      else if (char == '/' && pos + 1 < text.length && text[pos + 1] == '/') {
        pos = _skipLineComment(text, pos);
      }
      // 检查是否在多行注释内
      else if (char == '/' && pos + 1 < text.length && text[pos + 1] == '*') {
        pos = _skipBlockComment(text, pos);
      }
      else {
        break;
      }
    }
    
    return pos;
  }
  
  /// 跳过字符串
  int _skipString(String text, int position, String quote) {
    int pos = position + 1;
    bool escaped = false;
    
    while (pos < text.length) {
      final char = text[pos];
      
      if (char == '\\') {
        escaped = !escaped;
      } else if (char == quote && !escaped) {
        return pos + 1;
      } else {
        escaped = false;
      }
      
      pos++;
    }
    
    return pos;
  }
  
  /// 跳过行注释
  int _skipLineComment(String text, int position) {
    int pos = position + 2;
    
    while (pos < text.length && text[pos] != '\n') {
      pos++;
    }
    
    return pos + 1;
  }
  
  /// 跳过块注释
  int _skipBlockComment(String text, int position) {
    int pos = position + 2;
    
    while (pos + 1 < text.length) {
      if (text[pos] == '*' && text[pos + 1] == '/') {
        return pos + 2;
      }
      
      pos++;
    }
    
    return pos;
  }
}

/// 括号对信息
class _BracketInfo {
  final String bracket;
  final int position;
  
  _BracketInfo(this.bracket, this.position);
}

/// 括号对
class BracketPair {
  final int openPosition;
  final int closePosition;
  final String openBracket;
  final String closeBracket;
  
  BracketPair(this.openPosition, this.closePosition, this.openBracket, this.closeBracket);
}

/// 括号匹配服务提供者
final bracketMatchingServiceProvider = Provider<BracketMatchingService>((ref) {
  return BracketMatchingService(ref.watch(loggerServiceProvider), ref.watch(settingsServiceProvider));
}); 