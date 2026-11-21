# Actualizaciones OTA

Publica aquí un APK firmado con la misma clave que la instalación inicial. No basta con cambiar archivos Python o Dart: las apps instaladas necesitan una nueva compilación APK y un número de build mayor.

Desde `app/`: `python tools/publish_update.py ruta/al/Vault.apk --version 0.1.0 --build 1 --notes "Primera versión"`.

El lanzador puede compilar y publicar cambios automáticamente si Flutter, Android SDK y `frontend/android/key.properties` están configurados. El lanzador incrementa automáticamente el build al detectar cambios; para publicar manualmente, usa un build mayor. Si la compilación falla, la API inicia y conserva la última publicación válida. No se instala nada en silencio: Android solicita autorización al usuario. El manifiesto se reemplaza atómicamente y el cliente verifica SHA-256 antes de abrir el instalador. En Internet usa HTTPS; en una LAN HTTP no protege frente a un atacante que pueda sustituir tanto APK como manifiesto.

Conserva y respalda tu keystore privado fuera del repositorio. `release.json` y los APK publicados son datos locales ignorados por Git. La API sirve sólo el APK anunciado en el manifiesto.
