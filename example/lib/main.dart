import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            SvgPicture.asset(
              'assets/example.svg',
              width: 1093,
              height: 761,
            ),
            // Добавляем область нажатия поверх SVG
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print('Pressed!');
              },
              child: CustomPaint(
                size: const Size(
                  300,
                  300,
                ),
                // child: Container(
                //   color: Colors.green,
                //   width: 300,
                //   height: 300,
                // ),
                painter: PolygonPainter(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PolygonPainter extends CustomPainter {
  @override
  void paint(final Canvas canvas, final Size size) {
    final paintFill = Paint()
      ..color = Color(0xFFA04D87) // Цвет заливки
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = Colors.black // Цвет обводки
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // Толщина обводки

    // Определение пути из SVG
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
      ..close(); // Закрытие контура

    // Отрисовка пути
    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);

    // // Преобразуем размеры в локальные координаты холста
    // final scaleX = size.width / 200.0;
    // final scaleY = size.height / 200.0;
    // final matrix4 = Matrix4.identity()..scale(scaleX, scaleY, 1);
    // path.transform(matrix4.storage);

    // // Можно настроить стиль рисования для отладки
    // final paint = Paint()
    //   ..color = Colors.transparent // Делаем область невидимой
    //   ..style = PaintingStyle.fill;

    // // Рисуем путь на холсте
    // canvas.drawPath(path, paint);

    // // Для отладки можно визуализировать границы пути:
    // final debugPaint = Paint()
    //   ..color = Colors.red.withOpacity(0.5)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 2.0;
    // canvas.drawPath(path, debugPaint);
  }

  @override
  bool shouldRepaint(final CustomPainter oldDelegate) => false;
}
