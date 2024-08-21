import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

class FloorMapWidget extends StatefulWidget {
  final FloorItem item;
  final VoidCallback? onTap;
  final Duration duration;

  const FloorMapWidget({
    required this.item,
    this.onTap,
    this.duration = const Duration(milliseconds: 200),
    super.key,
  });

  @override
  State<FloorMapWidget> createState() => _FloorMapWidgetState();
}

class _FloorMapWidgetState extends State<FloorMapWidget>
    with SingleTickerProviderStateMixin {
  bool _isInsideShape = false;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  Path _getPathWithOffset() {
    final size = MediaQuery.of(context).size;
    final double scale =
        (size.width / widget.item.drawingInstructions.sizeParentSvg.width)
            .clamp(
      0,
      size.height / widget.item.drawingInstructions.sizeParentSvg.height,
    );

    final offsetX = (size.width -
            widget.item.drawingInstructions.sizeParentSvg.width * scale) /
        2;
    final offsetY = (size.height -
            widget.item.drawingInstructions.sizeParentSvg.height * scale) /
        2;

    final matrix4 = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale, 1);

    return widget.item.drawingInstructions.clickableArea
        .transform(matrix4.storage);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _colorAnimation = ColorTween(begin: Colors.transparent, end: Colors.black26)
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onPanDown: (final details) {
          _isInsideShape = _getPathWithOffset().contains(details.localPosition);
          if (_isInsideShape) {
            _animationController.forward();
          }
        },
        onTapUp: (final details) {
          _isInsideShape = _getPathWithOffset().contains(details.localPosition);
          if (_isInsideShape) {
            widget.onTap?.call();
            _animationController.reverse();
          }
        },
        onPanUpdate: (final details) {
          _isInsideShape = _getPathWithOffset().contains(details.localPosition);
          if (!_isInsideShape) {
            _animationController.reverse();
          }
        },
        onPanEnd: (final _) {
          if (_isInsideShape) {
            widget.onTap?.call();
            _animationController.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (final context, final child) => CustomPaint(
            painter: _CustomShapePainter(
              _getPathWithOffset(),
              _colorAnimation.value ?? Colors.transparent,
            ),
            child: Container(),
          ),
        ),
      );
}

class _CustomShapePainter extends CustomPainter {
  final Path pathWithOffset;
  final Color color;

  _CustomShapePainter(
    this.pathWithOffset,
    this.color,
  );

  @override
  void paint(final Canvas canvas, final Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(pathWithOffset, paintFill);
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => true;
}
