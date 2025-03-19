import 'package:flutter/material.dart';

/// 搜索结果项
class SearchResultItem {
  /// 文件路径
  final String filePath;
  
  /// 行号
  final int lineNumber;
  
  /// 列号
  final int columnNumber;
  
  /// 匹配文本
  final String matchText;
  
  /// 前缀文本
  final String prefixText;
  
  /// 后缀文本
  final String suffixText;
  
  /// 构造函数
  SearchResultItem({
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.matchText,
    this.prefixText = '',
    this.suffixText = '',
  });
}

/// 搜索状态管理类
class SearchState extends ChangeNotifier {
  /// 搜索关键字
  String _searchText = '';
  
  /// 替换文本
  String _replaceText = '';
  
  /// 是否区分大小写
  bool _caseSensitive = false;
  
  /// 是否使用正则表达式
  bool _useRegex = false;
  
  /// 是否全字匹配
  bool _wholeWord = false;
  
  /// 是否在当前文件中搜索
  bool _searchInCurrentFile = true;
  
  /// 是否在所有文件中搜索
  bool _searchInAllFiles = false;
  
  /// 搜索结果
  List<SearchResultItem> _searchResults = [];
  
  /// 当前选中结果索引
  int _selectedResultIndex = -1;
  
  /// 是否显示搜索面板
  bool _showSearchPanel = false;
  
  /// 是否显示替换面板
  bool _showReplacePanel = false;
  
  /// 获取搜索关键字
  String get searchText => _searchText;
  
  /// 获取替换文本
  String get replaceText => _replaceText;
  
  /// 获取是否区分大小写
  bool get caseSensitive => _caseSensitive;
  
  /// 获取是否使用正则表达式
  bool get useRegex => _useRegex;
  
  /// 获取是否全字匹配
  bool get wholeWord => _wholeWord;
  
  /// 获取是否在当前文件中搜索
  bool get searchInCurrentFile => _searchInCurrentFile;
  
  /// 获取是否在所有文件中搜索
  bool get searchInAllFiles => _searchInAllFiles;
  
  /// 获取搜索结果
  List<SearchResultItem> get searchResults => _searchResults;
  
  /// 获取当前选中结果索引
  int get selectedResultIndex => _selectedResultIndex;
  
  /// 获取是否显示搜索面板
  bool get showSearchPanel => _showSearchPanel;
  
  /// 获取是否显示替换面板
  bool get showReplacePanel => _showReplacePanel;
  
  /// 设置搜索关键字
  set searchText(String value) {
    _searchText = value;
    notifyListeners();
  }
  
  /// 设置替换文本
  set replaceText(String value) {
    _replaceText = value;
    notifyListeners();
  }
  
  /// 设置是否区分大小写
  set caseSensitive(bool value) {
    _caseSensitive = value;
    notifyListeners();
  }
  
  /// 设置是否使用正则表达式
  set useRegex(bool value) {
    _useRegex = value;
    notifyListeners();
  }
  
  /// 设置是否全字匹配
  set wholeWord(bool value) {
    _wholeWord = value;
    notifyListeners();
  }
  
  /// 设置是否在当前文件中搜索
  set searchInCurrentFile(bool value) {
    _searchInCurrentFile = value;
    notifyListeners();
  }
  
  /// 设置是否在所有文件中搜索
  set searchInAllFiles(bool value) {
    _searchInAllFiles = value;
    notifyListeners();
  }
  
  /// 设置搜索结果
  set searchResults(List<SearchResultItem> value) {
    _searchResults = value;
    _selectedResultIndex = value.isNotEmpty ? 0 : -1;
    notifyListeners();
  }
  
  /// 设置当前选中结果索引
  set selectedResultIndex(int value) {
    if (value >= -1 && value < _searchResults.length) {
      _selectedResultIndex = value;
      notifyListeners();
    }
  }
  
  /// 设置是否显示搜索面板
  set showSearchPanel(bool value) {
    _showSearchPanel = value;
    notifyListeners();
  }
  
  /// 设置是否显示替换面板
  set showReplacePanel(bool value) {
    _showReplacePanel = value;
    if (value) {
      _showSearchPanel = true;
    }
    notifyListeners();
  }
  
  /// 切换搜索面板显示
  void toggleSearchPanel() {
    _showSearchPanel = !_showSearchPanel;
    if (!_showSearchPanel) {
      _showReplacePanel = false;
    }
    notifyListeners();
  }
  
  /// 切换替换面板显示
  void toggleReplacePanel() {
    _showReplacePanel = !_showReplacePanel;
    if (_showReplacePanel) {
      _showSearchPanel = true;
    }
    notifyListeners();
  }
  
  /// 选择下一个结果
  void selectNextResult() {
    if (_searchResults.isNotEmpty) {
      _selectedResultIndex = (_selectedResultIndex + 1) % _searchResults.length;
      notifyListeners();
    }
  }
  
  /// 选择上一个结果
  void selectPreviousResult() {
    if (_searchResults.isNotEmpty) {
      _selectedResultIndex = (_selectedResultIndex - 1 + _searchResults.length) % _searchResults.length;
      notifyListeners();
    }
  }
  
  /// 清空搜索结果
  void clearSearchResults() {
    _searchResults = [];
    _selectedResultIndex = -1;
    notifyListeners();
  }
  
  /// 重置状态
  void reset() {
    _searchText = '';
    _replaceText = '';
    _caseSensitive = false;
    _useRegex = false;
    _wholeWord = false;
    _searchInCurrentFile = true;
    _searchInAllFiles = false;
    _searchResults = [];
    _selectedResultIndex = -1;
    _showSearchPanel = false;
    _showReplacePanel = false;
    notifyListeners();
  }
} 