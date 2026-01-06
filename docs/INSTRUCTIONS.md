# Project instructions

This repository exposes an HTTP API (Express) that scrapes social profile data using Puppeteer. It can optionally persist each profile image in maximum available quality.

## High-level architecture

- `index.js`
  - Express server.
  - Defines routes like `GET /<platform>/profile?username_or_link=...`.
  - Each route calls a scraper under `scrapers/`.

- `utils/helpers.js`
  - `extractUsername(input, platform)` normalizes a URL or handle to a username.
  - `createBrowser()` launches Puppeteer with Cloud Run friendly args.
  - `createBrowser()` prefers `puppeteer-core` when installed.

- `scrapers/*.js`
  - Each scraper:
    - Opens a page.
    - Extracts structured fields (name, bio, followers, etc.).
    - Returns a JSON object that includes `profile_image_url` when possible.

- `utils/imageSaver.js`
  - Optional persistence for `profile_image_url`.
  - Downloads the image and stores it either locally or in Google Cloud Storage.

## Installation

From the project root:

```bash
npm install
```

## Puppeteer installation (recommended)

This project can run with either:

- `puppeteer` (downloads a compatible Chromium during install)
- `puppeteer-core` (library only; you provide Chrome/Chromium)

### Option A (simplest): use `puppeteer`

Use this when you run locally and want the least setup.

```bash
npm install
```

No extra environment variables are required.

### Option B (production-friendly): use `puppeteer-core`

Use this when you want to control the Chrome binary (typical in containers/Cloud Run).

You must provide a Chrome/Chromium binary and set:

- `PUPPETEER_EXECUTABLE_PATH=<absolute-path-to-chrome>`

This repository installs `puppeteer-core`, and `utils/helpers.js` will prefer it.

### Avoiding Chromium downloads during install

If `puppeteer` is installed, it may download Chromium during `npm install`.

To prevent that in CI/container builds, set the environment variable during install:

```bash
# PowerShell
$env:PUPPETEER_SKIP_DOWNLOAD = "true"; npm install
```

If you want a strict `puppeteer-core`-only setup, remove `puppeteer` from dependencies and keep `puppeteer-core`.

Dependencies added/used:

- `puppeteer` (already present)
- `puppeteer-core` (added)
- `puppeteer-extra` + `puppeteer-extra-plugin-stealth`
- `@google-cloud/storage` (for Cloud Storage image upload)

## Puppeteer: `puppeteer` vs `puppeteer-core`

- If you use `puppeteer`:
  - A compatible Chromium is downloaded during `npm install`.
  - No system Chrome is required.

- If you use `puppeteer-core`:
  - Chromium is NOT downloaded during installation.
  - You must provide a Chrome/Chromium binary and point to it via `PUPPETEER_EXECUTABLE_PATH`.

This project installs both so you can choose the runtime behavior. `utils/helpers.js` will prefer `puppeteer-core` if available.

## `PUPPETEER_EXECUTABLE_PATH` examples

Windows (local Chrome):

- `C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe`

Linux (common container paths):

- `/usr/bin/google-chrome-stable`
- `/usr/bin/chromium`
- `/usr/bin/chromium-browser`

## Running locally

```bash
node index.js
```

Example requests:

- `http://localhost:8080/twitter/profile?username_or_link=@elonmusk`
- `http://localhost:8080/instagram/profile?username_or_link=@instagram`

## Profile image persistence

### Enable saving

Set:

- `SAVE_IMAGES=true`

### Store in Google Cloud Storage

Set:

- `SAVE_IMAGES=true`
- `GCS_BUCKET=<bucket-name>`

If you run outside of GCP, also set:

- `GOOGLE_APPLICATION_CREDENTIALS=<absolute-path-to-service-account.json>`

### Store locally

If `GCS_BUCKET` is not set, images are saved under:

- `images/<platform>/<username>.<ext>`

### Response fields

When saving is enabled, responses include:

- `profile_image_saved`
- `profile_image_path`
- `profile_image_public_url` (only if available)

## Maximum quality strategy

The image quality depends on the URL the scraper finds.

What we do:

- Prefer the highest-resolution URL exposed by each platform.
- Normalize known patterns where it is safe.

Examples:

- Twitter/X:
  - If the image URL includes `_normal`, the scraper removes that suffix to prefer the original/full-size variant.

- Instagram:
  - Uses `profile_pic_url_hd` when available.

- TikTok:
  - Uses `avatarLarger` when available.

- Deezer:
  - Uses `picture_xl` or a `500x500` URL.

- SoundCloud:
  - Upgrades `-large` to `-t500x500` when possible.

If you need a hard guarantee for maximum available size (even when URLs are blocked), the next step is to implement an avatar element screenshot fallback:

- Find avatar element
- `elementHandle.screenshot()` to a buffer
- Extend `utils/imageSaver.js` with `saveProfileImageBuffer(...)` and store the buffer to GCS/local

## Cloud Run notes

- Cloud Run has ephemeral disk. For durable storage, use `GCS_BUCKET`.
- Recommended IAM for the Cloud Run service account:
  - `roles/storage.objectCreator`

Puppeteer on Cloud Run:

- If you run with `puppeteer-core`, ensure your container image includes Chrome/Chromium.
- Set `PUPPETEER_EXECUTABLE_PATH` to the Chrome binary inside the container.

## Troubleshooting

- If Puppeteer fails to launch with `puppeteer-core`:
  - Ensure `PUPPETEER_EXECUTABLE_PATH` points to a valid Chrome/Chromium binary.
  - Verify it exists in the container/VM.
  - If you are building a container, confirm Chrome dependencies are installed.

## Quick verification checklist

1) Verify the module loads:

```bash
node -e "const {createBrowser}=require('./utils/helpers'); console.log(typeof createBrowser);"
```

2) Run the server:

```bash
node index.js
```

3) Hit a scraper endpoint:

- `http://localhost:8080/twitter/profile?username_or_link=@elonmusk`

4) Verify image saving (optional):

- Set `SAVE_IMAGES=true`
- For GCS, also set `GCS_BUCKET=...` and (outside GCP) `GOOGLE_APPLICATION_CREDENTIALS=...`

- If images do not upload to GCS:
  - Verify `GCS_BUCKET` is correct.
  - Verify service account permissions.
  - If outside GCP, verify `GOOGLE_APPLICATION_CREDENTIALS`.

- If a platform blocks scraping:
  - Expect intermittent failures.
  - Adjust wait times, headers, and extraction strategy.

See also: `docs/IMAGE_STORAGE.md` for storage-specific details.
