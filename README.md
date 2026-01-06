# Migozz Scraper Service

Servicio de scraping para redes sociales (TikTok, Facebook, Instagram, Twitter, YouTube, etc.) basado en Express y Puppeteer con stealth.

## Estructura del Proyecto

```
project/
│
├── index.js                    # Servidor Express principal
│
├── utils/
│   └── helpers.js             # Funciones auxiliares (extractUsername, createBrowser)
│
└── scrapers/
    ├── tiktok.js              # Scraper de TikTok
    ├── facebook.js            # Scraper de Facebook
    ├── twitch.js              # Scraper de Twitch
    └── kick.js                # Scraper de Kick
```

## Instalación

```bash
npm install
```

## Uso

```bash
node index.js
```

## Endpoints Disponibles

- `GET /<plataforma>/profile?username_or_link=xxx` (ver lista en `/`)

Ejemplos locales:

- http://localhost:8080/twitter/profile?username_or_link=@elonmusk
- http://localhost:8080/instagram/profile?username_or_link=@instagram

## Guardado de imágenes de perfil

- Si `SAVE_IMAGES=true`, al extraer un perfil se descargará la imagen (`profile_image_url`) y se guardará:
  - En desarrollo: `images/<plataforma>/<username>.<ext>`.
  - En Cloud Storage si `GCS_BUCKET` está definido: `gs://<bucket>/profiles/<plataforma>/<username>.<ext>` y `profile_image_public_url` si el bucket es público.
- Respuesta añade campos: `profile_image_saved`, `profile_image_path`, `profile_image_public_url`.

### Variables de entorno

- `SAVE_IMAGES=true` para activar guardado.
- `GCS_BUCKET` nombre del bucket en Cloud Storage.
- `GOOGLE_APPLICATION_CREDENTIALS` ruta de credenciales fuera de GCP.
- `NODE_ENV=production` para despliegue.
- `PUPPETEER_EXECUTABLE_PATH` si usas Chrome del sistema.

### Ejecución local con guardado

```bash
set SAVE_IMAGES=true
node index.js
```

## Cómo agregar una nueva red social

1. Crear un nuevo archivo en `scrapers/` (ej: `instagram.js`)
2. Importarlo en `index.js`
3. Agregar la ruta correspondiente
4. Agregar la plataforma al array de plataformas en la ruta `/`

Ejemplo:

```javascript
// En index.js
const scrapeInstagram = require('./scrapers/instagram');

app.get('/instagram/profile', async (req, res) => {
  // ... lógica de la ruta
});
```

## Plan de acción con Puppeteer

- Stealth y UA de escritorio ya configurados en `utils/helpers.js`.
- Interceptar API/GraphQL cuando exista (Twitter/Instagram) y fallback al DOM/meta.
- Para avatares, preferir URLs en alta resolución; si la URL falla, último recurso: `element.screenshot()` del avatar y guardar el buffer.
- Persistencia de imágenes: usar `GCS_BUCKET` en producción para evitar disco efímero en Cloud Run.

## Cumplimiento y permisos

Respeta Términos de Servicio, derechos de autor y privacidad de cada plataforma. Asegúrate de tener permisos para almacenar imágenes.
