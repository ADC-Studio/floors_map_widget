import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final class SvgMapExample extends StatelessWidget {
  final String svgContent;
  final List<FloorItem> items;
  final List<FloorPoint> points;

  const SvgMapExample({
    required this.svgContent,
    required this.items,
    required this.points,
    super.key,
  });

  @override
  Widget build(final BuildContext context) => Scaffold(
        body: InteractiveViewer(
          child: Center(
            child: Stack(
              children: [
                SvgMap(svgContent),
                ...List.generate(
                  items.length,
                  (final i) => Center(
                    child: FloorMapWidget(
                      item: items[i],
                      onTap: () async => print(items[i].idPoint),
                    ),
                  ),
                ),
                Center(
                  child: FloorPathPainter(
                    PathBuilder(
                      startId: 30,
                      endId: 2,
                      coords: points,
                    ).findShortestPath()['points'] as List<FloorPoint>,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

void main() async {
  //! TODO ВЫНЕСТИ В ФАЙЛ ПЕРЕД ПУБЛИКАЦИЕЙ
  WidgetsFlutterBinding.ensureInitialized();
  final svgContent = await rootBundle.loadString('assets/example.svg');
  final parser = SvgParser(svgContent: svgContent);
  final list = parser.getItems();
  final listPoints = parser.getPoints();
  final parser2 = SvgParser(svgContent: svgContent);
  // final Iterable<FloorStairs> stairs = list.whereType<FloorStairs>();
  // print(
  //   PathBuilder(
  //     startId: listPoints[1].id,
  //     endId: getNearestStair(listPoints[1].id, stairs, listPoints).idPoint!,
  //     coords: listPoints,
  //   ),
  // );

  // print(
  //   PathBuilder(
  //     startId: listPoints[1].id,
  //     endId: listPoints[6].id,
  //     coords: listPoints,
  //   ).findShortestPath(),
  // );
  // print(
  //   PathBuilder(
  //     startId: 33,
  //     endId: 42,
  //     coords: listPoints,
  //   ).findShortestPath(),
  // );
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
  // print(
  //   const PathBuilder(
  //     startId: 0,
  //     endId: 16,
  //     coords: [
  //       FloorPoint(floor: 1, id: 0, x: 333.9, y: 432.4, neighbours: [1, 2]),
  //       FloorPoint(floor: 1, id: 1, x: 333.4, y: 344, neighbours: [0, 2, 3]),
  //       FloorPoint(floor: 1, id: 2, x: 370.5, y: 343.3, neighbours: [0, 1, 3]),
  //       FloorPoint(floor: 1, id: 3, x: 332.5, y: 303.8, neighbours: [1, 2, 4]),
  //       FloorPoint(floor: 1, id: 4, x: 332.6, y: 242.4, neighbours: [3, 5, 6]),
  //       FloorPoint(floor: 1, id: 5, x: 356.2, y: 206.3, neighbours: [4, 6]),
  //       FloorPoint(floor: 1, id: 6, x: 416.4, y: 242.2, neighbours: [4, 5, 7]),
  //       FloorPoint(
  //         floor: 1,
  //         id: 7,
  //         x: 481.9,
  //         y: 242.7,
  //         neighbours: [6, 8, 12, 16],
  //       ),
  //       FloorPoint(floor: 1, id: 8, x: 481.8, y: 160.1, neighbours: [7, 9]),
  //       FloorPoint(floor: 1, id: 9, x: 483.1, y: 68, neighbours: [8, 10]),
  //       FloorPoint(floor: 1, id: 10, x: 585.6, y: 67.6, neighbours: [9, 11]),
  //       FloorPoint(floor: 1, id: 11, x: 585.8, y: 153.7, neighbours: [10, 12]),
  //       FloorPoint(floor: 1, id: 12, x: 583.3, y: 242, neighbours: [7, 11, 13]),
  //       FloorPoint(floor: 1, id: 13, x: 583.9, y: 321.1, neighbours: [12, 14]),
  //       FloorPoint(floor: 1, id: 14, x: 586.2, y: 398, neighbours: [13, 15]),
  //       FloorPoint(floor: 1, id: 15, x: 484.8, y: 400.5, neighbours: [14, 16]),
  //       FloorPoint(floor: 1, id: 16, x: 479.9, y: 318, neighbours: [7, 15]),
  //     ],
  //   ).findShortestPath(),
  // );
  // print(
  //   const PathBuilder(
  //     startId: 16,
  //     endId: 0,
  //     coords: [
  //       FloorPoint(floor: 1, id: 0, x: 333.9, y: 432.4, neighbours: [1, 2]),
  //       FloorPoint(floor: 1, id: 1, x: 333.4, y: 344, neighbours: [0, 2, 3]),
  //       FloorPoint(floor: 1, id: 2, x: 370.5, y: 343.3, neighbours: [0, 1, 3]),
  //       FloorPoint(floor: 1, id: 3, x: 332.5, y: 303.8, neighbours: [1, 2, 4]),
  //       FloorPoint(floor: 1, id: 4, x: 332.6, y: 242.4, neighbours: [3, 5, 6]),
  //       FloorPoint(floor: 1, id: 5, x: 356.2, y: 206.3, neighbours: [4, 6]),
  //       FloorPoint(floor: 1, id: 6, x: 416.4, y: 242.2, neighbours: [4, 5, 7]),
  //       FloorPoint(
  //         floor: 1,
  //         id: 7,
  //         x: 481.9,
  //         y: 242.7,
  //         neighbours: [6, 8, 12, 16],
  //       ),
  //       FloorPoint(floor: 1, id: 8, x: 481.8, y: 160.1, neighbours: [7, 9]),
  //       FloorPoint(floor: 1, id: 9, x: 483.1, y: 68, neighbours: [8, 10]),
  //       FloorPoint(floor: 1, id: 10, x: 585.6, y: 67.6, neighbours: [9, 11]),
  //       FloorPoint(floor: 1, id: 11, x: 585.8, y: 153.7, neighbours: [10, 12]),
  //       FloorPoint(floor: 1, id: 12, x: 583.3, y: 242, neighbours: [7, 11, 13]),
  //       FloorPoint(floor: 1, id: 13, x: 583.9, y: 321.1, neighbours: [12, 14]),
  //       FloorPoint(floor: 1, id: 14, x: 586.2, y: 398, neighbours: [13, 15]),
  //       FloorPoint(floor: 1, id: 15, x: 484.8, y: 400.5, neighbours: [14, 16]),
  //       FloorPoint(floor: 1, id: 16, x: 479.9, y: 318, neighbours: [7, 15]),
  //     ],
  //   ).findShortestPath(),
  // );

  runApp(
    MaterialApp(
      home: SvgMapExample(
        svgContent: svgContent,
        items: list,
        points: listPoints,
      ),
    ),
  );
}
