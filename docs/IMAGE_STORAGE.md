# Profile image storage

This project scrapes profile data from multiple platforms. Many scrapers already return a `profile_image_url`. We added an optional step that downloads that URL and persists the image.

## What was implemented

- A shared helper that downloads and stores profile images:
  - File: `utils/imageSaver.js`
  - Main function: `saveProfileImageForProfile({ platform, username, imageUrl })`
- The helper is integrated into all scrapers that expose `profile_image_url`.
- When enabled, API responses include these additional fields:
  - `profile_image_saved` (boolean)
  - `profile_image_path` (string): local path or `gs://...`
  - `profile_image_public_url` (string, optional): `https://storage.googleapis.com/...` if applicable

## Where images are stored

Storage selection is controlled by environment variables:

- If `SAVE_IMAGES=true` and `GCS_BUCKET` is set:
  - The image is uploaded to Google Cloud Storage
  - Object name pattern: `profiles/<platform>/<username>.<ext>`
- If `SAVE_IMAGES=true` and `GCS_BUCKET` is not set:
  - The image is saved locally to: `images/<platform>/<username>.<ext>`

Notes:

- `platform` and `username` are sanitized to avoid unsafe characters and path issues.
- The file extension is inferred from the response `Content-Type`.

## Required environment variables

- `SAVE_IMAGES=true` to enable saving.
- `GCS_BUCKET=<bucket-name>` to store in Google Cloud Storage.

Optional:

- `GOOGLE_APPLICATION_CREDENTIALS=<path-to-service-account.json>` when running outside GCP.
- `NODE_ENV=production` for Cloud Run (not required for GCS upload logic, but commonly used).

## Cloud Run setup (recommended)

1. Create a GCS bucket.
2. Ensure the Cloud Run service account has permission to write objects.
   - Typical role: `roles/storage.objectCreator` (and optionally `roles/storage.objectViewer`).
3. Set env vars on the Cloud Run service:
   - `SAVE_IMAGES=true`
   - `GCS_BUCKET=<bucket-name>`

Puppeteer note:

- If you are using `puppeteer-core`, also set `PUPPETEER_EXECUTABLE_PATH` and ensure Chrome/Chromium exists in the container.

Public URL behavior:

- The code returns `profile_image_public_url` using the public URL format.
- This URL works only if your bucket/object is publicly readable, or you handle access in another way.

## Local run

Windows example:

```bash
npm install
set SAVE_IMAGES=true
set GCS_BUCKET=your-bucket-name
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account.json
node index.js
```

If you omit `GCS_BUCKET`, images are stored locally under `images/`.

## Scrapers covered

The image saving hook was added to these scrapers:

- `scrapers/applemusic.js`
- `scrapers/deezer.js`
- `scrapers/discord.js`
- `scrapers/facebook.js`
- `scrapers/instagram.js`
- `scrapers/kick.js`
- `scrapers/linkedin.js`
- `scrapers/pinterest.js`
- `scrapers/reddit.js`
- `scrapers/snapchat.js`
- `scrapers/soundcloud.js`
- `scrapers/spotify.js`
- `scrapers/threads.js`
- `scrapers/tiktok.js`
- `scrapers/trovo.js`
- `scrapers/twitch.js`
- `scrapers/twitter.js`
- `scrapers/youtube.js`

## Puppeteer action plan

- Keep using `puppeteer-extra` with stealth (`utils/helpers.js`).
- Prefer extracting avatar URLs from API responses (GraphQL/JSON) when available.
- Keep DOM and meta tag fallbacks for resilience.
- If an avatar URL is blocked or short-lived, add a last-resort fallback:
  - Locate the avatar element in the DOM
  - Use `elementHandle.screenshot()` to get a buffer
  - Extend `imageSaver` with a `saveProfileImageBuffer(...)` helper to store the buffer into GCS/local

## Compliance and permissions

Make sure you have permission to download and store images, and comply with each platform's Terms of Service, privacy rules, and copyright restrictions.
