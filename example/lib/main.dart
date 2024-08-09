// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// void main() {
//   runApp(
//     MaterialApp(
//       home: Scaffold(
//         body: Stack(
//           children: [
//             // SvgPicture.asset(
//             //   'assets/example.svg',
//             //   width: 1093,
//             //   height: 761,
//             // ),
//             // Добавляем область нажатия поверх SVG
//             // GestureDetector(
//             //   behavior: HitTestBehavior.opaque,
//             //   onTap: () {
//             //     print('Pressed!');
//             //   },
//             //   child: CustomPaint(
//             //     size: const Size(
//             //       300,
//             //       300,
//             //     ),
//             //     // child: Container(
//             //     //   color: Colors.green,
//             //     //   width: 300,
//             //     //   height: 300,
//             //     // ),
//             //     painter: PolygonPainter(),
//             //   ),
//             // ),
//             CustomPaint(
//               size: Size(400,
//                   400), // Убедитесь, что размер холста достаточен для отображения
//               painter: SVGPathCustomPainter(),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// class PolygonPainter extends CustomPainter {
//   @override
//   void paint(final Canvas canvas, final Size size) {
//     final paintFill = Paint()
//       ..color = Color(0xFFA04D87) // Цвет заливки
//       ..style = PaintingStyle.fill;

//     final paintStroke = Paint()
//       ..color = Colors.black // Цвет обводки
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0; // Толщина обводки

//     // Определение пути из SVG
//     final path = Path()
//       ..moveTo(328.283, 181.09)
//       ..lineTo(328.283, 89.2973)
//       ..lineTo(328.283, 73.4319)
//       ..lineTo(365.964, 73.4319)
//       ..lineTo(365.964, 57.5664)
//       ..lineTo(472.489, 57.5664)
//       ..lineTo(472.489, 237.753)
//       ..lineTo(433.958, 237.753)
//       ..lineTo(433.958, 189.023)
//       ..lineTo(418.093, 189.023)
//       ..lineTo(418.093, 181.09)
//       ..close(); // Закрытие контура

//     // Отрисовка пути
//     canvas.drawPath(path, paintFill);
//     canvas.drawPath(path, paintStroke);

//     // // Преобразуем размеры в локальные координаты холста
//     // final scaleX = size.width / 200.0;
//     // final scaleY = size.height / 200.0;
//     // final matrix4 = Matrix4.identity()..scale(scaleX, scaleY, 1);
//     // path.transform(matrix4.storage);

//     // // Можно настроить стиль рисования для отладки
//     // final paint = Paint()
//     //   ..color = Colors.transparent // Делаем область невидимой
//     //   ..style = PaintingStyle.fill;

//     // // Рисуем путь на холсте
//     // canvas.drawPath(path, paint);

//     // // Для отладки можно визуализировать границы пути:
//     // final debugPaint = Paint()
//     //   ..color = Colors.red.withOpacity(0.5)
//     //   ..style = PaintingStyle.stroke
//     //   ..strokeWidth = 2.0;
//     // canvas.drawPath(path, debugPaint);
//   }

//   @override
//   bool shouldRepaint(final CustomPainter oldDelegate) => false;
// }

// class PolygonTouchHandler extends StatelessWidget {
//   final Widget child;
//   final VoidCallback onTap;

//   PolygonTouchHandler({required this.child, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final path = Path()
//           ..moveTo(328.283, 181.09)
//           ..lineTo(328.283, 89.2973)
//           ..lineTo(328.283, 73.4319)
//           ..lineTo(365.964, 73.4319)
//           ..lineTo(365.964, 57.5664)
//           ..lineTo(472.489, 57.5664)
//           ..lineTo(472.489, 237.753)
//           ..lineTo(433.958, 237.753)
//           ..lineTo(433.958, 189.023)
//           ..lineTo(418.093, 189.023)
//           ..lineTo(418.093, 181.09)
//           ..close();

//         return GestureDetector(
//           onTap: onTap,
//           behavior: HitTestBehavior.translucent,
//           child: CustomPaint(
//             size: Size(constraints.maxWidth, constraints.maxHeight),
//             painter: SVGPathCustomPainter(),
//             child: Builder(
//               builder: (context) {
//                 final size = MediaQuery.of(context).size;
//                 final offset = Offset(
//                     0, 0); // Возможно, вам нужно будет настроить смещение

//                 return GestureDetector(
//                   onTapUp: (details) {
//                     final localPosition = details.localPosition;
//                     if (path.contains(
//                         localPosition.translate(-offset.dx, -offset.dy))) {
//                       onTap();
//                     }
//                   },
//                   child: Container(
//                     width: size.width,
//                     height: size.height,
//                     color: Colors.transparent,
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class SVGPathCustomPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Color(0xFF010101) // Цвет, указанный в SVG
//       ..style = PaintingStyle.fill;

//     // Определите размер и расположение обрезки
//     final clipRect = Rect.fromLTWH(602.812, 643.456, 11.3325, 11.3325);
//     final clipPath = Path()..addRect(clipRect);

//     // Создание пути для SVG
//     final path = Path()
//       ..moveTo(399.24, 348.502)
//       ..lineTo(398.341, 348.502)
//       ..lineTo(398.341, 341.685)
//       ..lineTo(399.24, 341.685)
//       ..close()
//       ..moveTo(394.141, 348.502)
//       ..lineTo(391.369, 348.502)
//       ..lineTo(391.369, 342.488)
//       ..lineTo(394.141, 342.488)
//       ..close()
//       ..moveTo(397.221, 348.502)
//       ..lineTo(394.449, 348.502)
//       ..lineTo(394.449, 342.488)
//       ..lineTo(397.221, 342.488)
//       ..close()
//       ..moveTo(398.032, 348.502)
//       ..lineTo(397.53, 348.502)
//       ..lineTo(397.53, 342.333)
//       ..lineTo(398.032, 342.333)
//       ..lineTo(398.032, 348.502)
//       ..close();

//     // Применение обрезки
//     canvas.clipPath(clipPath);

//     // Отрисовка пути
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PolygonPainter extends StatelessWidget {
  const PolygonPainter({super.key});

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Polygon Painter Example'),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/example.svg',
                  // width: 1093,
                  // height: 761,
                ),
                PolygonTouchHandler(
                  onTap: () {
                    if (kDebugMode) {
                      print('Polygon tapped!');
                    }
                  },
                  child: CustomPaint(
                    painter: SVGPathCustomPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class SVGPathCustomPainter extends CustomPainter {
  final Path path;

  SVGPathCustomPainter()
      : path = Path()
          ..moveTo(328.283, 181.09)
          ..lineTo(328.283, 89.2973)
          ..lineTo(328.283, 73.4319)
          ..lineTo(365.964, 73.4319)
          ..lineTo(365.964, 57.5664)
          ..lineTo(472.489, 57.5664)
          ..lineTo(472.489, 237.753)
          ..lineTo(433.958, 237.753)
          ..lineTo(433.958, 189.023)
          ..lineTo(418.093, 189.023)
          ..lineTo(418.093, 181.09)
          ..close(); // Закрытие контура

  @override
  void paint(final Canvas canvas, final Size size) {
    final paintFill = Paint()
      ..color = const Color(0xFFA04D87) // Цвет заливки
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = Colors.black // Цвет обводки
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // Толщина обводки

    // Отрисовка пути
    canvas
      ..drawPath(path, paintFill)
      ..drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(final CustomPainter oldDelegate) => false;
}

class PolygonTouchHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const PolygonTouchHandler({
    required this.child,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final path = Path()
            ..moveTo(328.283, 181.09)
            ..lineTo(328.283, 89.2973)
            ..lineTo(328.283, 73.4319)
            ..lineTo(365.964, 73.4319)
            ..lineTo(365.964, 57.5664)
            ..lineTo(472.489, 57.5664)
            ..lineTo(472.489, 237.753)
            ..lineTo(433.958, 237.753)
            ..lineTo(433.958, 189.023)
            ..lineTo(418.093, 189.023)
            ..lineTo(418.093, 181.09)
            ..close();

          return GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.translucent,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: SVGPathCustomPainter(),
              child: Builder(
                builder: (final context) {
                  final size = MediaQuery.of(context).size;
                  const offset = Offset.zero;

                  return GestureDetector(
                    onTapUp: (final details) {
                      final localPosition = details.localPosition;
                      if (path.contains(
                        localPosition.translate(-offset.dx, -offset.dy),
                      )) {
                        onTap();
                      }
                    },
                    child: Container(
                      width: size.width,
                      height: size.height,
                      color: Colors.transparent,
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
}

void main() {
  runApp(
    const MaterialApp(
      home: PolygonPainter(),
    ),
  );
}
