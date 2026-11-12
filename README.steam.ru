[h1]LiveWire - Переработка навыка электрики[/h1]

[b]Build 42.21+ · Одиночная игра и мультиплеер[/b]

Электросеть пропала навсегда, но свет можно сохранить. Солнечные панели, ветряки и водяные колёса питают инвертор, который снабжает дом. Уровень Электрики улучшает установку.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/art/extended_banner.png[/img]

[h2]Одна подписка, три мода[/h2]
[list]
[*][b]LiveWire[/b] (обязателен): производите, храните и распределяйте свой ток. Часть 1.
[*][b]LiveWire Extended[/b] (необязателен, [b]новое в 2.0[/b]): ток во всё здание через электрощитки, комната за комнатой. Часть 2.
[*][b]LiveWire - Viewpoint models[/b] (необязателен): 3D-модели, только с Project Viewpoint.
[/list]
Extended и модели требуют LiveWire, включённый раньше них.

[hr][/hr]
[h1]1. LiveWire, базовый мод[/h1]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/diagram_ru.png[/img]

[h2]Как это работает[/h2]

Солнце 100 Вт, ветер 400 Вт, колесо 120 Вт. Инвертор питает приборы в 20 клетках и ±3 этажах, до 1 500 Вт.
Пока публичная сеть работает, инвертор в здании берёт из сети до 1/5 своей мощности (опция GridCharging, вкл. по умолчанию).
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-01-getting-started]Начало работы[/url]

[h2]Оборудование[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_ru.png[/img]

Установка: отвёртка, без уровня. Подключение: панели и инверторы с 3 уровня, ветряки и колёса со 2.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-02-equipment]Оборудование[/url]

[h2]Выработка[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/production_ru.png[/img]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-04-production-and-calculations]Выработка[/url]

[h2]Проводка и сцепка[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-03-wiring]Проводка[/url]

[h2]Экран инвертора и программа управления[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-05-inverter-screen-and-software]Экран и программа[/url]

[h2]Водяной насос[/h2]

Насос (Электрика 3) питает сантехнику в 15 клетках от 8 соседних дождевых сборников или бочек [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035]Useful Barrels[/url].
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-07-water-pump]Насос[/url]

[h2]Рецепты[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_ru.png[/img]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-08-recipes]Рецепты[/url]

[h2]Электрика и безопасность[/h2]

Проверяйте аккумуляторы на Электрике 1, 3 и 5. Удар током: 50 % на уровне 0, 0 % с 6. Сначала выключите главный инвертор.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-10-electrical-skill-and-maintenance]Обслуживание[/url]

[h2]Мультиплеер[/h2]

Перед отключением мода закройте обе цепи.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-12-multiplayer]Мультиплеер[/url]

[hr][/hr]
[h1]2. LiveWire Extended, дополнение[/h1]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/diagram_extended_ru.png[/img]

Доводит ток инвертора до целых зданий и уличных зон. Основные работы требуют Электрику 3.

[list]
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#connect-a-whole-building]Всё здание[/url]: этажи и подвал; полоса вокруг: опция «Полоса вокруг здания» (по умолчанию 0).
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#power-terminal-and-zone]Наружная клемма[/url]: зона до 16 x 16 клеток.
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#breaker-boards]Электрощитки[/url]: автоматы 15, 20, 30 А, один на цепь из нескольких приборов.
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#twilight-switch]Сумеречный выключатель для автомата[/url]: включает цепь от заката до рассвета.
[/list]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_extended_ru.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_extended_ru.png[/img]

[h2]Включение и удаление[/h2]

Включите после LiveWire. Несовместимо с LG Extended Electricity и Knox Power.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended]Руководство[/url]

[hr][/hr]
[h1]3. Модели Viewpoint[/h1]

[b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528]Project Viewpoint[/url][/b]: мод LiveWire - Viewpoint models с 3D-моделями приборов.

[hr][/hr]
[h2]Совместимость[/h2]

Совместим с [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3725497089]Computer Mod[/url] и [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3798992436]Laptop Mod[/url]. Лицензия MIT.

[h2]Документация[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-Home]Вики LiveWire[/url] · Исходный код: [url=https://github.com/cyberbobjr/LiveWire]GitHub[/url]

[h2]Discord[/h2]

[url=https://discord.gg/QEsBya7hUA]https://discord.gg/QEsBya7hUA[/url]

[h2]Пара слов об ИИ[/h2]

Я разработчик уже много лет и делал моды задолго до появления агентов для кода, часто в ущерб времени с семьёй. Я открыто использую Claude Code и Codex: каждая функция по-прежнему обсуждается, проектируется и планируется, а не пишется «на вайбе» вслепую. ИИ здесь надолго; я решил адаптироваться, а не сопротивляться. Спасибо всем, кто встал на защиту от личных нападок.

[h2]Поддержать проект[/h2]

Нравится мод? Чашка кофе помогает финансировать новые функции и переводы.
[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]

[h2]Авторы[/h2]

Создал batmanfr. Модель шкафа инвертора: PewPewCricket. Оригинальный код, тайлы и звуки; контент из других модов не использован.
