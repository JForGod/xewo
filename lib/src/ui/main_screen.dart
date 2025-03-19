// 假设MainScreen中包含了文件树组件和编辑器组件

// 需要添加一个状态变量来跟踪文件树是否可见
bool _isFileTreeVisible = true;

// 在构建FileTree组件时，添加onToggleVisibility回调
FileTree(
  onFileSelected: _handleFileSelected,
  onToggleVisibility: () {
    setState(() {
      _isFileTreeVisible = !_isFileTreeVisible;
    });
  },
),

// 在布局中根据_isFileTreeVisible状态来控制文件树的显示
// 例如，在Row或者Split组件中：
Row(
  children: [
    if (_isFileTreeVisible)
      SizedBox(
        width: 250, // 或其他宽度
        child: FileTree(
          onFileSelected: _handleFileSelected,
          onToggleVisibility: () {
            setState(() {
              _isFileTreeVisible = !_isFileTreeVisible;
            });
          },
        ),
      ),
    Expanded(
      child: EditorView(), // 编辑器组件
    ),
  ],
) 