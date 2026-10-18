[h1]Live Wire - Переработка навыка «Электрика»[/h1]

[b]Build 42.21 · Одиночная игра и мультиплеер (решения принимает сервер)[/b]

Своё автономное электричество: солнечные панели, ветряк или водяное колесо питают инвертор, а он снабжает весь дом вокруг. Аккумуляторы — на ночь. Навык «Электрика» наконец важен: у каждого прибора свой уровень, и ваш уровень улучшает установку.

[h2]Как это работает[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/diagram_ru.png[/img]

[list]
[*][b]Источники[/b]: панель 100 W, ветряк 400 W, водяное колесо 120 W, сколько угодно на инвертор.
[*][b]Инвертор[/b] (до 1 500 W) питает все приборы в радиусе 20 клеток и ±3 этажа, без проводки к приборам.
[*][b]Аккумуляторный блок[/b] хранит излишки (4 аккумулятора). Без них дом живёт на текущей выработке.
[*][b]Кабели[/b]: провод, 1 на 4 клетки, до 12 клеток. Правый клик > «Live Wire» > «Подключить к инвертору».
[/list]

[h2]Оборудование[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/equipment_ru.png[/img]

[list]
[*]Панель (Электрика 3) и ветряк (6) — на улице; водяное колесо (7) — на берегу реки; инвертор (5) можно ставить в доме; аккумуляторный блок (2) открывается как ящик.
[*][b]Дополнительно[/b]: щиток автоматов, сигнализация низкого заряда, звукоизоляция инвертора, обычный генератор как резерв (ниже 20%), обычный компьютер для управления. До 4 инверторов параллельно (6 000 W) с комплектом связи.
[/list]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot4.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/onduleur.png[/img]

[h2]Производство[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/production_ru.png[/img]

[list]
[*][b]Солнце[/b]: ~0,94 kWh летом, ~0,60 зимой; облака и снег снижают.
[*][b]Ветер[/b]: от 10 км/ч, полная мощность 45–85 км/ч, выше — тормоз.
[*][b]Водяное колесо[/b]: 120 W днём и ночью.
[/list]

Холодильник-морозилка и 10 ламп — ~4,1 kWh в сутки: водяное колесо и 2 панели покрывают это круглый год.

[h2]Водяной насос (новое в 1.2.0)[/h2]

[list]
[*]Бочки с водой на земле снабжают весь дом: раковины, душ, ванны и унитазы работают после отключения воды.
[*][b]Насос[/b] (Электрика 6) ставится рядом со сборниками дождевой воды или бочками [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035]Useful Barrels[/url] (до 8, железная труба на бочку) и подключается к инвертору. Сантехника подключается трубным ключом; радиус 15 клеток. Только вода; дождевая выходит чистой.
[*]5 л/мин, 250 Вт при работе, сам останавливается, когда всё заполнено. Перед удалением мода: действие «Убрать все водяные реле».
[/list]

[h2]Рецепты[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/recipe_book_ru.png[/img]

Категория «Электрика», изучаются автоматически. Солнечные ячейки — из калькуляторов или добычи; готовое оборудование встречается у электриков, в хозмагазинах и гаражах.

[h2]Управляющая программа[/h2]

Live Wire Monitor: выработка, потребление, аккумуляторы, история за 48 ч и прогноз «до рассвета». С Computer Mod или Laptop Mod — на диске из добычи, иначе на подключённом обычном компьютере.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/livewire_monitor_without_compute.png[/img]

[h2]Мультиплеер[/h2]

Сервер всё считает и проверяет. Установка работает и без игроков: еда в холодильниках не портится. Сообщайте о проблемах на выделенном сервере.

[h2]Документация[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki]Вики Live Wire (англ.)[/url] · Код: [url=https://github.com/cyberbobjr/LiveWire]GitHub[/url]

[b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528]Project Viewpoint[/url][/b]: необязательный мод [b]Live Wire - Viewpoint models[/b] (batman_LiveWireViewpoint) с 3D-моделями устройств — только для Project Viewpoint.
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/viewpoint.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/viewpoint2.png[/img]
[b]Совместим с[/b] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3725497089]Computer Mod[/url] и [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3798992436]Laptop Mod[/url] (необязательно).
[b]Совместимость[/b]: не для совместной работы с другими модами энергосистем. Лицензия MIT.

[h2]Поддержите проект[/h2]

Нравится мод? Кофе помогает новым функциям и переводам.
[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]

[h2]Авторы[/h2]

Создал batmanfr. Оригинальный код, текстуры и звуки, без содержимого других модов.
