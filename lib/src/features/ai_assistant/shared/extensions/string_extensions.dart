import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 字符串扩展
extension StringExtensions on String {
  /// 将字符串转为驼峰式命名
  String toCamelCase() {
    if (isEmpty) return '';
    
    final words = split(RegExp(r'[_\s-]+'));
    final firstWord = words[0].toLowerCase();
    final remainingWords = words.sublist(1).map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('');
    
    return firstWord + remainingWords;
  }
  
  /// 将字符串转为帕斯卡式命名
  String toPascalCase() {
    if (isEmpty) return '';
    
    final words = split(RegExp(r'[_\s-]+'));
    return words.map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('');
  }
  
  /// 将字符串转为下划线命名
  String toSnakeCase() {
    if (isEmpty) return '';
    
    final result = replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    
    return result.replaceAll(RegExp(r'[-\s]+'), '_').toLowerCase();
  }
  
  /// 将字符串转为短横线命名
  String toKebabCase() {
    if (isEmpty) return '';
    
    final result = replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '-${match.group(0)!.toLowerCase()}',
    );
    
    return result.replaceAll(RegExp(r'[_\s]+'), '-').toLowerCase();
  }
  
  /// 将字符串首字母大写
  String capitalize() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
  
  /// 将字符串每个单词首字母大写
  String toTitleCase() {
    if (isEmpty) return '';
    
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
  
  /// 检查字符串是否为有效的电子邮件地址
  bool isValidEmail() {
    if (isEmpty) return false;
    
    final emailRegExp = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
    return emailRegExp.hasMatch(this);
  }
  
  /// 检查字符串是否为有效的URL
  bool isValidUrl() {
    if (isEmpty) return false;
    
    final urlRegExp = RegExp(
      r'^(http|https)://'
      r'(([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}|'
      r'localhost|'
      r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
      r'(:\d+)?'
      r'(/[-a-zA-Z0-9%_.~#+]*)*'
      r'(\?[;&a-zA-Z0-9%_.~+=-]*)?'
      r'(\#[-a-zA-Z0-9%_.~+=/]*)?$',
    );
    
    return urlRegExp.hasMatch(this);
  }
  
  /// 检查字符串是否为有效的手机号（中国大陆）
  bool isValidPhoneNumber() {
    if (isEmpty) return false;
    
    final phoneRegExp = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegExp.hasMatch(this);
  }
  
  /// 从字符串生成MD5哈希
  String toMd5() {
    return md5.convert(utf8.encode(this)).toString();
  }
  
  /// 从字符串生成SHA-1哈希
  String toSha1() {
    return sha1.convert(utf8.encode(this)).toString();
  }
  
  /// 从字符串生成SHA-256哈希
  String toSha256() {
    return sha256.convert(utf8.encode(this)).toString();
  }
  
  /// 将字符串截断为指定长度，并添加省略号
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) {
      return this;
    }
    
    return substring(0, maxLength - suffix.length) + suffix;
  }
  
  /// 将URL字符串转为无协议（省略http:// 或 https://）形式
  String toDisplayUrl() {
    return replaceFirst(RegExp(r'^https?://'), '');
  }
  
  /// 检查字符串是否全部为大写
  bool isUpperCase() {
    return this == toUpperCase();
  }
  
  /// 检查字符串是否全部为小写
  bool isLowerCase() {
    return this == toLowerCase();
  }
  
  /// 移除字符串中的HTML标签
  String stripHtml() {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }
  
  /// 将字符串中的多个连续空白字符替换为单个空格
  String normalizeWhitespace() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// 计算字符串的字节大小
  int get byteSize {
    return utf8.encode(this).length;
  }
}
