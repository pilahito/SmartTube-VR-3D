# SmartTube VR 3D 🏝️

Una playa **en 3D de verdad** para las Meta Quest, con una pantalla de cine gigante delante de ti.
No es una foto de fondo: hay mar con olas que se mueven, arena por la que puedes caminar
(teletransporte), palmeras, sol, y sonido del mar y del viento a tu alrededor.

Es la **fase 1** del salto de [SmartTube VR](https://github.com/pilahito/SmartTube-VR) a mundos inmersivos,
hecha con **Godot 4.7.2** y OpenXR.

> ⚠️ Versión de prueba. Se compila y se firma automáticamente en GitHub, pero todavía no se ha probado en unas Quest reales.

## Qué trae

- **Playa inmersiva**: océano animado (olas Gerstner y espuma en la orilla), arena con dunas y zona mojada,
  cielo procedural con sol, 10 palmeras y rocas hechas por código, niebla suave en el horizonte.
- **Sonido ambiente**: olas en 3D (las oyes venir del mar) y viento suave. Generados por código (CC0).
- **Pantalla de cine curva** flotando delante, con un vídeo de prueba (Big Buck Bunny).
- **Panel de control** que se maneja con el rayo láser de los mandos.

## Controles

| Acción | Cómo |
|---|---|
| Pulsar botones del panel | Apunta con el láser (cualquier mando) y aprieta el **gatillo** |
| Reproducir / pausa, ±10 s, volumen | Botones y barra del panel |
| Acercar / alejar, agrandar / achicar la pantalla | Botones del panel |
| Centrar la vista | Botón **Centrar** |
| Mostrar / ocultar el panel | Botón **B** (mando derecho) |
| Girar | **Joystick derecho** izquierda/derecha (giro por pasos de 30°) |
| Moverte por la arena | Mantén el **grip** del mando izquierdo, apunta y suelta (teletransporte) |
| Salir | Botón **Salir** |

## Instalar en las Quest

1. Descarga el APK `SmartTube_VR_3D.apk` (en *Actions* → último build → artefacto `SmartTube_VR_3D-apk`, o en *Releases* cuando se publique).
2. Instálalo con SideQuest o con `adb install SmartTube_VR_3D.apk` (las Quest deben estar en modo desarrollador).
3. Ábrelo desde **Biblioteca → Orígenes desconocidos**.

Todas las versiones van firmadas con la misma clave, así que las nuevas se instalan encima sin perder nada.

## Abrir el proyecto en tu PC

Abre la carpeta con **Godot 4.7.2-stable** (*Importar* → `project.godot`). Para exportar a Quest necesitas
las plantillas de exportación de Android de la 4.7.2, el Android SDK (plataforma 36, build-tools 36.1.0) y JDK 17.

## Rendimiento (objetivo 72–90 fps en Quest 2/3)

- Renderizador **Mobile** (Vulkan), MSAA 2×.
- **Foveación** fija nivel alto + dinámica (OpenXR).
- Pide 90 Hz si el visor lo permite; si no, 72 Hz.
- Todo procedural y con pocos polígonos: sin texturas pesadas, una sola luz con sombras cortas (30 m), océano opaco.

## Vídeo: cómo funciona en la fase 1

En esta fase el vídeo es un **clip OGV (Theora) incluido en la app** que se reproduce con `VideoStreamPlayer`
dentro de un `SubViewport`, proyectado en la pantalla curva. Es lo más seguro para empezar, pero la calidad
es limitada (854×480).

En la fase 2 se cambiará por una **capa de composición OpenXR con superficie Android** (`OpenXRCompositionLayer`
+ `use_android_surface`) alimentada por ExoPlayer desde un plugin Kotlin: calidad nativa y vídeos de YouTube reales.

## Plan (fase 2)

- Reproducción real de YouTube (extractor de SmartTube / NewPipeExtractor) en la superficie Android nativa.
- Búsqueda y navegación de vídeos en un panel 3D.
- SponsorBlock y DeArrow, como en SmartTube VR.
- Más mundos: playa al atardecer y de noche, bosque mágico, salones, cine.
- Seguimiento de manos.

## Créditos y licencias

- Código de este proyecto: **MIT** (ver `LICENSE`).
- [Godot Engine](https://godotengine.org) — MIT.
- [Godot OpenXR Vendors](https://github.com/GodotVR/godot_openxr_vendors) 5.1.0 — MIT (incluye el OpenXR loader de Meta con su licencia en `addons/godotopenxrvendors/meta/`).
- [Godot XR Tools](https://github.com/GodotVR/godot-xr-tools) 4.5.2 — MIT.
- Vídeo de prueba: fragmento de **Big Buck Bunny** © Blender Foundation, [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) — peach.blender.org.
- Sonidos de olas y viento: generados por código para este proyecto, dominio público (CC0).
