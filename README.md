# Migozz Scraper Service

Servicio de scraping para redes sociales (TikTok, Facebook).

## 📁 Estructura del Proyecto

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
    └── facebook.js            # Scraper de Facebook
```

## 🚀 Instalación

```bash
npm install express puppeteer-extra puppeteer-extra-plugin-stealth cors
```

## 💻 Uso

```bash
node index.js
```

## 📡 Endpoints Disponibles

- `GET /tiktok/profile?username_or_link=xxx`
- `GET /facebook/profile?username_or_link=xxx`

## ✨ Ventajas de esta Estructura

1. **Modularidad**: Cada scraper está en su propio archivo
2. **Mantenibilidad**: Más fácil de mantener y actualizar
3. **Escalabilidad**: Agregar nuevas redes sociales es simple
4. **Organización**: Código limpio y bien estructurado
5. **Reutilización**: Las utilidades están centralizadas

## 📝 Cómo agregar una nueva red social

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
