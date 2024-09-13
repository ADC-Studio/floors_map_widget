import 'dart:ui';

import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

class FloorPathPainter extends StatefulWidget {
  final List<FloorPoint> listPoints;
  const FloorPathPainter(
    this.listPoints, {
    super.key,
  });

  @override
  State<FloorPathPainter> createState() => _FloorPathPainterState();
}

class _FloorPathPainterState extends State<FloorPathPainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5), // Длительность анимации
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          0.7,
        ), // Заполнение белой линии
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.7,
          1,
          curve: Curves.easeOut,
        ), // Исчезновение белой линии
      ),
    );

    _controller.forward().then((final _) {
      _controller.repeat(); // Повторение анимации после завершения
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Path pathBuilder() {
    final Path path = Path()
      ..moveTo(widget.listPoints[0].x, widget.listPoints[0].y);

    for (int i = 1; i < widget.listPoints.length; i++) {
      path.lineTo(widget.listPoints[i].x, widget.listPoints[i].y);
    }
    return path;
  }

  Path _getPathWithOffset() {
    final size = MediaQuery.of(context).size;
    final double scale =
        (size.width / widget.listPoints[0].sizeParentSvg.width).clamp(
      0,
      size.height / widget.listPoints[0].sizeParentSvg.height,
    );

    final offsetX =
        (size.width - widget.listPoints[0].sizeParentSvg.width * scale) / 2;
    final offsetY =
        (size.height - widget.listPoints[0].sizeParentSvg.height * scale) / 2;

    final matrix4 = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale, 1);

    return pathBuilder().transform(matrix4.storage);
  }

  @override
  Widget build(final BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) => CustomPaint(
            painter: _CustomPathPainter(
              _getPathWithOffset(),
              Colors.red,
              _animation.value,
              _fadeAnimation.value,
            ),
            child: Container(),
          ),
        ),
      );
}

class _CustomPathPainter extends CustomPainter {
  final Path pathWithOffset;
  final Color color;
  final double progress;
  final double fadeProgress;

  _CustomPathPainter(
    this.pathWithOffset,
    this.color,
    this.progress,
    this.fadeProgress,
  );

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Рисуем красную линию
    canvas.drawPath(pathWithOffset, paintFill);

    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(
        0.5 * fadeProgress,
      ) // Используем fadeProgress для управления прозрачностью
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final PathMetrics pathMetrics = pathWithOffset.computeMetrics();
    for (final PathMetric pathMetric in pathMetrics) {
      final double length = pathMetric.length;
      final double progressLength = length * progress;

      final Path extractPath = pathMetric.extractPath(0, progressLength);
      canvas.drawPath(extractPath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => true;
}
