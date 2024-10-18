import 'dart:math' as math;
import 'dart:ui';
import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

class FloorPathPainter extends StatefulWidget {
  final List<FloorPoint> listPoints;

  // The available space that the widget can occupy.
  // Necessary for miscalculations
  final Size? parentSize;

  /// Creates a [FloorPathPainter] widget that animates
  /// a path along given points.
  const FloorPathPainter(
    this.listPoints, {
    this.parentSize,
    super.key,
  });

  @override
  State<FloorPathPainter> createState() => _FloorPathPainterState();
}

class _FloorPathPainterState extends State<FloorPathPainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with a duration of 5 seconds.
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // Animation that controls the progress of the white line along the path.
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          0.7, // First 70% of the animation time.
        ),
      ),
    );

    // Animation that controls the fade-out effect of the white line.
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.7,
          1, // Last 30% of the animation time.
          curve: Curves.easeOut,
        ),
      ),
    );

    // Start the animation and repeat it indefinitely.
    _controller.forward().then((final _) {
      _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the path from the list of points.
  Path _buildPath() {
    final Path path = Path()
      ..moveTo(widget.listPoints[0].x, widget.listPoints[0].y);

    for (int i = 1; i < widget.listPoints.length; i++) {
      path.lineTo(widget.listPoints[i].x, widget.listPoints[i].y);
    }
    return path;
  }

  /// Transforms the path to fit within the current context size,
  ///  maintaining aspect ratio.
  Path _getPathWithOffset(final BuildContext context) {
    final size = widget.parentSize ?? MediaQuery.of(context).size;
    final svgSize = widget.listPoints[0].sizeParentSvg;

    // Calculate the scale to fit the path within the screen while
    // maintaining aspect ratio.
    final double scale = math.min(
      size.width / svgSize.width,
      size.height / svgSize.height,
    );

    // Calculate the offsets to center the path.
    final offsetX = (size.width - svgSize.width * scale) / 2;
    final offsetY = (size.height - svgSize.height * scale) / 2;

    // Create a transformation matrix.
    final matrix4 = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale);

    // Apply the transformation to the path.
    return _buildPath().transform(matrix4.storage);
  }

  @override
  Widget build(final BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) => CustomPaint(
            painter: _CustomPathPainter(
              pathWithOffset: _getPathWithOffset(context),
              color: Colors.red,
              progress: _progressAnimation.value,
              fadeProgress: _fadeAnimation.value,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

class _CustomPathPainter extends CustomPainter {
  final Path pathWithOffset;
  final Color color;
  final double progress;
  final double fadeProgress;

  _CustomPathPainter({
    required this.pathWithOffset,
    required this.color,
    required this.progress,
    required this.fadeProgress,
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw the red path line.
    canvas.drawPath(pathWithOffset, paintFill);

    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5 * fadeProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Animate the white line along the path.
    final PathMetrics pathMetrics = pathWithOffset.computeMetrics();
    for (final PathMetric pathMetric in pathMetrics) {
      final double length = pathMetric.length;
      final double progressLength = length * progress;

      final Path extractPath = pathMetric.extractPath(0, progressLength);
      canvas.drawPath(extractPath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant final _CustomPathPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.fadeProgress != fadeProgress ||
      oldDelegate.pathWithOffset != pathWithOffset ||
      oldDelegate.color != color;
}
