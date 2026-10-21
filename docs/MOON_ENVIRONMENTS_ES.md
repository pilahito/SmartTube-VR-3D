# Entornos Moon y panoramas propios en NebulaVR

## Disponible en esta versión

En **Entornos** hay dos accesos nuevos:

- **Moon ↗** abre `https://moonvrhome.com/es/environments` en el navegador externo. No descarga automáticamente contenido ni instala hogares en el sistema. Android puede pausar NebulaVR mientras otra aplicación está en primer plano.
- **Mis panoramas** muestra hasta 128 imágenes locales, ordenadas por nombre, con cuatro elementos por página. **Actualizar** vuelve a leer la carpeta. Elegir una imagen cambia el fondo del cine sin recrear el reproductor, modificar su volumen ni pausar el vídeo.

Se admiten panoramas equirectangulares monoscópicos **PNG/JPEG 2:1**, desde 64×32 hasta **4096×2048**, con un máximo de **16 MiB** por archivo. Se validan las dimensiones del encabezado antes de descomprimir para limitar la memoria. Lectura y decodificación usan un único hilo secundario; la textura se crea en el hilo principal. El panorama anterior se libera al cambiar de mundo. Si falla la carga se conserva el entorno actual. Seleccionar un mundo integrado cancela la aplicación de una carga pendiente.

Son fondos 360°: siguen la orientación de la cabeza pero no tienen profundidad ni paralaje al caminar. La pantalla y los controles continúan siendo objetos 3D. Hay un suelo físico invisible para mantener al usuario estable. No son modelos 3D navegables.

## Añadir imágenes

Pulsa **Mis panoramas → Importar imagen**. Se solicita el selector de archivos nativo de Godot (`FileDialog`, acceso al sistema de archivos, filtro MIME PNG/JPEG). En Android se comprueba que el sistema anuncie soporte. El archivo seleccionado se valida y copia en segundo plano a la biblioteca privada, con nombre por hash de contenido para evitar duplicados; después se aplica. Cancelar el diálogo no cambia el entorno. El diálogo del sistema puede poner NebulaVR en segundo plano: no se garantiza reproducción continua mientras se selecciona el archivo. La ruta de importación y la copia se prueban en escritorio; **el diálogo y las URI de proveedores de documentos siguen pendientes de validar en Quest física**.


Usa imágenes propias o cuyo autor permita este uso. Esta versión carga archivos de la carpeta privada `user://panoramas`, creada al entrar en Mis panoramas. No pide acceso a todo el almacenamiento ni instala APK.

En Quest conectado por ADB, abre primero Mis panoramas. Para una compilación de depuración con `run-as` habilitado:

```bash
adb shell run-as app.smarttube.vr3d mkdir -p files/panoramas
adb push bosque.jpg /data/local/tmp/nebula-panorama.jpg
adb shell run-as app.smarttube.vr3d cp /data/local/tmp/nebula-panorama.jpg files/panoramas/bosque.jpg
adb shell rm /data/local/tmp/nebula-panorama.jpg
```

`user://` usa el directorio de datos de Godot; comprueba su ruta con `OS.get_user_data_dir()` en tu exportación. Si Godot usa almacenamiento externo, copia a esa ruta en lugar de `files`. En un APK release Android puede impedir `run-as`: usa el botón Importar imagen si el visor ofrece el selector de documentos. Su compatibilidad con los proveedores de archivos del visor aún requiere prueba física. En escritorio, copia directamente a la ruta de datos del proyecto (Linux: normalmente `~/.local/share/godot/app_userdata/NebulaVR/panoramas`).

Vuelve a la aplicación, pulsa Actualizar y elige tu panorama. Los archivos permanecen en la carpeta para futuras sesiones; el entorno activo no se restaura automáticamente. Eliminar una imagen de esa carpeta la quita de la lista al actualizar.

## Qué significa la compatibilidad con Moon

Fuentes consultadas el 21 de octubre de 2026:

- https://moonvrhome.com/es/environments
- https://moonvrhome.com/es/faq
- https://moonvrhome.com/es/download
- https://moonvrhome.com/terms

Moon diferencia skyboxes de hogares personalizados: los hogares se instalan mediante su Companion y aparecen en los ajustes de entornos de Quest. Instalar uno en el sistema no lo convierte en una escena de NebulaVR. Su FAQ menciona imágenes locales JPG/PNG y recursos comprimidos KTX2. La documentación pública consultada no ofrece una API de catálogo/exportación para terceros que se haya integrado aquí, ni una licencia general de redistribución de toda la colección.

NebulaVR enlaza el catálogo oficial y permite cargar panoramas compatibles que hayas obtenido con permiso. No incluye miniaturas o modelos extraídos de Moon, no descompila hogares APK, no carga PCK/scripts ajenos y no promete que todos sus entornos se puedan importar. Para importar modelos 3D completos hace falta un formato exportable y autorización del creador, más un importador con límites de geometría, texturas y materiales; no está incluido en este cambio.

## Verificación y rendimiento

`tests/panoramas.gd` comprueba PNG/JPEG, encabezados inválidos, dimensiones excesivas y proporción incorrecta, carga asíncrona exclusiva, importación y deduplicación, cancelación de resultados, cambios entre panorama/bosque/playa y conservación de reproductor/pausa. `tests/ui.gd` cubre entrada/salida de la biblioteca y límites del panel. Se ejecutan en CI junto con smoke/apps.

La preferencia OpenXR existente sigue solicitando 120 Hz cuando el runtime lo ofrece, con alternativas 90/80/72. Un panorama no implica que el visor sostenga 120 FPS: hay que medir creación de textura, tiempos CPU/GPU y temperatura en Quest real. No se han validado esos resultados en hardware con este cambio.
