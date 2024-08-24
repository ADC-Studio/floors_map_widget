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

class _FloorPathPainterState extends State<FloorPathPainter> {
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

  //! TODO Исправить
  @override
  Widget build(final BuildContext context) => ClipPath(
        clipper: _ShapeClipper(
          _getPathWithOffset(),
        ),
        child: CustomPaint(
          painter: _CustomPathPainter(
            _getPathWithOffset(),
            Colors.red,
          ),
          child: Container(),
        ),
      );
}

class RoutePainter extends CustomPainter {
  final Path path;

  RoutePainter(this.path);

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(final CustomPainter oldDelegate) => true;
}

class _CustomPathPainter extends CustomPainter {
  final Path pathWithOffset;
  final Color color;

  _CustomPathPainter(
    this.pathWithOffset,
    this.color,
  );

  @override
  void paint(final Canvas canvas, final Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(pathWithOffset, paintFill);
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => true;
}

class _ShapeClipper extends CustomClipper<Path> {
  final Path path;

  _ShapeClipper(this.path);

  @override
  Path getClip(final Size size) => path;

  @override
  bool shouldReclip(final CustomClipper<Path> oldClipper) => oldClipper != this;
}
