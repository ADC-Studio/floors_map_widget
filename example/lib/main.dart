import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

final class SvgMap extends StatelessWidget {
  final List<FloorItem> items;

  const SvgMap({
    required this.items,
    super.key,
  });

  @override
  Widget build(final BuildContext context) => Scaffold(
        body: InteractiveViewer(
          child: Center(
            child: Stack(
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/example.svg',
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                  ),
                ),
                ...List.generate(
                  items.length,
                  (final i) => Center(
                    child: FloorMapWidget(
                      item: items[i],
                      onTap: () => print(items[i].key),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

void main() {
  const svgContent = '''
    <?xml version="1.0" encoding="utf-8"?>
    <svg width="1093" height="761" id="floor-1" viewBox="0 0 1093 761" fill="none" xmlns="http://www.w3.org/2000/svg">
<g id="point1@2x 1" clip-path="url(#clip0_223_1869)">
<path id="Vector" d="M1093 0H0V761H1093V0Z" fill="white"/>
<path id="shop-11" d="M649.275 510.299H676.848C679.258 510.299 681.325 508.58 681.764 506.211L687.522 475.168L694.038 439.471H683.839L696.305 366.943H666.274V320.48H607.345V400.941L649.275 431.538V510.299Z" fill="#A04D87" stroke="black"/>
<path id="shop-6" d="M328.283 181.09V89.2973V73.4319H365.964V57.5664H472.489V237.753H433.958V189.023H418.093V181.09H328.283Z" fill="#A04D87" stroke="black"/>
<path id="toilet-male-5" d="M401.094 254.752H472.772V315.947H352.364V272.884H401.094V254.752Z" fill="#7D4080" stroke="black"/>
<path id="stairs-elevator-6" d="M401.094 254.752H472.772V315.947H352.364V272.884H401.094V254.752Z" fill="#7D4080" stroke="black"/>
<circle id="point-1=2" cx="335.5" cy="295.5" r="3.5" fill="black"/>
<circle id="point-2=1-3-4-5" cx="335.5" cy="245.5" r="3.5" fill="black"/>
<circle id="point-3=2-4-5" cx="335.5" cy="193.5" r="3.5" fill="black"/>
<circle id="point-4=2-3-5" cx="386.5" cy="193.5" r="3.5" fill="black"/>
<circle id="point-5=2-3-4" cx="389.5" cy="245.5" r="3.5" fill="black"/>
<circle id="point-6=5-7" cx="441.5" cy="245.5" r="3.5" fill="black"/>
<circle id="point-7=6" cx="484.5" cy="245.5" r="3.5" fill="black"/>
</g>
<defs>
<clipPath id="clip0_223_1869">
<rect width="1093" height="761" fill="white"/>
</clipPath>
</defs>
</svg>

  ''';

  final parser = SvgParser(svgContent: svgContent);
  final list = parser.getItems();

  final listPoints = parser.getPoints();
  runApp(
    MaterialApp(
      home: SvgMap(
        items: list,
      ),
    ),
  );
}
