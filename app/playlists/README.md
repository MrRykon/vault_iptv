# Listas de Vault

Coloca aquí archivos `.m3u` o `.m3u8`, o archivos `.txt` con una URL de lista M3U por línea. Usa fuentes que tengas permiso de reproducir. `demo.m3u` incluye una transmisión pública de prueba, no un paquete de canales comerciales.

El servidor revisa la carpeta cada 30 segundos. Agregar, editar o borrar listas reemplaza el catálogo completo. Si una lista no se puede leer, conserva el último catálogo válido y vuelve a intentarlo. Guarda temporalmente con otra extensión y renómbralo al terminar para evitar lecturas incompletas.

La app sincroniza mientras está abierta y guarda el último catálogo por cuenta. Sin servidor reproduce directamente esos enlaces; necesita Internet y que el proveedor esté disponible. Los cambios hechos con el servidor apagado se incorporan al siguiente arranque. Los dispositivos desconectados recibirán los cambios cuando vuelvan a conectarse.

`start_server.bat` copia las listas locales a los assets antes de una compilación nueva de Flutter. Las URLs de `.txt` se resuelven en el servidor y llegan mediante sincronización; no se empaquetan sus contenidos automáticamente.
