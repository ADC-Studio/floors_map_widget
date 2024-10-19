<!-- markdownlint-disable MD041 MD033 -->

<br>

<div align="center">
    <h1 align="center">Floors Map Widget</h1>
    <p align="center">
        <strong>
        Этот виджет позволяет создать интерактивную карту этажей на основе SVG изображения.
        </strong>
    </p>

[![build](https://img.shields.io/github/actions/workflow/status/ADC-Studio/floors_map_widget/build.yml)](https://github.com/ADC-Studio/floors_map_widget/actions)
[![release](https://img.shields.io/pub/v/floors_map_widget)](https://github.com/hydralauncher/hydra/releases)

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

Используя Figma или любой другой редактор SVG, создаём карту помещения или используем уже готовую.
Теперь данную карту нужно подготовить к работе с FloorMapWidget. Необходимо задать точки маршрута и точки входов в объекты помещения. Для этого можно использовать готовое расширение для Figma [здесь](https://github.com/ADC-Studio/FloorsMapWidgetFigmaExtension) или сделать это вручную.

#### Расширение Figma

Расставляем точки и соединяем их в маршруты. Более детальное описание можно прочитать [здесь](https://github.com/ADC-Studio/FloorsMapWidgetFigmaExtension).

![MapPlaginExample](https://github.com/user-attachments/assets/2a780fb4-5541-4334-a229-a7577a65b730)

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
    // Floors widgets
    _listWidgets,
    // Use for build a route
    startIdPoint: _startPointItem?.idPoint,
    endIdPoint: _endPointItem?.idPoint, 
    // Use for remove points from svg
    unvisiblePoints: true,
),
```

Чтобы добавить на карту интерактивные объекты, необходимо их инициализировать виджетом FloorItemWidget и передать списком в FloorItemWidget.

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

[ADC STUDIO](https://adc-web.ru)

[Valerij Shishov](https://github.com/MixKage) |
[Arthur Lokhov](https://github.com/i4ox)

This library is open for issues and pull requests. If you have ideas for improvements or bugs, the repository is open to contributions!
