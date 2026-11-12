[h1]LiveWire - Renovación de la habilidad de Electrónica[/h1]

[b]Build 42.21+ · Un jugador y multijugador[/b]

La red eléctrica se fue para siempre, pero las luces no tienen por qué apagarse. Produce tu electricidad fuera de la red: paneles solares, aerogeneradores y ruedas hidráulicas alimentan un inversor que da corriente a la casa que lo rodea, con baterías para la noche. Cada aparato tiene un nivel de Electrónica, y tu nivel mejora la instalación.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/art/extended_banner.png[/img]

[h2]LiveWire Extended (complemento opcional)[/h2]

[list]
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#connect-a-whole-building]Conectar un edificio entero[/url]: cada planta y el sótano. Franja alrededor opcional: opción sandbox Franja exterior alrededor de un edificio (0 por defecto).
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#power-terminal-and-zone]Terminal de corriente exterior[/url]: alimenta una zona dibujada de hasta 16 x 16 casillas.
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#breaker-boards]Cuadros eléctricos[/url]: disyuntores de 15, 20 o 30 A, uno por circuito; un disyuntor puede alimentar varios aparatos.
[*][url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended#twilight-switch]Interruptor crepuscular para disyuntor[/url]: montado en un disyuntor, mantiene ese circuito encendido del anochecer al amanecer.
[*]Algunas casas del mapa ya tienen un cuadro precableado, sin etiquetas.
[/list]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_extended_es.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_extended_es.png[/img]

Actívalo en la lista de mods, después de LiveWire. No es compatible con LG Extended Electricity ni con Knox Power. Para quitarlo sin riesgo, un admin primero vuelve a encender todos los disyuntores desde el menú de un cuadro.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-14-livewire-extended]Guía completa[/url]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/diagram_es.png[/img]

[h2]Cómo funciona[/h2]

Solar 100 W, eólica 400 W, rueda hidráulica 120 W. Un inversor alimenta los aparatos a 20 casillas y ±3 plantas, hasta 1.500 W, sin cable por aparato. El excedente va a bancos de baterías.
Mientras la red pública funcione, un inversor dentro de un edificio también toma hasta una quinta parte de su potencia de la red (opción sandbox GridCharging, activada por defecto).
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-01-getting-started]Primeros pasos[/url]

[h2]Equipo[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_es.png[/img]

Colocar requiere un destornillador, sin nivel. Conexión: paneles solares e inversores nivel 3; aerogeneradores, ruedas hidráulicas y bancos de baterías nivel 2. Opcional: disyuntor, alarma, insonorización, generador de respaldo vanilla y ordenador de gestión.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-02-equipment]Guía del equipo[/url]

[h2]Producción[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/production_es.png[/img]

La orientación solar importa: sur 100 %, este y oeste 85 %, norte 55 %. Nubes, nieve y suciedad reducen la producción; la lluvia limpia los paneles. El aerogenerador produce desde 10 km/h y a plena potencia de 30 a 85 km/h. La rueda hidráulica produce de día y de noche.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-04-production-and-calculations]Producción y cálculos[/url]

[h2]Cableado y acoplamiento[/h2]

Clic derecho en un aparato > LiveWire > Conectar a un inversor. Un cable cuesta 1 cable eléctrico por cada 4 casillas, alcance 12. ¿Necesitas más de 1.500 W? Acopla un segundo inversor (Acoplar a un inversor, 1 kit de acoplamiento de inversores): una red admite 4 inversores, 6.000 W.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-03-wiring]Guía de cableado[/url]

[h2]Pantalla del inversor y software de gestión[/h2]

La pantalla del inversor controla la iluminación, los equipos y las palancas principales, y muestra los vatios de cada circuito. LiveWire Monitor añade consumidores, vistas de cables, una previsión a tres días y los últimos 30 eventos, en un ordenador de gestión con corriente.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-05-inverter-screen-and-software]Pantalla y software[/url]

[h2]Bomba de agua[/h2]

Una bomba de agua (Electrónica 3) alimenta los sanitarios conectados a 15 casillas, desde hasta 8 recolectores de lluvia o barriles [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035]Useful Barrels[/url] adyacentes.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-07-water-pump]Guía de la bomba[/url]

[h2]Recetas[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_es.png[/img]

16 recetas de fabricación (arriba) y 15 de desmontaje (destornillador): todo se desmonta salvo la célula solar. Recoge el aparato, aunque esté estropeado, y desmóntalo en el menú de fabricación.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-08-recipes]Recetas[/url]

[h2]Electrónica y seguridad[/h2]

Prueba las baterías en Electrónica 1, 3 y 5 para ver más detalles. El trabajo con corriente tiene riesgo de descarga, activado por defecto: 50 % en nivel 0, 0 % en nivel 6 o más. Apaga primero el inversor maestro; abrir un disyuntor no aísla.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-10-electrical-skill-and-maintenance]Habilidad de Electrónica y mantenimiento[/url]

[h2]Multijugador[/h2]

El servidor comprueba cada acción; las elecciones de circuitos y los estados de los aparatos se guardan y sincronizan. Cierra ambos circuitos antes de desactivar el mod.
[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-12-multiplayer]Guía multijugador[/url]

[h2]Modelos de Project Viewpoint[/h2]

[b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528]Project Viewpoint[/url][/b]: este elemento incluye también el mod opcional LiveWire - Viewpoint models, con modelos 3D de todos los aparatos. Actívalo solo si usas Project Viewpoint.

[h2]Compatibilidad[/h2]

Compatible con [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3725497089]Computer Mod[/url] y [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3798992436]Laptop Mod[/url] (opcionales). Creación original, no pensada para otros mods de sistemas eléctricos. Licencia MIT.

[h2]Documentación[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-Home]Wiki de LiveWire[/url] · Código fuente: [url=https://github.com/cyberbobjr/LiveWire]GitHub[/url]

[h2]Discord[/h2]

¿Preguntas, errores o ideas? Únete al Discord:
[url=https://discord.gg/QEsBya7hUA]https://discord.gg/QEsBya7hUA[/url]

[h2]Una nota sobre la IA[/h2]

Soy desarrollador desde hace años e hice mods mucho antes de que existieran los agentes de programación, a menudo a costa de tiempo con mi familia. Uso abiertamente Claude Code y Codex: cada función sigue siendo discutida, diseñada y planificada, no «vibe coded» a ciegas. La IA ha llegado para quedarse; elegí adaptarme en lugar de resistirme. Gracias a todos los que se pusieron de pie frente a los ataques personales.

[h2]Apoya el proyecto[/h2]

¿Te gusta el mod? Un café ayuda a financiar nuevas funciones y traducciones.
[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]

[h2]Créditos[/h2]

Creado por batmanfr. Modelo del armario inversor: PewPewCricket. Código, baldosas y sonidos originales; no se ha tomado contenido de otros mods.
