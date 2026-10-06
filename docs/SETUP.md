# Vault

App privada para Android: biblioteca Plex, Live TV por listas M3U y un espacio independiente para Xtream Codes. Backend FastAPI + SQLite y cliente Flutter. La versión de trabajo es **0.1.0+1**.

## Arrancar en Windows

1. Instala Python 3.12 o posterior. Para compilar la app necesitas Flutter **3.38.4**, un JDK completo Java 17 o 21 y Android SDK; agrega Flutter al PATH.
2. Ejecuta `app/start_server.bat`. Crea el entorno Python, instala las dependencias y muestra las direcciones de red de la PC. En el primer arranque pregunta la contraseña inicial de `admin`. La contraseña se guarda sólo en `.env` y como hash en SQLite, nunca dentro del APK.
3. En la pantalla de login de Android pulsa **Configurar servidor** y escribe una dirección mostrada por el lanzador, por ejemplo `http://192.168.1.20:8000`. Permite TCP 8000 en el firewall de Windows para tu red privada. Puedes compilar con una dirección inicial: `flutter build apk --debug --dart-define=VAULT_SERVER_URL=http://192.168.1.20:8000`.
4. Entra como `admin`. Desde Perfil → Administración puedes crear después tu cuenta normal, suspender o activar usuarios, cambiar contraseñas y enviar notificaciones.

Los archivos privados ignorados por Git no viajan con el repositorio. Introduce la contraseña inicial de administrador en el primer arranque de un checkout nuevo. Para restablecerla después: desde `app/backend`, ejecuta `.venv\Scripts\python.exe ..\tools\reset_admin.py`.

`start_server.bat --skip-build` arranca sólo la API. El lanzador detecta cambios en el cliente, recompila el cliente web y, si hay Android SDK y una clave de firma configurada, compila/publica un APK. No modifica ni publica automáticamente tu código en GitHub. Los clientes abiertos comprueban conexión, avisos y catálogos cada 30 segundos; la disponibilidad de nuevas versiones se consulta al entrar y durante esa sincronización.

## Pantallas y acceso sin servidor

La app abre directamente el login. Después muestra películas/series Plex, avisos del administrador, perfil arriba a la derecha y una barra inferior con **Inicio / Live TV / Xtream**. Perfil incluye información de la app, ajustes y controles admin. Hasta configurar Plex se ven cuadros de demostración identificados como «Próximamente».

El primer login de cada cuenta/dispositivo requiere el servidor. Después puede verificar la contraseña sin servidor usando un verificador PBKDF2-HMAC-SHA256 con sal guardado en almacenamiento seguro. No almacena la contraseña Vault en texto plano. Los catálogos IPTV se guardan por servidor y cuenta; las listas incluidas en el APK sirven como respaldo inicial.

Sin servidor se bloquean Plex, Xtream y administración. Live TV sigue reproduciendo directamente las URLs del último catálogo: requiere Internet y una fuente disponible. Suspensiones, contraseñas cambiadas y borrados no pueden conocerse en un dispositivo desconectado; al reconectar una respuesta 401/403 elimina su acceso offline y exige login. Se respeta la fecha de caducidad ya conocida. Una sesión cuyo token expiró o fue revocado necesita login online nuevamente. Cambiar la IP configurada crea una identidad de servidor distinta para las credenciales locales; usa una IP reservada o un nombre estable.

## Listas IPTV

Usa [app/playlists](../app/playlists/README.md). Admite archivos `.m3u`/`.m3u8` y `.txt` con una URL de lista por línea. El servidor detecta altas, ediciones y bajas cada 30 segundos y al arrancar. Una fuente rota conserva el último catálogo válido. Administración permite sincronizar inmediatamente. `demo.m3u` es un canal HLS público de prueba, no una oferta de canales comerciales.

No se pueden distribuir cambios a una app desconectada: llegan cuando se conecta al servidor. Para incluir tus listas locales en instalaciones nuevas, el lanzador copia las listas a `frontend/assets/playlists` antes de compilar. Tus listas personales se ignoran en Git para no subir URLs privadas por accidente; cópialas y respáldalas junto con los datos del servidor. Agrega sólo enlaces que tengas permiso de usar. Las listas y URLs incluidas en el APK son visibles para sus usuarios.

## Plex y Xtream

En `app/backend/.env`, configura:

```dotenv
MOCK_PLEX=false
PLEX_BASE_URL=http://tu-servidor-plex:32400
PLEX_TOKEN=tu_token_privado
```

Reinicia la API. El catálogo muestra bibliotecas de películas y series, permite navegar temporadas/episodios y sirve el archivo por el backend sin revelar el token Plex. Se usa **Direct Play**, sin transcoding: el dispositivo debe soportar los codecs del archivo. El token se guarda en el servidor. La reproducción Plex está orientada a Android; los navegadores pueden limitar los encabezados de autenticación del reproductor web.

Xtream pide URL, usuario y contraseña del proveedor en su propia pestaña. Consulta TV, películas y series a través de Vault, y reproduce las URLs suministradas por el proveedor. Se puede guardar la conexión en el almacenamiento seguro del dispositivo; el backend no persiste esas credenciales. Requiere una cuenta activa, un proveedor con dirección pública y acceso de red del servidor a ese proveedor. Los perfiles infantiles no tienen acceso a Xtream; las listas IPTV y Plex se filtran por sus categorías/etiquetas infantiles.

## OTA y firma Android

Las actualizaciones de Python se aplican al reiniciar el servidor. Los cambios de Dart necesitan un APK nuevo. Para compilaciones manuales aumenta `version: x.y.z+N` en `app/frontend/pubspec.yaml` y conserva **la misma clave de firma** para todas las instalaciones y actualizaciones. `N` debe aumentar en cada publicación. El lanzador calcula automáticamente un build mayor al último publicado cuando detecta cambios; usa `--build-number` sin modificar tu `pubspec.yaml`. Puedes cambiar la versión visible en `pubspec.yaml` cuando quieras anunciar una versión nueva.

Crea un keystore privado y configura `app/frontend/android/key.properties` (ignorado por Git):

```properties
storeFile=C:/ruta/privada/vault-release.jks
storePassword=tu_clave_del_keystore
keyAlias=vault
keyPassword=tu_clave_de_la_key
```

No subas ese archivo ni el keystore al repositorio. `start_server.bat` puede compilar/publicar con esa configuración. También puedes compilar manualmente con `flutter build apk --release` y publicar desde `app/`:

```console
python tools/publish_update.py frontend/build/app/outputs/flutter-apk/app-release.apk --version 0.1.0 --build 1 --notes "Primera versión"
```

Si Flutter cambia el nombre del APK a `Vault_v0.1.0.apk`, usa ese archivo. Antes de publicar verifica versión, build y firma con `apkanalyzer`/`apksigner`; la publicación comprueba formato ZIP, presencia de AndroidManifest, SHA-256 y número de build creciente, pero no sustituye la validación Android del APK. Una compilación debug sirve para probar; no se actualiza sobre una instalación firmada con otra clave.

La API anuncia sólo un APK existente y con checksum válido. La app compara versión/build, descarga desde su servidor, verifica SHA-256 y abre el instalador Android. El usuario autoriza la instalación. No basta con cambiar un número en un archivo para enviar cambios de código a una app instalada. En Internet usa HTTPS; en LAN HTTP, el checksum detecta corrupción pero no autentica frente a alguien capaz de sustituir APK y manifiesto.

## Mantenimiento y Raspberry Pi 5

Con la app/build detenidos ejecuta `app/maintenance.bat` para borrar caches Python, resultados de compilación Flutter, `.dart_tool`, caché local Gradle y temporales de publicación. `maintenance.bat --dry-run` muestra qué borraría. Conserva SQLite, `.env`, listas, APK publicados, código y contenido multimedia; no intenta adivinar qué archivos fuente «ya no se usan».

En Raspberry Pi, copia la carpeta `app` junto con una copia segura de `.env`, SQLite, listas y publicaciones; instala Python 3.12+ y ejecuta `bash start_server.sh --skip-build`. Compila APK en Windows y transfiere los APK publicados al Pi. Reserva una dirección de red o configura un dominio para evitar reconfigurar todos los dispositivos. Este lanzador Linux se comparte con Windows; el despliegue en hardware Pi aún debe comprobarse allí.

## Vista HTML y publicación web

`web/index.html` funciona sin compilación ni dependencias externas. Para servirla localmente: desde la raíz del repositorio ejecuta `python -m http.server 8080 --directory web`. El backend también sirve esta vista en `/preview/`, manteniendo el cliente Flutter en `/`.

Puedes cambiar entre Web, Android y Chromecast/TV. La vista TV acepta flechas y Enter como un mando; en un dispositivo pequeño el marco TV se desplaza horizontalmente. No realiza casting ni instala una app en un Chromecast. La demostración muestra contenido ilustrativo. El login real requiere un servidor Vault, y la sesión vive sólo en memoria. Para conectar desde GitHub Pages, el servidor y las fuentes de reproducción deben usar HTTPS y ser accesibles desde el navegador. El reproductor usa los formatos admitidos nativamente por el navegador; Plex se reproduce con el cliente Android.

Para publicar, abre el repositorio en GitHub → **Settings → Pages → Source → GitHub Actions**. El workflow `Publish Vault HTML` publica la carpeta `web` al recibir cambios en `main`; también se puede ejecutar manualmente desde Actions. La URL prevista es `https://mrrykon.github.io/vault_iptv/`. La activación de Pages y la primera publicación deben completarse en GitHub antes de que ese enlace funcione.

## Pruebas

Desde `app/backend`: `.venv/bin/python -m unittest discover -s tests -v` (Windows: `.venv\Scripts\python.exe`). Las pruebas usan SQLite, listas y publicaciones temporales.

Desde `app/frontend`: `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`, `flutter build web --no-pub`. Prueban autenticación offline, aislamiento de cuentas/servidores, rechazo de cuentas suspendidas, lectura M3U, comparación OTA y pantalla de login.

No conectamos todavía servidores Plex/Xtream reales ni instalamos en un dispositivo Android. En el navegador, el almacenamiento seguro necesita HTTPS o localhost; para uso en LAN sin HTTPS utiliza la app Android. El cliente web generado se puede servir con `WEB_CLIENT_DIR` o mediante el lanzador, sin sobrescribir el bundle antiguo versionado en `backend/app/web_client`.
