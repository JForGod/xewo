import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/providers/file_state_provider.dart';

class FileOperationsWidget extends ConsumerWidget {
  const FileOperationsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileStateProvider);
    final fileNotifier = ref.read(fileStateProvider.notifier);

    return Column(
      children: [
        if (fileState.isLoading)
          const LinearProgressIndicator(),
        if (fileState.error != null)
          Text(
            fileState.error!,
            style: const TextStyle(color: Colors.red),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => const NewFileDialog(),
                );
                if (result != null) {
                  await fileNotifier.createFile(result);
                }
              },
              child: const Text('新建文件'),
            ),
            ElevatedButton(
              onPressed: fileState.currentFilePath != null
                  ? () => fileNotifier.saveFile()
                  : null,
              child: const Text('保存文件'),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              return ListTile(
                title: Text(file.path),
                onTap: () => fileNotifier.openFile(file.path),
              );
            },
          ),
        ),
      ],
    );
  }
}

class NewFileDialog extends StatefulWidget {
  const NewFileDialog({Key? key}) : super(key: key);

  @override
  _NewFileDialogState createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<NewFileDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建文件'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '文件路径',
          hintText: '请输入文件路径',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('确定'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 