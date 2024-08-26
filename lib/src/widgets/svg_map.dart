import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class SvgMap extends StatefulWidget {
  final String svgContent;
  const SvgMap(
    this.svgContent, {
    super.key,
  });

  @override
  State<SvgMap> createState() => _SvgMapState();
}

class _SvgMapState extends State<SvgMap> {
  String cleanPointFromMap() {
    final document = XmlDocument.parse(widget.svgContent);
    final svg = document.findElements('svg').first;

    // Рекурсивная функция для удаления элементов с id, содержащим 'point'
    void removeElementsWithPoint(final XmlElement element) {
      // Удаляем все дочерние элементы, если их id содержит 'point'
      element.children.removeWhere((final node) {
        if (node is XmlElement) {
          final id = node.getAttribute('id');
          return id != null && id.contains('point');
        }
        return false;
      });

      // Рекурсивно обрабатываем дочерние элементы
      element.children.whereType<XmlElement>().forEach(removeElementsWithPoint);
    }

    // Запускаем удаление
    removeElementsWithPoint(svg);

    return document.toXmlString(pretty: true);
  }

  @override
  Widget build(final BuildContext context) => Center(
        child: SvgPicture.string(
          // cleanPointFromMap(),
          widget.svgContent,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        ),
      );
}
