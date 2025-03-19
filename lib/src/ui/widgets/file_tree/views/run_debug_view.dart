import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/loading_indicator.dart';

class RunDebugView extends ConsumerStatefulWidget {
  const RunDebugView({super.key});

  @override
  ConsumerState<RunDebugView> createState() => _RunDebugViewState();
}

class _RunDebugViewState extends ConsumerState<RunDebugView> {
  bool _isRunning = false;
  bool _isDebugging = false;
  List<DebugConfiguration> _configurations = [];
  DebugConfiguration? _selectedConfiguration;
  final List<String> _consoleOutput = [];

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  void _loadConfigurations() {
    // 模拟加载配置
    setState(() {
      _configurations = [
        DebugConfiguration(
          name: 'Flutter Run',
          command: 'flutter run -d windows',
          type: ConfigurationType.flutter,
        ),
        DebugConfiguration(
          name: 'Flutter Debug',
          command: 'flutter run -d windows --debug',
          type: ConfigurationType.flutter,
        ),
        DebugConfiguration(
          name: 'Flutter Profile',
          command: 'flutter run -d windows --profile',
          type: ConfigurationType.flutter,
        ),
        DebugConfiguration(
          name: 'Flutter Release',
          command: 'flutter run -d windows --release',
          type: ConfigurationType.flutter,
        ),
      ];
      _selectedConfiguration = _configurations.first;
    });
  }

  void _startRun() {
    if (_isRunning || _isDebugging) return;

    setState(() {
      _isRunning = true;
      _consoleOutput.clear();
      _addConsoleOutput('正在运行: ${_selectedConfiguration?.command}');
      _addConsoleOutput('正在编译...');
    });

    // 模拟运行过程
    Future.delayed(const Duration(seconds: 2), () {
      _addConsoleOutput('编译完成');
      _addConsoleOutput('正在启动应用...');
      
      Future.delayed(const Duration(seconds: 1), () {
        _addConsoleOutput('应用已启动');
        _addConsoleOutput('Flutter run key commands.');
        _addConsoleOutput('r Hot reload.');
        _addConsoleOutput('R Hot restart.');
        _addConsoleOutput('h List all available interactive commands.');
        _addConsoleOutput('d Detach (terminate "flutter run" but leave application running).');
        _addConsoleOutput('c Clear the screen');
        _addConsoleOutput('q Quit (terminate the application on the device).');
      });
    });
  }

  void _startDebug() {
    if (_isRunning || _isDebugging) return;

    setState(() {
      _isDebugging = true;
      _consoleOutput.clear();
      _addConsoleOutput('正在调试: ${_selectedConfiguration?.command} --debug');
      _addConsoleOutput('正在编译...');
    });

    // 模拟调试过程
    Future.delayed(const Duration(seconds: 2), () {
      _addConsoleOutput('编译完成');
      _addConsoleOutput('正在启动调试器...');
      
      Future.delayed(const Duration(seconds: 1), () {
        _addConsoleOutput('调试器已启动');
        _addConsoleOutput('Debugger attached');
        _addConsoleOutput('Waiting for connection from debug service...');
        _addConsoleOutput('Debug service listening on ws://127.0.0.1:50123/ws');
        _addConsoleOutput('The Flutter DevTools debugger and profiler is available at:');
        _addConsoleOutput('http://127.0.0.1:9102?uri=ws://127.0.0.1:50123/ws');
      });
    });
  }

  void _stop() {
    setState(() {
      _isRunning = false;
      _isDebugging = false;
      _addConsoleOutput('已停止');
    });
  }

  void _addConsoleOutput(String line) {
    setState(() {
      _consoleOutput.add(line);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 工具栏
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              // 配置选择下拉框
              Expanded(
                child: DropdownButton<DebugConfiguration>(
                  value: _selectedConfiguration,
                  isExpanded: true,
                  underline: Container(
                    height: 1,
                    color: theme.dividerColor,
                  ),
                  onChanged: (DebugConfiguration? newValue) {
                    setState(() {
                      _selectedConfiguration = newValue;
                    });
                  },
                  items: _configurations.map<DropdownMenuItem<DebugConfiguration>>(
                    (DebugConfiguration config) {
                      return DropdownMenuItem<DebugConfiguration>(
                        value: config,
                        child: Row(
                          children: [
                            Icon(
                              _getConfigIcon(config.type),
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(config.name),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
              const SizedBox(width: 8),
              // 运行按钮
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: '运行',
                color: _isRunning ? Colors.green : null,
                onPressed: _isRunning || _isDebugging ? null : _startRun,
              ),
              // 调试按钮
              IconButton(
                icon: const Icon(Icons.bug_report),
                tooltip: '调试',
                color: _isDebugging ? Colors.blue : null,
                onPressed: _isRunning || _isDebugging ? null : _startDebug,
              ),
              // 停止按钮
              IconButton(
                icon: const Icon(Icons.stop),
                tooltip: '停止',
                color: Colors.red,
                onPressed: _isRunning || _isDebugging ? _stop : null,
              ),
            ],
          ),
        ),

        // 控制台输出
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: _consoleOutput.length,
              itemBuilder: (context, index) {
                return Text(
                  _consoleOutput[index],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),

        // 状态栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isRunning
                    ? Icons.play_arrow
                    : _isDebugging
                        ? Icons.bug_report
                        : Icons.stop,
                size: 16,
                color: _isRunning
                    ? Colors.green
                    : _isDebugging
                        ? Colors.blue
                        : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _isRunning
                    ? '正在运行'
                    : _isDebugging
                        ? '正在调试'
                        : '已停止',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              if (_isRunning || _isDebugging)
                Text(
                  '按 q 停止',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getConfigIcon(ConfigurationType type) {
    switch (type) {
      case ConfigurationType.flutter:
        return Icons.flutter_dash;
      case ConfigurationType.dart:
        return Icons.code;
      case ConfigurationType.web:
        return Icons.web;
      case ConfigurationType.custom:
        return Icons.settings;
    }
  }
}

enum ConfigurationType {
  flutter,
  dart,
  web,
  custom,
}

class DebugConfiguration {
  final String name;
  final String command;
  final ConfigurationType type;

  DebugConfiguration({
    required this.name,
    required this.command,
    required this.type,
  });
} 