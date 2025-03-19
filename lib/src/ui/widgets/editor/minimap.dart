import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

/// 编辑器小地图组件
class Minimap extends StatefulWidget {
  final String code;
  final String language;
  final ScrollController scrollController;
  final int currentLine;
  
  const Minimap({
    Key? key,
    required this.code,
    required this.language,
    required this.scrollController,
    required this.currentLine,
  }) : super(key: key);
  
  @override
  State<Minimap> createState() => _MinimapState();
}

class _MinimapState extends State<Minimap> {
  double _viewportPosition = 0.0;
  double _viewportHeight = 100.0;
  bool _isDragging = false;
  late ScrollController _internalScrollController;
  
  @override
  void initState() {
    super.initState();
    _internalScrollController = ScrollController();
    widget.scrollController.addListener(_updateViewportPosition);
  }
  
  @override
  void dispose() {
    widget.scrollController.removeListener(_updateViewportPosition);
    _internalScrollController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(Minimap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_updateViewportPosition);
      widget.scrollController.addListener(_updateViewportPosition);
    }
  }
  
  void _updateViewportPosition() {
    if (!mounted || !widget.scrollController.hasClients) return;
    
    final scrollPosition = widget.scrollController.position;
    final viewportDimension = scrollPosition.viewportDimension;
    final maxScrollExtent = scrollPosition.maxScrollExtent;
    final offset = scrollPosition.pixels;
    
    if (maxScrollExtent <= 0) {
      setState(() {
        _viewportPosition = 0;
        _viewportHeight = 100;
      });
      return;
    }
    
    // 计算可视区域在小地图中的位置和高度
    final contentHeight = maxScrollExtent + viewportDimension;
    final minimapHeight = 100.0; // 小地图内容区域高度
    final scale = minimapHeight / contentHeight;
    
    setState(() {
      _viewportPosition = offset * scale;
      _viewportHeight = viewportDimension * scale;
    });
  }
  
  void _handleDragStart(DragStartDetails details) {
    if (!widget.scrollController.hasClients) return;
    setState(() {
      _isDragging = true;
    });
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.scrollController.hasClients) return;
    
    final scrollPosition = widget.scrollController.position;
    final maxScrollExtent = scrollPosition.maxScrollExtent;
    final viewportDimension = scrollPosition.viewportDimension;
    
    if (maxScrollExtent <= 0) return;
    
    // 计算拖动后的位置
    final contentHeight = maxScrollExtent + viewportDimension;
    final minimapHeight = 100.0; // 小地图内容区域高度
    final scale = contentHeight / minimapHeight;
    
    // 直接使用当前拖动位置计算新的滚动位置
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final newPosition = (localPosition.dy - _viewportHeight / 2).clamp(0.0, minimapHeight - _viewportHeight) * scale;
    
    // 更新滚动位置
    widget.scrollController.jumpTo(newPosition.clamp(0.0, maxScrollExtent));
  }
  
  void _handleDragEnd(DragEndDetails details) {
    if (!widget.scrollController.hasClients) return;
    setState(() {
      _isDragging = false;
    });
  }
  
  void _handleMinimapTap(TapDownDetails details) {
    if (!widget.scrollController.hasClients) return;
    
    final scrollPosition = widget.scrollController.position;
    final maxScrollExtent = scrollPosition.maxScrollExtent;
    final viewportDimension = scrollPosition.viewportDimension;
    
    if (maxScrollExtent <= 0) return;
    
    // 计算点击位置对应的滚动位置
    final contentHeight = maxScrollExtent + viewportDimension;
    final minimapHeight = 100.0; // 小地图内容区域高度
    final scale = contentHeight / minimapHeight;
    
    final tapPosition = details.localPosition.dy;
    final newScrollPosition = (tapPosition - _viewportHeight / 2) * scale;
    
    // 更新滚动位置
    widget.scrollController.jumpTo(newScrollPosition.clamp(0.0, maxScrollExtent));
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = isDarkMode 
        ? {
            'root': TextStyle(
              backgroundColor: const Color(0xFF1E1E1E),
              color: const Color(0xFFD4D4D4),
            ),
            'keyword': const TextStyle(color: Color(0xFF569CD6)),
            'literal': const TextStyle(color: Color(0xFF569CD6)),
            'symbol': const TextStyle(color: Color(0xFF569CD6)),
            'name': const TextStyle(color: Color(0xFF9CDCFE)),
            'params': const TextStyle(color: Color(0xFF9CDCFE)),
            'string': const TextStyle(color: Color(0xFFCE9178)),
            'number': const TextStyle(color: Color(0xFFB5CEA8)),
            'title': const TextStyle(color: Color(0xFFDCDCAA)),
            'comment': const TextStyle(color: Color(0xFF6A9955)),
          }
        : {
            'root': TextStyle(
              backgroundColor: Colors.white,
              color: Colors.black,
            ),
            'keyword': const TextStyle(color: Color(0xFF0000FF)),
            'literal': const TextStyle(color: Color(0xFF0000FF)),
            'symbol': const TextStyle(color: Color(0xFF0000FF)),
            'name': const TextStyle(color: Color(0xFF267F99)),
            'params': const TextStyle(color: Color(0xFF267F99)),
            'string': const TextStyle(color: Color(0xFFA31515)),
            'number': const TextStyle(color: Color(0xFF098658)),
            'title': const TextStyle(color: Color(0xFF795E26)),
            'comment': const TextStyle(color: Color(0xFF008000)),
          };
    
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: GestureDetector(
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        onTapDown: _handleMinimapTap,
        child: Stack(
          children: [
            // 代码小地图
            SingleChildScrollView(
              controller: _internalScrollController,
              physics: const NeverScrollableScrollPhysics(),
              child: Transform.scale(
                scale: 0.5,
                alignment: Alignment.topLeft,
                child: HighlightView(
                  widget.code,
                  language: widget.language,
                  theme: theme,
                  textStyle: const TextStyle(
                    fontSize: 8,
                    height: 1.2,
                  ),
                  padding: const EdgeInsets.all(8.0),
                ),
              ),
            ),
            
            // 当前可视区域指示器
            Positioned(
              top: _viewportPosition,
              left: 0,
              right: 0,
              child: Container(
                height: _viewportHeight,
                decoration: BoxDecoration(
                  color: _isDragging
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: _isDragging
                      ? Icon(
                          Icons.drag_indicator,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 