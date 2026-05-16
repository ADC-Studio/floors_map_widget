<!-- markdownlint-disable MD041 -->

## 2.0.0 Release Notes (2026-05-15)

### Added

- Tiled SVG rendering is now the default map rendering path.
- Added `debugTiles` to visualize tile borders, tile coordinates, cache stats,
  pending tiles, hits/misses, generated tiles, and pruned tiles.
- Added support for optional external `TransformationController` and
  `SvgMapRenderProperties` notifier for advanced zoom-quality control.

### Changed

- `FloorMapWidget` keeps the simple constructor compatible with existing usage,
  while `listPoints`, `renderPropertiesNotifier`, and
  `transformationController` are now optional named parameters.
- Route calculation now works on initial render and clears when route endpoints
  are removed.
- SVG picture loading and tile generation are cached more carefully to avoid
  unnecessary reloads during pan/zoom gestures.

### Fixed

- Fixed tiled map repainting by using a tile cache version instead of comparing
  a mutable tile cache map by reference.
- Removed production debug tile borders, labels, and `print` calls unless
  `debugTiles` is enabled.
- Fixed debug overlay text decoration when rendered from a root overlay.
- Fixed package validation for the checked-in example SVG asset.

## 1.0.1 Release Notes (2024-10-19)

- add tests
- clean code
- add support change color in FloorPathPainter
- fix get hashCode

## 1.0.0 Release Notes (2024-10-18)

### Add support basic interactive objects

1) shop
2) parkingspace
3) atmmachine
4) toilet
    - male
    - female
    - mother_and_child
5) stairs
    - simple
    - fire_escape
    - escalator
    - elevator

### Add FloorSvgParser

- Can parse points from Circle and Path
- Can parse objects class from Path

### Add FloorSvgMap

- Add function cleanPointsFromMap

### Add PathBuilder

- Can find findShortestPath

### FloorItemWidget

- Can tapped
- Can blinking
- Can customize the animation

### Add FloorPathPainter

- Can paint a path with animation
