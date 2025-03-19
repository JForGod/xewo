import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolbarVisibilityProvider = StateProvider<bool>((ref) => false);

final editorStateProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorState {
  final bool showLineNumbers;
  final bool showMinimap;
  final bool isModified;
  final String? currentFilePath;
  final Map<String, String> openFiles;
  
  EditorState({
    this.showLineNumbers = true,
    this.showMinimap = true,
    this.isModified = false,
    this.currentFilePath,
    Map<String, String>? openFiles,
  }) : openFiles = openFiles ?? {};
  
  EditorState copyWith({
    bool? showLineNumbers,
    bool? showMinimap,
    bool? isModified,
    String? currentFilePath,
    Map<String, String>? openFiles,
  }) {
    return EditorState(
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      showMinimap: showMinimap ?? this.showMinimap,
      isModified: isModified ?? this.isModified,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      openFiles: openFiles ?? this.openFiles,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState());
  
  void toggleLineNumbers() {
    state = state.copyWith(showLineNumbers: !state.showLineNumbers);
  }
  
  void toggleMinimap() {
    state = state.copyWith(showMinimap: !state.showMinimap);
  }
  
  void setModified(bool value) {
    state = state.copyWith(isModified: value);
  }
  
  void openFile(String path, String content) {
    final files = Map<String, String>.from(state.openFiles);
    files[path] = content;
    state = state.copyWith(
      currentFilePath: path,
      openFiles: files,
    );
  }
  
  void closeFile(String path) {
    final files = Map<String, String>.from(state.openFiles);
    files.remove(path);
    state = state.copyWith(
      currentFilePath: files.isEmpty ? null : files.keys.first,
      openFiles: files,
    );
  }
  
  void updateFileContent(String path, String content) {
    final files = Map<String, String>.from(state.openFiles);
    files[path] = content;
    state = state.copyWith(
      openFiles: files,
      isModified: true,
    );
  }
  
  void switchToFile(String path) {
    if (state.openFiles.containsKey(path)) {
      state = state.copyWith(currentFilePath: path);
    }
  }
} 