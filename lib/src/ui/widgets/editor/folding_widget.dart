import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/editor/folding_service.dart';

/// 代码折叠小部件
class FoldingWidget extends ConsumerStatefulWidget {
  final String text;
  final String? fileType;
  final String? filePath;
  final double lineHeight;
  final ScrollController scrollController;
  final Function(int startLine, int endLine, bool isCollapsed) onFoldingChanged;
  
  const FoldingWidget({
    super.key,
    required this.text,
    this.fileType,
    this.filePath,
    required this.lineHeight,
    required this.scrollController,
    required this.onFoldingChanged,
  });
  
  @override
  ConsumerState<FoldingWidget> createState() => _FoldingWidgetState();
}

class _FoldingWidgetState extends ConsumerState<FoldingWidget> {
  late List<FoldingRegion> _regions;
  double _scrollOffset = 0;
  
  @override
  void initState() {
    super.initState();
    _updateFoldingRegions();
    widget.scrollController.addListener(_updateScrollOffset);
  }
  
  @override
  void dispose() {
    if (widget.scrollController.hasClients) {
      widget.scrollController.removeListener(_updateScrollOffset);
    } else {
      widget.scrollController.removeListener(_updateScrollOffset);
    }
    super.dispose();
  }
  
  void _updateScrollOffset() {
    if (mounted && widget.scrollController.hasClients) {
      final newOffset = widget.scrollController.offset;
      if ((newOffset - _scrollOffset).abs() > 0.1) {
        setState(() {
          _scrollOffset = newOffset;
        });
      }
    }
  }
  
  @override
  void didUpdateWidget(FoldingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _updateFoldingRegions();
    }
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController.removeListener(_updateScrollOffset);
      widget.scrollController.addListener(_updateScrollOffset);
    }
  }
  
  void _updateFoldingRegions() {
    final foldingService = ref.read(foldingServiceProvider);
    _regions = foldingService.getFoldingRegions(
      widget.text,
      fileType: widget.fileType,
      filePath: widget.filePath,
    );
  }
  
  void _toggleFolding(FoldingRegion region) {
    final foldingService = ref.read(foldingServiceProvider);
    setState(() {
      foldingService.toggleFolding(region, widget.text, widget.filePath);
      widget.onFoldingChanged(
        region.startLine,
        region.endLine,
        region.isCollapsed,
      );
    });
  }
  
  void _expandAll() {
    final foldingService = ref.read(foldingServiceProvider);
    setState(() {
      foldingService.expandAll(_regions, widget.filePath);
      for (final region in _regions.where((r) => r.isCollapsed)) {
        widget.onFoldingChanged(
          region.startLine,
          region.endLine,
          false,
        );
      }
    });
  }
  
  void _collapseAll() {
    final foldingService = ref.read(foldingServiceProvider);
    setState(() {
      foldingService.collapseAll(_regions, widget.text, widget.filePath);
      for (final region in _regions.where((r) => !r.isCollapsed)) {
        widget.onFoldingChanged(
          region.startLine,
          region.endLine,
          true,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: _FoldingPainter(
            regions: _regions,
            lineHeight: widget.lineHeight,
            scrollOffset: _scrollOffset,
          ),
          child: GestureDetector(
            onTapUp: (details) {
              final y = details.localPosition.dy + _scrollOffset;
              final line = (y / widget.lineHeight).floor();
              
              for (final region in _regions) {
                if (region.startLine == line) {
                  _toggleFolding(region);
                  break;
                }
              }
            },
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.unfold_less, size: 16),
                onPressed: _collapseAll,
                tooltip: '全部折叠',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.unfold_more, size: 16),
                onPressed: _expandAll,
                tooltip: '全部展开',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 折叠指示器绘制器
class _FoldingPainter extends CustomPainter {
  final List<FoldingRegion> regions;
  final double lineHeight;
  final double scrollOffset;
  
  _FoldingPainter({
    required this.regions,
    required this.lineHeight,
    required this.scrollOffset,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (final region in regions) {
      final startY = region.startLine * lineHeight - scrollOffset;
      final endY = region.endLine * lineHeight - scrollOffset;
      
      // 绘制折叠指示器
      if (startY >= 0 && startY <= size.height) {
        final rect = Rect.fromLTWH(0, startY, 10, 10);
        canvas.drawRect(rect, paint);
        
        // 绘制加号或减号
        if (region.isCollapsed) {
          canvas.drawLine(
            Offset(2, startY + 5),
            Offset(8, startY + 5),
            paint,
          );
          canvas.drawLine(
            Offset(5, startY + 2),
            Offset(5, startY + 8),
            paint,
          );
        } else {
          canvas.drawLine(
            Offset(2, startY + 5),
            Offset(8, startY + 5),
            paint,
          );
        }
      }
      
      // 绘制垂直线
      if (!region.isCollapsed && startY < size.height && endY > 0) {
        canvas.drawLine(
          Offset(5, startY + 10),
          Offset(5, endY),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _FoldingPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.lineHeight != lineHeight ||
        (oldDelegate.scrollOffset - scrollOffset).abs() > 0.1;
  }
} 