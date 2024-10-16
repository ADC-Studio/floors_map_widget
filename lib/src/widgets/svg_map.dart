import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class SvgMap extends StatefulWidget {
  final String svgContent;
  final bool hidePoints;
  final Size? sizeMap;

  const SvgMap(
    this.svgContent, {
    this.sizeMap,
    this.hidePoints = false,
    super.key,
  });

  @override
  State<SvgMap> createState() => _SvgMapState();
}

class _SvgMapState extends State<SvgMap> {
  late String svgContent;

  @override
  void initState() {
    super.initState();
    svgContent = widget.hidePoints ? cleanPointsFromMap() : widget.svgContent;
  }

  /// Removes elements with an 'id' containing 'point' from the SVG content.
  String cleanPointsFromMap() {
    final document = XmlDocument.parse(widget.svgContent);
    final regex = RegExp(r'\bpoint[-=]', caseSensitive: false);
    // Find all elements whose 'id' attribute contains 'point'.
    final elementsToRemove =
        document.findAllElements('*').where((final element) {
      final String? id = element.getAttribute('id');
      return id != null && regex.hasMatch(id);
    }).toList();

    // Remove each element from its parent.
    for (final element in elementsToRemove) {
      element.parent?.children.remove(element);
    }

    return document.toXmlString(pretty: true);
  }

  @override
  Widget build(final BuildContext context) {
    final svgContent =
        widget.hidePoints ? cleanPointsFromMap() : widget.svgContent;

    return Center(
      child: SvgPicture.string(
        svgContent,
        width: widget.sizeMap?.width,
        height: widget.sizeMap?.height,
      ),
    );
  }
}
