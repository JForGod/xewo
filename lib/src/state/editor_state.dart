import 'package:flutter/material.dart';

/// 编辑器状态管理类
class EditorState extends ChangeNotifier {
  /// 当前文件路径
  String? _currentFilePath;
  
  /// 当前文件内容
  String _content = '';
  
  /// 是否已修改
  bool _isModified = false;
  
  /// 是否显示行号
  bool _showLineNumbers = true;
  
  /// 是否显示小地图
  bool _showMinimap = true;
  
  /// 获取当前文件路径
  String? get currentFilePath => _currentFilePath;
  
  /// 获取当前文件内容
  String get content => _content;
  
  /// 获取是否已修改
  bool get isModified => _isModified;
  
  /// 获取是否显示行号
  bool get showLineNumbers => _showLineNumbers;
  
  /// 获取是否显示小地图
  bool get showMinimap => _showMinimap;
  
  /// 设置当前文件路径
  set currentFilePath(String? path) {
    _currentFilePath = path;
    notifyListeners();
  }
  
  /// 设置当前文件内容
  set content(String value) {
    if (_content != value) {
      _content = value;
      _isModified = true;
      notifyListeners();
    }
  }
  
  /// 设置是否已修改
  set isModified(bool value) {
    if (_isModified != value) {
      _isModified = value;
      notifyListeners();
    }
  }
  
  /// 设置是否显示行号
  set showLineNumbers(bool value) {
    if (_showLineNumbers != value) {
      _showLineNumbers = value;
      notifyListeners();
    }
  }
  
  /// 设置是否显示小地图
  set showMinimap(bool value) {
    if (_showMinimap != value) {
      _showMinimap = value;
      notifyListeners();
    }
  }
  
  /// 切换行号显示
  void toggleLineNumbers() {
    _showLineNumbers = !_showLineNumbers;
    notifyListeners();
  }
  
  /// 切换小地图显示
  void toggleMinimap() {
    _showMinimap = !_showMinimap;
    notifyListeners();
  }
  
  /// 保存文件
  void saveFile() {
    _isModified = false;
    notifyListeners();
  }
  
  /// 重置状态
  void reset() {
    _currentFilePath = null;
    _content = '';
    _isModified = false;
    notifyListeners();
  }
} 