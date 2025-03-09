import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../services/core/system/file_service.dart';

class FileState {
  final bool isLoading;
  final String? error;
  final List<FileSystemEntity> files;
  final String? currentFilePath;
  final String? currentContent;

  FileState({
    this.isLoading = false,
    this.error,
    this.files = const [],
    this.currentFilePath,
    this.currentContent,
  });

  FileState copyWith({
    bool? isLoading,
    String? error,
    List<FileSystemEntity>? files,
    String? currentFilePath,
    String? currentContent,
  }) {
    return FileState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      files: files ?? this.files,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      currentContent: currentContent ?? this.currentContent,
    );
  }
}

class FileStateNotifier extends StateNotifier<FileState> {
  final FileService _fileService;

  FileStateNotifier(this._fileService) : super(FileState());

  Future<void> createFile(String path) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _fileService.createFile(path);
      await _refreshFiles();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> openFile(String path) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final content = await _fileService.readFile(path);
      state = state.copyWith(
        currentFilePath: path,
        currentContent: content,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveFile() async {
    if (state.currentFilePath == null || state.currentContent == null) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _fileService.writeFile(state.currentFilePath!, state.currentContent!);
      await _refreshFiles();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _refreshFiles() async {
    // TODO: 实现文件列表刷新逻辑
  }
}

final fileStateProvider = StateNotifierProvider<FileStateNotifier, FileState>((ref) {
  return FileStateNotifier(FileService());
}); 