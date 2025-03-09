import '../completion_service.dart';

/// 代码片段补全提供者
class SnippetCompletionProvider implements CompletionProvider {
  final Map<String, Map<String, String>> _snippets;
  
  SnippetCompletionProvider({
    Map<String, Map<String, String>>? snippets,
  }) : _snippets = snippets ?? {
    'dart': {
      'if': 'if (condition) {\n  \n}',
      'for': 'for (var i = 0; i < count; i++) {\n  \n}',
      'while': 'while (condition) {\n  \n}',
      'try': 'try {\n  \n} catch (e) {\n  \n}',
      'class': 'class ClassName {\n  \n}',
      'main': 'void main() {\n  \n}',
      'setState': 'setState(() {\n  \n});',
      'build': '@override\nWidget build(BuildContext context) {\n  return \n}',
      'initState': '@override\nvoid initState() {\n  super.initState();\n  \n}',
      'dispose': '@override\nvoid dispose() {\n  \n  super.dispose();\n}',
      'stateless': '''class WidgetName extends StatelessWidget {
  const WidgetName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}''',
      'stateful': '''class WidgetName extends StatefulWidget {
  const WidgetName({Key? key}) : super(key: key);

  @override
  State<WidgetName> createState() => _WidgetNameState();
}

class _WidgetNameState extends State<WidgetName> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}''',
      'consumer': '''class WidgetName extends ConsumerWidget {
  const WidgetName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}''',
      'consumerStateful': '''class WidgetName extends ConsumerStatefulWidget {
  const WidgetName({Key? key}) : super(key: key);

  @override
  ConsumerState<WidgetName> createState() => _WidgetNameState();
}

class _WidgetNameState extends ConsumerState<WidgetName> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}''',
    },
  };
  
  @override
  bool canHandle(String? fileType) => fileType != null && _snippets.containsKey(fileType);
  
  @override
  Future<List<CompletionItem>> getCompletions(CompletionContext context) async {
    if (context.fileType == null || !_snippets.containsKey(context.fileType!)) {
      return [];
    }
    
    final word = context.currentWord.toLowerCase();
    if (word.isEmpty) return [];
    
    return _snippets[context.fileType!]!
        .entries
        .where((entry) => entry.key.toLowerCase().startsWith(word))
        .map((entry) => CompletionItem(
          label: entry.key,
          kind: CompletionItemKind.snippet,
          detail: '代码片段',
          documentation: entry.value,
          insertText: entry.value,
          sortText: 3, // 片段排在关键字后面
        ))
        .toList();
  }
} 