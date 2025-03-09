/// 语言支持基类
abstract class LanguageSupport {
  /// 获取语言ID
  String getLanguageId();

  /// 获取语言名称
  String getLanguageName();

  /// 获取文件扩展名列表
  List<String> getFileExtensions();

  /// 判断是否为源代码文件
  bool isSourceFile(String fileName);

  /// 判断是否为配置文件
  bool isConfigFile(String fileName);

  /// 获取导入语句列表
  List<String> getImports(String code);

  /// 获取导出语句列表
  List<String> getExports(String code);

  /// 获取类定义列表
  List<String> getClasses(String code);

  /// 获取函数定义列表
  List<String> getFunctions(String code);

  /// 获取变量定义列表
  List<String> getVariables(String code);

  /// 判断是否为测试文件
  bool isTestFile(String fileName);

  /// 获取单行注释开始符
  String getCommentStart();

  /// 获取单行注释结束符
  String getCommentEnd();

  /// 获取多行注释开始符
  String getBlockCommentStart();

  /// 获取多行注释结束符
  String getBlockCommentEnd();

  /// 获取行注释开始符
  String getLineCommentStart();

  /// 获取字符串分隔符
  String getStringDelimiter();

  /// 获取替代字符串分隔符
  String getAlternativeStringDelimiter();

  /// 获取模板字符串分隔符
  String getTemplateStringDelimiter();

  /// 判断是否为有效标识符
  bool isValidIdentifier(String name);

  /// 判断是否为关键字
  bool isKeyword(String word);

  /// 判断是否为运算符
  bool isOperator(String text);

  /// 判断是否为TypeScript代码
  bool isTypeScript(String code);
} 