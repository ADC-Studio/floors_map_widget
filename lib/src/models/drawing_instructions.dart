// ignore_for_file: lines_longer_than_80_chars

import 'dart:ui';

/*
fill: Defines the color or gradient to be used for filling the interior of a shape. For example, fill="#A04D87" sets the fill color to a pinkish hue.

stroke: Defines the color used for the outline or border of a shape. For example, stroke="black" sets the stroke color to black.

stroke-width: Defines the thickness of the stroke. For example, stroke-width="2" sets the stroke thickness to 2 pixels.

stroke-linecap: Defines the shape of the ends of lines. Values can be butt (flat ends), round (rounded ends), or square (square ends).

stroke-linejoin: Defines the shape of corners where lines join. Values can be miter (sharp corner), round (rounded corner), or bevel (beveled corner).

opacity: Defines the transparency of an element. The value ranges from 0 (completely transparent) to 1 (completely opaque).

transform: Applies transformations such as scaling, rotation, translation, and skewing. For example, transform="rotate(45 50 50)" rotates the element by 45 degrees around the point (50, 50).

x and y: Define the position of an element relative to the coordinate system. For example, x="10" and y="20" position the element 10 units to the right and 20 units down from the origin.

width and height: Define the size of an element, such as width and height. These attributes are commonly used for rectangles, images, and other elements with fixed dimensions.

viewBox: Defines the coordinate system and the visible area for elements within the SVG container. For example, viewBox="0 0 100 100" sets the viewable area to coordinates from (0,0) to (100,100).

class: Assigns a CSS class to an element, allowing styles to be applied.
*/

/// Parent class for all Drawing Instructions
final class DrawingInstructions {
  final Size sizeParentSvg;

  final Path clickableArea;

  final Color? colorFill;

  final Color? colorStroke;

  const DrawingInstructions({
    required this.clickableArea,
    required this.sizeParentSvg,
    this.colorFill,
    this.colorStroke,
  });
}
