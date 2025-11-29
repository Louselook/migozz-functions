# Migozz Scraper Service

Servicio de scraping para redes sociales (TikTok, Instagram, LinkedIn, Facebook).

## Tecnologías

- Node.js + Express
- Puppeteer + Stealth Plugin
- Docker

## Rutas

- `GET /tiktok/profile?username_or_link=xxx`
- `GET /instagram/profile?username_or_link=xxx`
- `GET /linkedin/profile?username_or_link=xxx`
- `GET /facebook/profile?username_or_link=xxx`

## Desarrollo local
```bash
npm install
node index.js
```

## Deploy a Cloud Run
```bash
gcloud run deploy migozz-scraper \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 2Gi \
  --timeout 60s
```