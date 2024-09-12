import 'dart:async';

import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

class FloorMapWidget extends StatefulWidget {
  final FloorItem item;
  final Future<void> Function()? onTap;
  final Duration duration;
  final Duration durationBlink;
  final bool isActiveBlinking;
  final Color? selectedColor;

  const FloorMapWidget({
    required this.item,
    this.onTap,
    this.duration = const Duration(milliseconds: 50),
    this.durationBlink = const Duration(seconds: 1),
    this.isActiveBlinking = false,
    this.selectedColor,
    super.key,
  });

  @override
  State<FloorMapWidget> createState() => _FloorMapWidgetState();
}

class _FloorMapWidgetState extends State<FloorMapWidget>
    with TickerProviderStateMixin {
  bool _isInsideShape = false;
  // bool _isAnimating = false;
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
    _initializeAnimation();
    // _animationController.addStatusListener((final status) {
    //   if (status == AnimationStatus.completed) {
    //     _isAnimating = true;
    //   } else if (status == AnimationStatus.dismissed) {
    //     _isAnimating = false;
    //   }
    // });
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration:
          widget.isActiveBlinking ? widget.durationBlink : widget.duration,
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.selectedColor ?? Colors.black26,
    ).animate(_animationController);

    if (widget.isActiveBlinking) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant final FloorMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActiveBlinking != oldWidget.isActiveBlinking ||
        widget.durationBlink != oldWidget.durationBlink ||
        widget.selectedColor != oldWidget.selectedColor) {
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      _animationController.dispose();
      _initializeAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => ClipPath(
        clipper: _ShapeClipper(_getPathWithOffset()),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          // onTapUp: (final details) {
          //   _isInsideShape =
          //       _getPathWithOffset().contains(details.localPosition);
          //   if (_isInsideShape) {
          //     //   if (_isAnimating) {
          //     //     // If the animation is running, reverse it only if it's completed
          //     //     _animationController.addStatusListener((status) {
          //     //       if (status == AnimationStatus.completed) {
          //     //         _animationController.reverse();
          //     //       }
          //     //     });
          //     //   } else {
          //     //     _animationController.reverse();
          //     //   }

          //     if (_animationController.isAnimating) {
          //       // Delay the reverse call until the animation completes
          //       Future.delayed(_animationController.duration!, () {
          //         if (_animationController.status == AnimationStatus.forward) {
          //           _animationController.reverse();
          //         }
          //       });
          //     } else {
          //       _animationController.reverse();
          //     }
          //   }
          // },
          onTapDown: (widget.onTap == null)
              ? null
              : (final details) async {
                  unawaited(_animationController.forward());
                  if (widget.onTap != null) {
                    await widget.onTap?.call();
                  }
                  _isInsideShape =
                      _getPathWithOffset().contains(details.localPosition);
                  if (_isInsideShape) {
                    await _animationController.reverse();
                  }
                },
          // onPanUpdate: (final details) {
          //   _isInsideShape =
          //       _getPathWithOffset().contains(details.localPosition);
          //   if (!_isInsideShape) {
          //     _animationController.reverse();
          //   }
          // },
          // onPanEnd: (final _) {
          //   if (_isInsideShape) {
          //     widget.onTap?.call();
          //     _animationController.reverse();
          //   }
          // },
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

class _ShapeClipper extends CustomClipper<Path> {
  final Path path;

  _ShapeClipper(this.path);

  @override
  Path getClip(final Size size) => path;

  @override
  bool shouldReclip(final CustomClipper<Path> oldClipper) => oldClipper != this;
}
