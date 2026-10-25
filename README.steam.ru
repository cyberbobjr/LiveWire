[h1]Live Wire - Electrical Skill Overhaul[/h1]

[b]Build 42.21 · Одиночная и сетевая игра[/b]

Автономная энергия для дома: солнце, ветер, вода и батареи.

[h2]1.6.0 — Управление электросетью[/h2]

Щиток: рычаги света, приборов и общего питания, текущие ватты по цепям и всего. Отключает реальные приборы и восстанавливает прежние состояния после перезапуска. При открытой общей цепи источники могут заряжать батареи. Левый щелчок открывает LCD устройства; кнопка подключений позволяет выбрать инвертор.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot6.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot7.png[/img]

[h2]Как это работает[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/diagram_ru.png[/img]

Солнце 100 Вт, ветер 400 Вт, водяное колесо 120 Вт. Инвертор питает приборы в 20 клетках и ±3 этажах, до 1500 Вт; четыре связанных — 6000 Вт. Отдельные провода к бытовым приборам не нужны.
Блок хранит 4 батареи. Кабель: 1 провод на 4 клетки, дальность 12. Профили расхода: игровые значения, Реалистичный 1993, Ультрареалистичный 1993, Комфорт.

[h2]Оборудование[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_ru.png[/img]

Установка: панели снаружи (Электрика 3), ветряк снаружи и колесо на берегу реки (оба 2), инвертор (5), блок батарей (2). Два блока ставятся друг на друга; инвентари и связи раздельные. Снимать пустыми, верхний первым.
Дополнительно: щиток, сигнализация, шумоизоляция, обычный резервный генератор и компьютер.

[h2]Производство[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/production_ru.png[/img]

Панели: юг 100%, восток/запад 85%, север 55%. Облака, снег и грязь снижают выработку. Дождь моет панели; вручную — тряпка + 0,5 л воды. Ветер от 10 км/ч, полная мощность 45–85, выше тормоз. Колесо работает круглосуточно. Холод батарей отключён по умолчанию; недоступная энергия сохраняется в резерве.

[h2]Водяной насос[/h2]

Насос (Электрика 6): сантехника в 15 клетках, до 8 соседних водосборников или бочек [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035]Useful Barrels[/url], по металлической трубе на бочку. Подключать трубным ключом. Дождевая вода чистая: до 5 л/мин, 250 Вт при работе. Синий свет = есть питание, даже в покое. До удаления мода уберите водяные реле действием debug/admin.

[h2]Рецепты[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_ru.png[/img]

17 рецептов на схеме. Электрические открываются по уровню; лопасти и мачта в металлообработке без уровня Электрики. Сборка ветряка на 6, колеса на 7, по два усилителя. Установка/подъём обоих на 2. Тестер разбирается на электронный лом. Все рецепты дают опыт Электрики. Больше мест добычи; множитель 5 (1–20), только новые броски после перезапуска.

[h2]Управляющая программа[/h2]

Live Wire Monitor: потребители (до 200), цветные силуэты, кабели, 30 событий, история 48 ч и прогноз выработки на три дня с работающим компьютером. Имена сетей на LCD и в тревогах. Работает обычный ПК; Computer Mod/Laptop Mod — с диском из добычи.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/livewire_monitor_without_compute.png[/img]

[h2]Электробезопасность и опыт[/h2]

Тест батарей на 1/3/5. Ремонт на 4 (мёртвых на 6): отвёртка сохраняется, лом, провод, 0,5 л воды; +15 состояния до 80, четырежды. Разбор пустых сломанных устройств на 3. Риск под напряжением включён: 50/42/33/25/17/8/0% на уровнях 0/1/2/3/4/5/6+. Удар обжигает руку с инструментом, роняет предметы и отменяет работу до расхода материалов. Выключайте главный инвертор: щиток не изолирует клеммы.

[h2]Мультиплеер[/h2]

Расчёты и проверки на сервере, цепи сохраняются, состояния приборов синхронизируются. Замкните обе цепи перед отключением мода.

[h2]Документация[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-Home]Вики Live Wire (англ.)[/url] · Код: [url=https://github.com/cyberbobjr/LiveWire]GitHub[/url]

[b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528]Project Viewpoint[/url][/b]: необязательный мод [b]Live Wire - Viewpoint models[/b] (batman_LiveWireViewpoint) с 3D-моделями устройств — только для Project Viewpoint.
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint2.png[/img]
[b]Совместим с[/b] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3725497089]Computer Mod[/url] и [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3798992436]Laptop Mod[/url] (необязательно).
[b]Совместимость[/b]: не для совместной работы с другими модами энергосистем. Лицензия MIT.

[h2]Discord[/h2]

Вопросы, ошибки или идеи? Присоединяйтесь к Discord:
[url=https://discord.gg/QEsBya7hUA]https://discord.gg/QEsBya7hUA[/url]

[h2]Поддержите проект[/h2]

Нравится мод? Кофе помогает новым функциям и переводам.
[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]

[h2]Авторы[/h2]

Создал batmanfr. Оригинальный код, текстуры и звуки, без содержимого других модов.
