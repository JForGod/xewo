import 'package:flutter/material.dart';
import 'editor_core.dart';

class VirtualScrollEditor extends StatefulWidget {
  final String initialText;
  final double lineHeight;
  final int visibleLines;
  final Function(String)? onChanged;

  const VirtualScrollEditor({
    Key? key,
    this.initialText = '',
    this.lineHeight = 20.0,
    this.visibleLines = 30,
    this.onChanged,
  }) : super(key: key);

  @override
  State<VirtualScrollEditor> createState() => _VirtualScrollEditorState();
}

class _VirtualScrollEditorState extends State<VirtualScrollEditor> {
  late ScrollController _scrollController;
  late List<String> _lines;
  int _startIndex = 0;
  int _endIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lines = widget.initialText.split('\n');
    _updateVisibleRange();

    _scrollController.addListener(_handleScroll);
  }

  void _updateVisibleRange() {
    final double scrollOffset = _scrollController.offset;
    _startIndex = (scrollOffset / widget.lineHeight).floor();
    _endIndex = _startIndex + widget.visibleLines;
    
    // 确保不超出边界
    _startIndex = _startIndex.clamp(0, _lines.length - 1);
    _endIndex = _endIndex.clamp(0, _lines.length);

    setState(() {});
  }

  void _handleScroll() {
    _updateVisibleRange();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalHeight = _lines.length * widget.lineHeight;
        final visibleLines = _lines.sublist(_startIndex, _endIndex);

        return SizedBox(
          height: constraints.maxHeight,
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                itemCount: visibleLines.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: widget.lineHeight,
                    child: Text(
                      visibleLines[index],
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
              // 滚动条指示器
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  color: Colors.grey[300],
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      final double delta = details.delta.dy;
                      final double maxScroll = _scrollController.position.maxScrollExtent;
                      final double scrollRatio = delta / constraints.maxHeight;
                      _scrollController.jumpTo(
                        (_scrollController.offset + (maxScroll * scrollRatio))
                            .clamp(0.0, maxScroll),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        top: (_startIndex / _lines.length) * constraints.maxHeight,
                        bottom: (1 - _endIndex / _lines.length) * constraints.maxHeight,
                      ),
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      _scrollController.removeListener(_handleScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }
} 