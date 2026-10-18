# NebulaVR 0.3.0 - proyecto unificado Godot

Continuacion de pilahito/SmartTube-VR-3D para Meta Quest con Godot 4.7.2.

## Implementado
- Inicio con launcher en el mundo 3D.
- Playa y bosque nocturno procedural con 128 luciernagas animadas.
- Cambio de mundo conservando el reproductor de video.
- Tres distancias de vision: 6, 10 y 16 metros.
- Panel ampliado y control del cine con mandos.
- Solicitud de 120 Hz si el runtime lo ofrece; no garantiza rendimiento a 120 FPS.
- Video de prueba incluido; volumen inicial reducido.
- Selector de apps Android, accesos guardados, paginas y eliminacion de accesos.
- Boton SmartTube VR: abre su paquete instalado mediante Android.
- Modo ECO (resolucion 3D al 75 %), pantalla curva/plana y pausa al perder actividad.
- Setas luminosas con shader animado y dibujado por instancias.

## Probar
Abre project.godot con Godot. Para el simulador de TITAN usa probar-silencioso.bat: selecciona salida de audio Dummy, sin cambiar el volumen del PC ni el runtime global de OpenXR.
Para ver la escena en escritorio usa abrir-NebulaVR-sin-sonido.bat. Teclas: 1 cine, 2 mundo, 3 inicio, espacio pausa, flechas salto, F curva/plana. Los botones 3D se manejan con el laser de los mandos en XR.

## Validacion
Pruebas headless en Godot 4.7.2 completadas: launcher, cine, ida y vuelta entre mundos, identidad del reproductor y tres asientos. Prueba adicional de accesos: escritorio sin Android, duplicados, persistencia y datos invalidos.

El runtime de Meta XR Simulator 207.1 se carga, pero su frontend no conecta en este entorno. La interaccion y el rendimiento en visor no estan validados. La exportacion Android se intento y se detuvo por las rutas del SDK/Java que esta ejecucion de Godot no puede resolver; no se incluye una APK.

## Pendiente
YouTube real integrado en la textura 3D, SponsorBlock y DeArrow conectados a ese reproductor, iconos nativos en los accesos, transiciones visuales, otros cuatro mundos y pruebas de rendimiento en visor. El boton navegador abre una URL con el navegador predeterminado; no incrusta Brave. El selector de apps esta implementado mediante JavaClassWrapper y AndroidRuntime, pero solo se ha validado su comportamiento fuera de Android: falta ejecutarlo en unas Quest.

## Alcance de la unificacion
NebulaVR incorpora y continua el proyecto Godot SmartTube-VR-3D en una unica escena principal y un unico proyecto. SmartTube-VR es una app Android 2D distinta: abrirla desde NebulaVR no equivale a integrar su motor en la pantalla 3D. No se incluye su APK ni se afirma una fusion binaria completa.

Para descubrir apps Android se incluye addons/nebula_apps/nebula-visibility.aar, una biblioteca sin codigo que aporta declaraciones queries al manifiesto al exportar con Gradle. Puede regenerarse con tools/build_visibility_aar.ps1. No solicita QUERY_ALL_PACKAGES.

Referencias revisadas: https://github.com/pilahito/SmartTube-VR-3D y https://github.com/pilahito/SmartTube-VR (launcher y modelo HomeTiles). Se mantienen las licencias de la base y de XR Tools.

El identificador Android original se conserva. Actualizar una APK existente requiere tambien mantener su firma. El repositorio remoto aun no esta renombrado ni contiene estos cambios.
