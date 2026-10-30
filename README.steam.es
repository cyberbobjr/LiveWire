[h1]Live Wire - Rediseño de la habilidad de Electricidad[/h1]

[b]Build 42.21 · Un jugador y multijugador (con autoridad del servidor)[/b]

El corte de luz es definitivo... pero las luces no tienen por qué serlo. Construye tu propia electricidad fuera de la red: paneles solares, un aerogenerador o una rueda hidráulica alimentan un inversor, y el inversor da corriente a toda la casa que lo rodea. Añade baterías para la noche. La habilidad de Electricidad por fin importa: cada aparato tiene un nivel, y tu nivel mejora la instalación.

[h2]1.6.0 — Controla tu instalación[/h2]

El cuadro incluye palancas de iluminación, equipos y general, con vatios actuales por circuito y totales. Apaga aparatos reales y recupera sus estados anteriores incluso tras reiniciar. Las fuentes pueden cargar baterías con la distribución general abierta. Clic izquierdo en cada equipo abre su LCD; el botón de conexiones permite elegir inversor.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot6.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/shot7.png[/img]

[h2]Cómo funciona[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/diagram_es.png[/img]

Solar 100 W, eólica 400 W, rueda hidráulica 120 W. Un inversor alimenta aparatos a 20 casillas y ±3 plantas, hasta 1500 W. Sin cable por aparato doméstico.
[b]¿Necesitas más de 1500 W?[/b] Coloca un segundo inversor sin nada conectado, clic derecho > Live Wire > «Acoplar a un inversor» (1 kit de acoplamiento de inversores, receta de Electricidad 6). Hasta 4 inversores acoplados: 6000 W.
Bancos de 4 baterías para guardar el excedente. Cables: 1 alambre cada 4 casillas, alcance 12. Perfiles: valores del juego, Realista 1993, Ultrarealista 1993 o Confort.

[h2]Equipo[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/equipment_es.png[/img]

Paneles al aire libre (Electricidad 3), aerogeneradores fuera y ruedas en la orilla de un río (ambos 2), inversores (5), bancos (2). Apila dos bancos por casilla con inventarios y conexiones separados; vacíalos antes de recogerlos, primero el superior.
Opcionales: cuadro eléctrico, alarma, insonorización, generador vanilla de respaldo y ordenador de gestión.

[h2]Producción[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/production_es.png[/img]

Orientación solar: sur 100%, este/oeste 85%, norte 55%. Nubes, nieve y suciedad reducen la producción. La lluvia limpia; también un trapo + 0,5 L de agua. Viento desde 10 km/h, potencia plena a 45–85 y freno por encima. Rueda activa día y noche. El frío opcional conserva como reserva la energía inaccesible de las baterías; desactivado por defecto.

[h2]Bomba de agua[/h2]

La bomba (Electricidad 6) abastece sanitarios conectados a 15 casillas desde hasta 8 colectores de lluvia o barriles [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035]Useful Barrels[/url] adyacentes, un tubo metálico por depósito. Fontanería con llave de tubo. Agua de lluvia limpia: hasta 5 L/min, 250 W al bombear. Azul = alimentada, incluso en reposo. Antes de desinstalar, elimina todos los relés de agua con la acción debug/admin.

[h2]Recetas[/h2]

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/diagrams/recipe_book_es.png[/img]

17 recetas ilustradas. Desbloqueo automático en Electricidad; palas y mástil en Metalurgia sin nivel eléctrico. Montaje del aerogenerador al 6, fabricación de la rueda al 7, ambos con dos amplificadores. Colocar/recoger ambos al 2. Desmonta un comprobador para recuperar chatarra electrónica. Todas dan XP de Electricidad. Más lugares de botín; multiplicador 5 por defecto (1–20), solo tiradas futuras tras reiniciar.

[h2]Software de gestión[/h2]

Live Wire Monitor añade consumidores (hasta 200), siluetas de colores, cables, los últimos 30 eventos y previsión de producción de tres días con ordenador de gestión alimentado, además del historial de 48 h. Nombres de red en LCD y avisos. Ordenador vanilla compatible; Computer Mod/Laptop Mod opcionales mediante disco de botín.

[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/livewire_monitor_without_compute.png[/img]

[h2]Seguridad eléctrica y experiencia[/h2]

Prueba baterías al nivel 1/3/5. Reacondiciona al 4 (6 si muerta): destornillador conservado, chatarra, cable, 0,5 L de agua; +15 estado, máximo 80, cuatro veces. Recupera equipos muertos y vacíos al 3. Riesgo con tensión activado: 50/42/33/25/17/8/0% a niveles 0/1/2/3/4/5/6+. Una descarga quema la mano de la herramienta, suelta objetos y cancela antes de gastar materiales. Apaga el inversor maestro; el cuadro no aísla sus bornes.

[h2]Multijugador[/h2]

Simulación y comprobaciones en el servidor, circuitos guardados y estados sincronizados. Cierra ambos circuitos antes de desactivar el mod.

[h2]Documentación[/h2]

[url=https://github.com/cyberbobjr/LiveWire/wiki/EN-Home]Wiki de Live Wire (en inglés)[/url] · Código fuente: [url=https://github.com/cyberbobjr/LiveWire]GitHub[/url]

[b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528]Project Viewpoint[/url][/b]: este objeto también incluye el mod opcional [b]Live Wire - Viewpoint models[/b] (batman_LiveWireViewpoint) con modelos 3D de todos los equipos. Actívalo solo si usas Project Viewpoint.
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint.png[/img]
[img]https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/screenshots/viewpoint2.png[/img]
[b]Compatible con[/b] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3725497089]Computer Mod[/url] y [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3798992436]Laptop Mod[/url] (opcionales): el software de gestión se instala desde un disco encontrado en el botín de ordenadores y funciona como una aplicación en su escritorio.
[b]Compatibilidad[/b]: creación original, no pensada para funcionar junto con otros mods de sistemas eléctricos. Licencia MIT.

[h2]Discord[/h2]

¿Preguntas, errores o ideas? Únete al Discord:
[url=https://discord.gg/QEsBya7hUA]https://discord.gg/QEsBya7hUA[/url]

[h2]Una nota sobre la IA[/h2]

Soy desarrollador desde hace años y creaba mods mucho antes de que existieran los agentes de programación, a menudo a costa del tiempo con mi familia. Uso abiertamente Claude Code y Codex: cada función se sigue discutiendo, diseñando y planificando, no se hace a ciegas con «vibe coding». La IA ha llegado para quedarse; he elegido adaptarme en lugar de resistirme. Gracias a todos los que se opusieron a los ataques personales.

[h2]Apoya el proyecto[/h2]

¿Te gusta el mod? Un café ayuda a financiar nuevas funciones y traducciones.
[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]

[h2]Créditos[/h2]

Creado por batmanfr. Código original, tiles y sonidos; no se ha tomado contenido de otros mods.
