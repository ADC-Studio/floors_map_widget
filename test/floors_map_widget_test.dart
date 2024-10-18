import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svgTestContent = '''
<svg width="748" height="328" viewBox="0 0 748 328" id="floor-1" xmlns="http://www.w3.org/2000/svg">
    <g id="map_with_points_without_stores 1">
        <g id="Map">
            <g id="Store 1">
                <path id="shop-1=1"
                    d="M179.447 40.6085V89.6045H234.107V65.5325V62.1365H237.515H247.307V45.3005H227.543V3.39648H149.843V37.2005H176.039H179.447V40.6085Z"
                    fill="#EEF9FE" />
            </g>
            <g id="Store 2">
                <path id="shop-2=2"
                    d="M171.447 49.6085V89.6045H234.107V65.5325V62.1365H237.515H247.307V45.3005H227.543V3.39648H149.843V37.2005H176.039H171.447В49.6085З"
                    fill="#EEF9FE" />
            </g>
        </g>
        <g id="Points">
            <path id="point-1=2"
                d="M507.2 196.4C509.519 196.4 511.4 194.52 511.4 192.2C511.4 189.881 509.519 188 507.2 188C504.88 188 503 189.881 503 192.2C503 194.52 504.88 196.4 507.2 196.4Z"
                fill="black" />
            <path id="point-2=2"
                d="M509.2 199.4C509.519 196.4 511.4 194.52 511.4 192.2C511.4 189.881 509.519 188 507.2 188C504.88 188 503 189.881 503 192.2C503 194.52 504.88 196.4 509.2 199.4Z"
                fill="black" />
        </g>
    </g>
</svg>''';

  group('FloorSvgParser Tests', () {
    test('should parse SVG dimensions correctly', () {
      // Create a parser with this SVG content
      final parser = FloorSvgParser(svgContent: svgTestContent);

      // Check that the SVG dimensions are correctly extracted
      expect(parser.svgSize.width, 748);
      expect(parser.svgSize.height, 328);
    });

    test('should extract floor number if not provided', () {
      // Create a parser without providing the floor number
      final parser = FloorSvgParser(svgContent: svgTestContent);

      // Check that the floor number is correctly extracted
      expect(parser.floorNumber, 1);
    });

    test('should handle invalid SVG gracefully', () {
      // Invalid SVG content
      const invalidSvgContent = '<svg>invalid</svg>';

      // Check that an appropriate exception is thrown
      expect(
        () => FloorSvgParser(svgContent: invalidSvgContent),
        throwsA(isA<FloorParserSvgException>()),
      );
    });
  });

  group('FloorMapWidget Tests', () {
    testWidgets('should render SVG content correctly', (final tester) async {
      // Create a FloorMapWidget with the test data
      await tester.pumpWidget(
        const MaterialApp(
          home: FloorMapWidget(
            svgTestContent,
            [],
          ),
        ),
      );

      // Check that an element containing the SVG map is rendered
      expect(find.byType(SvgMap), findsOneWidget);
    });

    testWidgets('should render listItemsWidgets correctly',
        (final tester) async {
      final parser = FloorSvgParser(svgContent: svgTestContent);
      // Create a FloorMapWidget with items
      await tester.pumpWidget(
        MaterialApp(
          home: FloorMapWidget(
            svgTestContent,
            parser
                .getItems()
                .map(
                  FloorItemWidget.new,
                )
                .toList(),
          ),
        ),
      );

      // Wait until all items are rendered
      await tester.pumpAndSettle();

      expect(find.byType(FloorItemWidget), findsWidgets);
    });

    testWidgets('should hide points when unvisiblePoints is true',
        (final tester) async {
      // Create a FloorMapWidget with unvisiblePoints set to true
      await tester.pumpWidget(
        const MaterialApp(
          home: FloorMapWidget(
            svgTestContent,
            [],
            unvisiblePoints: true,
          ),
        ),
      );

      // Check that the points are hidden
      final svgMap = tester.widget<SvgMap>(find.byType(SvgMap));
      expect(svgMap.hidePoints, true);
    });
  });

  group('FloorPathPainter Tests', () {
    testWidgets('should create path with correct points', (final tester) async {
      final parser = FloorSvgParser(svgContent: svgTestContent);
      // Create a FloorPathPainter
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloorPathPainter(
              parser.getPoints(),
            ),
          ),
        ),
      );

      // Check that the widget is created correctly
      expect(find.byType(FloorPathPainter), findsOneWidget);
    });
  });
}
