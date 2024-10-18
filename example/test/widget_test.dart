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
                    d="M171.447 49.6085V89.6045H234.107V65.5325V62.1365H237.515H247.307V45.3005H227.543V3.39648H149.843V37.2005H176.039H171.447V49.6085Z"
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
  testWidgets('should render SVG content correctly', (final tester) async {
    // Создаем FloorMapWidget с тестовыми данными
    await tester.pumpWidget(
      const MaterialApp(
        home: FloorMapWidget(
          svgTestContent,
          [],
        ),
      ),
    );

    // Проверяем, что отображается элемент, содержащий SVG карту
    expect(find.byType(SvgMap), findsOneWidget);
  });
}
