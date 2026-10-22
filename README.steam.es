[h1]Live Wire - Rediseño de la habilidad de Electricidad[/h1]

[b]Build 42.21 · Un jugador y multijugador (con autoridad del servidor)[/b]

El corte de luz es definitivo... pero las luces no tienen por qué serlo. Construye tu propia electricidad fuera de la red: paneles solares, un aerogenerador o una rueda hidráulica alimentan un inversor, y el inversor da corriente a toda la casa que lo rodea. Añade baterías para la noche. La habilidad de Electricidad por fin importa: cada aparato tiene un nivel, y tu nivel mejora la instalación.

[h2]Cómo funciona[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/diagram_es.png[/img]

[list]
[*][b]Fuentes[/b] producen: panel solar 100 W, aerogenerador 400 W, rueda hidráulica 120 W. Tantas como quieras por inversor.
[*][b]El inversor[/b] (1.500 W máx.) alimenta todos los aparatos a 20 casillas y 3 pisos por encima o por debajo. No hay que cablear cada aparato: neveras, luces, cocinas, televisores y radios funcionan como en el juego base.
[*][b]Perfil de consumo[/b] (sandbox): Valores del juego (por defecto), Realista 1993 (luz 60 W, televisor 80 W, cocina eléctrica 2.000 W), Ultrarrealista 1993 o Comodidad.
[*][b]El banco de baterías[/b] almacena el excedente: equivale a 4 baterías (de coche o de ciclo profundo). Sin baterías, la casa funciona solo con la producción del momento.
[*][b]Cables[/b]: cable eléctrico, 1 por cada 4 casillas, alcance de 12 casillas. Clic derecho en un aparato > "Live Wire" > "Conectar a un inversor".
[/list]

[h2]Equipo[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_es.png[/img]

[list]
[*][b]Panel solar[/b] (Electrónica 3): al aire libre, con cielo abierto. Los tejados planos también sirven.
[*][b]Aerogenerador[/b] (6): al aire libre, más potente cuanto más alto está.
[*][b]Rueda hidráulica[/b] (7): en la orilla de un río, en la planta baja.
[*][b]Inversor[/b] (5): el corazón de la red, puede instalarse en interiores.
[*][b]Banco de baterías[/b] (2): se abre como una caja.
[*][b]Opcional[/b]: panel de disyuntores (salta en lugar de dañar el inversor), alarma de batería baja, kit de insonorización para inversor (para el zumbido), generador del juego base como respaldo (se arranca con menos del 20 % de batería) y ordenador de sobremesa del juego base como ordenador de gestión. Hasta 4 inversores acoplados en paralelo (6.000 W) con un kit de acoplamiento.
[/list]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot4.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/onduleur.png[/img]

[h2]Producción[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/production_es.png[/img]

[list]
[*][b]Solar[/b]: unos 0,94 kWh por día de verano, unos 0,60 en invierno. Las nubes y la nieve la reducen.
[*][b]Eólica[/b]: nada por debajo de 10 km/h; sube con el cubo de la velocidad hasta 45 km/h, potencia máxima de 45 a 85 km/h, freno automático por encima.
[*][b]Rueda hidráulica[/b]: 120 W de día y de noche en los ríos.
[/list]

Ejemplo: un frigorífico-congelador y 10 luces consumen unos 4,1 kWh al día. Una rueda hidráulica y 2 paneles lo cubren todo el año.

[h2]Bomba de agua (novedad en 1.2.0)[/h2]

[list]
[*]Los barriles de agua en el suelo alimentan ahora los puntos de agua de toda la casa: fregaderos, duchas, bañeras e inodoros vuelven a funcionar tras el corte de agua.
[*]Coloca la [b]bomba de agua[/b] (Electricidad 6) junto a recolectores de lluvia vanilla o barriles de [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035]Useful Barrels[/url] (hasta 8, un tubo de hierro cada uno) y conéctala al inversor.
[*]Conecta los puntos de agua con una llave de tubo como en vanilla: cada punto conectado a menos de 15 casillas (sandbox) recibe agua. Solo se acepta agua; el agua de lluvia sale limpia.
[*]5 L por minuto, 250 W al bombear, un leve zumbido; se detiene sola cuando todos los puntos de agua están llenos. "Mostrar los puntos de agua alimentados" los resalta en azul.
[*]Antes de quitar el mod, ejecuta la acción debug/admin "Quitar todos los relés de agua". Aún no probada en el juego: informa de cualquier problema.
[/list]

[h2]Recetas[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_es.png[/img]

Categoría Electrónica, aprendida automáticamente al nivel requerido. Las células solares salen de calculadoras desmontadas o se encuentran como botín; también pueden aparecer equipos ya hechos en tiendas de electricistas, ferreterías y garajes.

[h2]Software de gestión[/h2]

Live Wire Monitor muestra la producción, el consumo, las baterías, un historial de 48 h y una previsión "hasta el amanecer". Con el Computer Mod o el Laptop Mod opcionales, llega en un disco que se encuentra en el botín de ordenadores. Si no, un ordenador de sobremesa del juego base conectado al inversor lo ejecuta.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/livewire_monitor_without_compute.png[/img]

[h2]Multijugador[/h2]

El servidor calcula todo y vuelve a comprobar cada petición. La instalación sigue funcionando cuando los jugadores se marchan: las neveras mantienen frescos los alimentos. Todavía no se ha probado en un servidor dedicado, así que informad de cualquier problema.

[h2]Documentación[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki]Wiki de Live Wire (en inglés)[/url] · Código fuente: [url=https://github.com/cyberbobjr/LiveWire]GitHub[/url]

[b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528]Project Viewpoint[/url][/b]: este objeto también incluye el mod opcional [b]Live Wire - Viewpoint models[/b] (batman_LiveWireViewpoint) con modelos 3D de todos los equipos. Actívalo solo si usas Project Viewpoint.
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint2.png[/img]
[b]Compatible con[/b] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3725497089]Computer Mod[/url] y [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3798992436]Laptop Mod[/url] (opcionales): el software de gestión se instala desde un disco encontrado en el botín de ordenadores y funciona como una aplicación en su escritorio.
[b]Compatibilidad[/b]: creación original, no pensada para funcionar junto con otros mods de sistemas eléctricos. Licencia MIT.

[h2]Discord[/h2]

¿Preguntas, errores o ideas? Únete al Discord:
[url=https://discord.gg/QEsBya7hUA]https://discord.gg/QEsBya7hUA[/url]

[h2]Apoya el proyecto[/h2]

¿Te gusta el mod? Un café ayuda a financiar nuevas funciones y traducciones.
[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]

[h2]Créditos[/h2]

Creado por batmanfr. Código original, tiles y sonidos; no se ha tomado contenido de otros mods.
