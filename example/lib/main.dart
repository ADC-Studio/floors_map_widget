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
<circle id="point-5=2-3-4-6" cx="389.5" cy="245.5" r="3.5" fill="black"/>
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

  print(
    PathBuilder(
      startId: listPoints[1].id,
      endId: listPoints[6].id,
      coords: listPoints,
    ).findShortestPath(),
  );
  print(
    PathBuilder(
      startId: listPoints[6].id,
      endId: listPoints[1].id,
      coords: listPoints,
    ).findShortestPath(),
  );
  // print(PathBuilder(startId: 6, endId: 3, coords: [
  //   FloorPoint(id: 1, x: 335.5, y: 295.5, neighbours: [2], floor: 1),
  //   FloorPoint(
  //       id: 2, x: 335.5, y: 245.5, neighbours: [1, 3, 4, 5], floor: 1), // 1
  //   FloorPoint(id: 3, x: 335.5, y: 193.5, neighbours: [2, 4, 5], floor: 1),
  //   FloorPoint(id: 4, x: 386.5, y: 193.5, neighbours: [2, 3, 5], floor: 1),
  //   FloorPoint(id: 5, x: 389.5, y: 245.5, neighbours: [2, 3, 4], floor: 1),
  //   FloorPoint(id: 6, x: 441.5, y: 245.5, neighbours: [5, 7], floor: 1), // 5
  //   FloorPoint(id: 7, x: 484.5, y: 245.5, neighbours: [6], floor: 1),
  // ]).findShortestPath());
  print(PathBuilder(startId: 0, endId: 16, coords: [
    FloorPoint(floor: 1, id: 0, x: 333.9, y: 432.4, neighbours: [1, 2]),
    FloorPoint(floor: 1, id: 1, x: 333.4, y: 344, neighbours: [0, 2, 3]),
    FloorPoint(floor: 1, id: 2, x: 370.5, y: 343.3, neighbours: [0, 1, 3]),
    FloorPoint(floor: 1, id: 3, x: 332.5, y: 303.8, neighbours: [1, 2, 4]),
    FloorPoint(floor: 1, id: 4, x: 332.6, y: 242.4, neighbours: [3, 5, 6]),
    FloorPoint(floor: 1, id: 5, x: 356.2, y: 206.3, neighbours: [4, 6]),
    FloorPoint(floor: 1, id: 6, x: 416.4, y: 242.2, neighbours: [4, 5, 7]),
    FloorPoint(floor: 1, id: 7, x: 481.9, y: 242.7, neighbours: [6, 8, 12, 16]),
    FloorPoint(floor: 1, id: 8, x: 481.8, y: 160.1, neighbours: [7, 9]),
    FloorPoint(floor: 1, id: 9, x: 483.1, y: 68, neighbours: [8, 10]),
    FloorPoint(floor: 1, id: 10, x: 585.6, y: 67.6, neighbours: [9, 11]),
    FloorPoint(floor: 1, id: 11, x: 585.8, y: 153.7, neighbours: [10, 12]),
    FloorPoint(floor: 1, id: 12, x: 583.3, y: 242, neighbours: [7, 11, 13]),
    FloorPoint(floor: 1, id: 13, x: 583.9, y: 321.1, neighbours: [12, 14]),
    FloorPoint(floor: 1, id: 14, x: 586.2, y: 398, neighbours: [13, 15]),
    FloorPoint(floor: 1, id: 15, x: 484.8, y: 400.5, neighbours: [14, 16]),
    FloorPoint(floor: 1, id: 16, x: 479.9, y: 318, neighbours: [7, 15]),
  ]).findShortestPath());
  print(PathBuilder(startId: 16, endId: 0, coords: [
    FloorPoint(floor: 1, id: 0, x: 333.9, y: 432.4, neighbours: [1, 2]),
    FloorPoint(floor: 1, id: 1, x: 333.4, y: 344, neighbours: [0, 2, 3]),
    FloorPoint(floor: 1, id: 2, x: 370.5, y: 343.3, neighbours: [0, 1, 3]),
    FloorPoint(floor: 1, id: 3, x: 332.5, y: 303.8, neighbours: [1, 2, 4]),
    FloorPoint(floor: 1, id: 4, x: 332.6, y: 242.4, neighbours: [3, 5, 6]),
    FloorPoint(floor: 1, id: 5, x: 356.2, y: 206.3, neighbours: [4, 6]),
    FloorPoint(floor: 1, id: 6, x: 416.4, y: 242.2, neighbours: [4, 5, 7]),
    FloorPoint(floor: 1, id: 7, x: 481.9, y: 242.7, neighbours: [6, 8, 12, 16]),
    FloorPoint(floor: 1, id: 8, x: 481.8, y: 160.1, neighbours: [7, 9]),
    FloorPoint(floor: 1, id: 9, x: 483.1, y: 68, neighbours: [8, 10]),
    FloorPoint(floor: 1, id: 10, x: 585.6, y: 67.6, neighbours: [9, 11]),
    FloorPoint(floor: 1, id: 11, x: 585.8, y: 153.7, neighbours: [10, 12]),
    FloorPoint(floor: 1, id: 12, x: 583.3, y: 242, neighbours: [7, 11, 13]),
    FloorPoint(floor: 1, id: 13, x: 583.9, y: 321.1, neighbours: [12, 14]),
    FloorPoint(floor: 1, id: 14, x: 586.2, y: 398, neighbours: [13, 15]),
    FloorPoint(floor: 1, id: 15, x: 484.8, y: 400.5, neighbours: [14, 16]),
    FloorPoint(floor: 1, id: 16, x: 479.9, y: 318, neighbours: [7, 15]),
  ]).findShortestPath());
  runApp(
    MaterialApp(
      home: SvgMap(
        items: list,
      ),
    ),
  );
}
