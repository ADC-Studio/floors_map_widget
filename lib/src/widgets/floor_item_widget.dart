import 'dart:async';
import 'dart:math' as math;

import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

class FloorItemWidget extends StatefulWidget {
  /// An interactive object on the map.
  final FloorItem item;

  /// Function to be called when the item is tapped.
  final Future<void> Function(FloorItem floorItem)? onTap;

  /// Duration for the tap animation.
  final Duration durationTapAnimation;

  /// Duration for the blinking animation.
  final Duration durationBlink;

  /// Indicates if the item should blink.
  final bool isActiveBlinking;

  /// Color to highlight the item when activated.
  final Color? selectedColor;

  /// Parent size; automatically set if null.
  final Size? parentSize;

  /// Creates an interactive floor item widget.
  const FloorItemWidget({
    required this.item,
    this.onTap,
    this.durationTapAnimation = const Duration(milliseconds: 50),
    this.durationBlink = const Duration(seconds: 1),
    this.isActiveBlinking = false,
    this.selectedColor,
    this.parentSize,
    super.key,
  });

  /// Returns a copy of this widget with updated properties.
  FloorItemWidget copyWith({
    final FloorItem? item,
    final Future<void> Function(FloorItem floorItem)? onTap,
    final Duration? durationTapAnimation,
    final Duration? durationBlink,
    final bool? isActiveBlinking,
    final Color? selectedColor,
    final Size? parentSize,
  }) =>
      FloorItemWidget(
        item: item ?? this.item,
        onTap: onTap ?? this.onTap,
        durationTapAnimation: durationTapAnimation ?? this.durationTapAnimation,
        durationBlink: durationBlink ?? this.durationBlink,
        isActiveBlinking: isActiveBlinking ?? this.isActiveBlinking,
        selectedColor: selectedColor ?? this.selectedColor,
        parentSize: parentSize ?? this.parentSize,
      );

  @override
  State<FloorItemWidget> createState() => _FloorItemWidgetState();
}

/// State class for FloorItemWidget, handling animations and interactions.
/// Uses TickerProviderStateMixin instead of SingleTickerProviderStateMixin
/// because the animation controller may not have time to free up memory when
/// the widget is rebuilt.
class _FloorItemWidgetState extends State<FloorItemWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Path pathWithOffset;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _isBlinking = widget.isActiveBlinking;
    _initAnimationController();
    _initPathWithOffset(widget.item.drawingInstructions);
  }

  /// Initializes the animation controller and color animation.
  void _initAnimationController() {
    _animationController = AnimationController(
      duration:
          _isBlinking ? widget.durationBlink : widget.durationTapAnimation,
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.selectedColor ?? Colors.black26,
    ).animate(_animationController);

    if (_isBlinking) {
      _animationController.repeat(reverse: true);
    }
  }

  /// Calculates the path with the necessary
  /// offset and scale to center the widget.
  void _initPathWithOffset(final DrawingInstructions instr) {
    final size = widget.parentSize ?? MediaQuery.of(context).size;
    final double scale = math.min(
      size.width / instr.sizeParentSvg.width,
      size.height / instr.sizeParentSvg.height,
    );

    final offsetX = (size.width - instr.sizeParentSvg.width * scale) / 2;
    final offsetY = (size.height - instr.sizeParentSvg.height * scale) / 2;

    final matrix4 = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale, 1);

    pathWithOffset = instr.clickableArea.transform(matrix4.storage);
  }

  @override
  void didUpdateWidget(covariant final FloorItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update blinking state and animation when the widget properties change.
    if (widget.isActiveBlinking != oldWidget.isActiveBlinking ||
        widget.durationBlink != oldWidget.durationBlink ||
        widget.selectedColor != oldWidget.selectedColor) {
      _isBlinking = widget.isActiveBlinking;

      // Update the controller's duration.
      _animationController.duration =
          _isBlinking ? widget.durationBlink : widget.durationTapAnimation;

      if (_isBlinking) {
        // Start blinking animation.
        _animationController.repeat(reverse: true);
      } else {
        // Stop blinking animation.
        _animationController
          ..stop()
          ..reset();
      }
    }

    _initPathWithOffset(widget.item.drawingInstructions);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handles the tap event and manages the animations.
  Future<void> _handleTap() async {
    if (_isBlinking) {
      // Temporarily stop blinking.
      _animationController
        ..stop()
        ..reset();
    }

    // Set duration for tap animation.
    _animationController.duration = widget.durationTapAnimation;

    // Start tap animation.
    await _animationController.forward();
    if (widget.onTap != null) {
      await widget.onTap!(widget.item);
    }
    await _animationController.reverse();

    // Resume blinking if it was active.
    if (_isBlinking) {
      _animationController
        ..duration = widget.durationBlink
        ..repeat(reverse: true);
    } else {
      _animationController.reset();
    }
  }

  @override
  Widget build(final BuildContext context) => ClipPath(
        clipper: _ShapeClipper(pathWithOffset),
        child: GestureDetector(
          // Supports InteractiveViewer and more.
          behavior: HitTestBehavior.translucent,
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (final context, final child) => CustomPaint(
              painter: _CustomShapePainter(
                pathWithOffset,
                _colorAnimation.value ?? Colors.transparent,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}

/// Custom painter that draws a shape with the required color and size.
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
  bool shouldRepaint(covariant final _CustomShapePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.pathWithOffset != pathWithOffset;
}

/// Clipper that allocates the required size to the shape.
class _ShapeClipper extends CustomClipper<Path> {
  final Path path;

  _ShapeClipper(this.path);

  @override
  Path getClip(final Size size) => path;

  @override
  bool shouldReclip(covariant final _ShapeClipper oldClipper) =>
      oldClipper.path != path;
}
