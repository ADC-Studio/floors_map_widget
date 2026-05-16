<!-- markdownlint-disable MD041 MD033 -->

<br>

<div align="center">
    <h1 align="center">Floors Map Widget</h1>
    <p align="center">
        <strong>
        Этот виджет позволяет создать интерактивную карту этажей на основе SVG изображения.
        </strong>
    </p>

[![release](https://img.shields.io/pub/v/floors_map_widget)](https://github.com/hydralauncher/hydra/releases)
[![platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![license](https://img.shields.io/github/license/codenameakshay/flutter-floating-bottom-bar?color=red)](https://opensource.org/licenses/MIT)

[![en](https://img.shields.io/badge/lang-en-yellow.svg)](README.md)

<p align="center">
        <img src="https://github.com/user-attachments/assets/546c6ba6-98e1-477c-afe0-8febdba6da8c" alt="Logo" />
</p>

</div>

## Список содержимого

- [О проекте](#о-проекте)
- [Возможности](#возможности)
- [Как использовать](#как-использовать)
- [Сделать свой вклад](#сделать-свой-вклад)

## О проекте

Этот виджет позволяет создать интерактивную карту этажей на основе SVG изображения.

## Возможности

- Генерация интерактивной карты на основе SVG изображения.
- Составление и визуализация маршрутов между различными точками.
- Настройка взаимодействий при нажатии на блок.
- Тайловый рендеринг SVG для более плавной работы с большими картами.
- Опциональная debug-панель тайлов для анализа видимой области и поведения
  кэша во время разработки.

## Поддерживаемые классы объектов

- shop
- parkingspace
- atmmachine
- toilet
- stairs

### Toilet SubTypes

- male
- female
- mother_and_child

### Stairs SubTypes

- simple
- fire_escape
- escalator
- elevator

## Как использовать

Работа с библиотекой разбита на несколько этапов.

- [Добавление точек маршрута](#этап-1---добавление-точек-маршрута)
- [Выдача правильных id объектам помещения](#этап-2---выдача-правильных-id-объектам-помещения)
- [Внедрение библиотеки в ваш проект](#этап-3---внедрение-библиотеки-в-ваш-проект)

### Этап 1 - Добавление точек маршрута

Используя Inkscape или любой другой редактор SVG, создаём карту помещения или используем уже готовую.
Теперь данную карту нужно подготовить к работе с FloorMapWidget. Необходимо задать точки маршрута и точки входов в объекты помещения. Для этого можно использовать готовое расширение для Inkscape [floors_map_extension](https://github.com/Brnd08/floors_map_extension) или сделать это вручную.

#### Расширение Inkscape

Расширение Inkscape [floors_map_extension](https://github.com/Brnd08/floors_map_extension) помогает подготовить SVG-карту для этого виджета: соединяет выбранные point shapes, назначает совместимые id для точек и объектов, создаёт точки входа, связывает объекты с их входами и удаляет больше не связанные точки. Используйте его, если хотите привести SVG к ID-паттернам, которые ожидает `FloorSvgParser`, без ручного редактирования id у каждого объекта.

![MapPlaginExample1](https://github.com/user-attachments/assets/1f61cf91-e84a-41ed-aca2-e24e4db4f8f6)
![MapPlaginExample2](https://github.com/user-attachments/assets/61c5ef6f-93cf-4640-9577-a522a5efaf68)

#### Реализация вручную

Можно использовать как фигуру circle, так и произвольную используя path. Привязка точек происходит с использованием id аттрибута. Например здесь в примере, мы создали точку двумя способами и привязали её к трём соседним точкам.

```text
point-43=44-39-45
│     │  └‒‒└‒‒└‒‒‒‒‒ уникальные id привязанных соседей
│     └‒‒‒‒‒ уникальный id объекта
└‒‒‒‒‒ класс объекта - point
```

```svg
<circle id="point-43=44-39-45" cx="4.5" cy="4.5" r="4.5" fill="black"/>
```

```svg
<path id="point-43=44-39-45" d="M4.2 8.39999C6.52 8.39999 8.39999 6.52 8.39999 4.2C8.39999 1.88 6.52 0 4.2 0C1.88 0 0 1.88 0 4.2C0 6.52 1.88 8.39999 4.2 8.39999Z" fill="black"/>
```

### Этап 2 - Выдача правильных id объектам помещения

Поддерживаемые объекты можно посмотреть [здесь](#поддерживаемые-классы-объектов).
Правила составления id такие же, как и у Point.

```text
shop-1=2
│    │ └‒‒‒‒‒ уникальные id привязанной точки входа (может быть только одна)
│    └‒‒‒‒‒ уникальный id объекта
└‒‒‒‒‒ класс объекта
```

```text
stairs-elevator-1=2
│      │        │ └‒‒‒‒‒ уникальные id привязанной точки входа (может быть только одна)
│      │        └‒‒‒‒‒ уникальный id объекта
│      └‒‒‒‒‒ подтип объекта (обязателен для stairs и toilet)
└‒‒‒‒‒ класс объекта
```

#### Готовый пример

```svg
<path id="shop-3=5" d="M477.648 206.928H428.712V323.772H565.44V315H569.448V235.404H481.044H477.648V231.996V206.928Z" fill="#EEF9FE" />
```

### Этап 3 - Внедрение библиотеки в ваш проект

Добавляем библиотеку в ваш проект и встраиваем готовый виджет, содержащий в себе необходимые параметры.

```Dart
FloorMapWidget(
  // String from SVG Map
  _svgContent,
  // Floor widgets
  _listWidgets,
  // Опционально: заранее распарсенные route points.
  // Если не передать, FloorMapWidget распарсит их сам.
  listPoints: _listPoints,
  // Use for build a route
  startIdPoint: _startPointItem?.idPoint,
  endIdPoint: _endPointItem?.idPoint,
  // Use for remove points from svg
  unvisiblePoints: true,
),
```

По умолчанию карта отрисовывается через тайловый renderer. Это отделяет слой
карты от интерактивных объектов и снижает количество повторной растеризации во
время перемещения и масштабирования.

Для разработки можно включить debug-панель тайлов:

```dart
FloorMapWidget(
  _svgContent,
  _listWidgets,
  debugTiles: true,
)
```

Панель закреплена в правом верхнем углу поверх приложения и сворачивается по
нажатию. Она показывает количество отрисованных/видимых тайлов, видимый
диапазон тайлов, effective/requested raster scale, cached/pending tiles,
hits/misses, generated tiles и pruned tiles.

Для расширенного управления качеством при масштабировании можно передать свои
`TransformationController` и `ValueNotifier<SvgMapRenderProperties>`:

```dart
final transformationController = TransformationController();
final renderPropertiesNotifier = ValueNotifier(
  SvgMapRenderProperties(
    svgData: svgContent,
    svgSource: SvgSource.string,
    mapSize: null,
    renderingStrategy: RenderStrategy.picture,
  ),
);

FloorMapWidget(
  svgContent,
  itemWidgets,
  listPoints: points,
  transformationController: transformationController,
  renderPropertiesNotifier: renderPropertiesNotifier,
)
```

#### Параметры FloorMapWidget

| Параметр | Тип | Обязательный | Описание |
| --- | --- | --- | --- |
| `svgContent` | `String` | Да | SVG-разметка, используемая стандартным string source. |
| `listItemsWidgets` | `List<FloorItemWidget>` | Да | Интерактивные overlay-объекты, которые отрисовываются поверх карты. |
| `listPoints` | `List<FloorPoint>?` | Нет | Заранее распарсенные точки маршрута. Если не передать, они будут получены из `svgContent`. |
| `renderPropertiesNotifier` | `ValueNotifier<SvgMapRenderProperties>?` | Нет | Внешнее состояние рендера карты для управления SVG source, качеством и loading widget. |
| `transformationController` | `TransformationController?` | Нет | Общий контроллер для родительского `InteractiveViewer` и тайлового renderer. |
| `unvisiblePoints` | `bool` | Нет | Удаляет point markers из SVG string rendering. По умолчанию `false`. |
| `debugTiles` | `bool` | Нет | Включает сворачиваемую debug-панель тайлов. По умолчанию `false`. |
| `startIdPoint` | `int?` | Нет | Id стартовой точки маршрута. |
| `endIdPoint` | `int?` | Нет | Id конечной точки маршрута. |

#### Параметры SvgMapRenderProperties

| Параметр | Тип | Значение по умолчанию | Описание |
| --- | --- | --- | --- |
| `svgData` | `Object` | Обязательный | SVG string, путь к SVG asset или путь к compiled vector graphic asset. |
| `svgSource` | `SvgSource` | Обязательный | Тип источника: `SvgSource.string`, `SvgSource.asset` или `SvgSource.compiled`. |
| `mapSize` | `Size?` | Обязательный | Размер рендера. `FloorMapWidget` синхронизирует его со своими layout constraints. |
| `loadingPlaceholder` | `Widget?` | `null` | Виджет, который показывается во время загрузки SVG picture. |
| `renderquality` | `double` | `5` | Запрошенное качество raster tiles. Тайловый renderer ограничивает effective quality текущим viewport scale. |
| `renderingStrategy` | `RenderStrategy?` | `RenderStrategy.raster` | Rendering strategy из `flutter_svg`, используемая SVG loader. |

Чтобы добавить на карту интерактивные объекты, инициализируйте их через
`FloorItemWidget` и передайте получившийся список в `FloorMapWidget`.

```Dart
FloorItemWidget(
    // FloorItem
    item: element,
    // Function (FloorItem)
    onTap: _handleFloorItemTap,
    // An example of how to change the color of an
    // interaction animation
    selectedColor: Colors.orange[200]!.withOpacity(0.5),
    // An example of how to turn on an object's blinking
    // Thanks to this, you can highlight some objects on the map.
    // For example toilets or ATM
    isActiveBlinking: false,
),
```

#### Параметры FloorItemWidget

| Параметр | Тип | Значение по умолчанию | Описание |
| --- | --- | --- | --- |
| `item` | `FloorItem` | Обязательный | Интерактивный объект, распарсенный из SVG. |
| `onTap` | `Future<void> Function(FloorItem)?` | `null` | Вызывается при нажатии на объект. |
| `durationTapAnimation` | `Duration` | `50ms` | Длительность анимации подсветки при нажатии. |
| `durationBlink` | `Duration` | `1s` | Длительность анимации мигающей подсветки. |
| `isActiveBlinking` | `bool` | `false` | Включает повторяющуюся мигающую подсветку. |
| `selectedColor` | `Color?` | `null` | Цвет подсветки. Если не задан, используется стандартный полупрозрачный цвет. |
| `parentSize` | `Size?` | `null` | Размер родительской карты. Обычно устанавливается автоматически внутри `FloorMapWidget`. |

Получить объекты можно, используя FloorSvgParser.

```Dart
final parser = FloorSvgParser(svgContent: svgContent);
// You can get anchor points from the map
final listPoints = parser.getPoints();
// You can get all objects supported by the library
final listItems = parser.getItems();
```

Для получения дополнительной информации посетите Example с подготовленным кодом и картой [example](/example/README.md).

![Example](https://github.com/user-attachments/assets/db2ae074-69e9-4e20-81b3-ce831daa5ae8)

## Сделать свой вклад

Для начала прочитайте [CONTRIBUTING.md](CONTRIBUTING.md),
чтобы узнать о гайдлайнах внутри этого проекта.

## Changelog

[Refer to the Changelog to get all release notes.](/CHANGELOG.md)

## Maintainers

[ЛОГИОН](https://logion-mobile.ru)

[Valerij Shishov](https://github.com/MixKage) |
[Arthur Lokhov](https://github.com/i4ox) |
[Brdn Velazquez](https://github.com/Brnd08)

This library is open for issues and pull requests. If you have ideas for improvements or bugs, the repository is open to contributions!
