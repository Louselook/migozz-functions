const fs = require('fs');
const path = require('path');
const axios = require('axios');

let Storage = null;
try {
  Storage = require('@google-cloud/storage').Storage;
} catch (_) {}

function sanitizeIdentifier(value) {
  const raw = String(value || '').trim();
  if (!raw) return 'unknown';
  // Keep object names and filenames safe (no slashes, query strings, etc.)
  return raw
    .replace(/\?.*$/, '')
    .replace(/\s+/g, '_')
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .slice(0, 120);
}

function ensureDirSync(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function extFromContentType(ct) {
  if (!ct) return '.jpg';
  const type = ct.toLowerCase();
  if (type.includes('png')) return '.png';
  if (type.includes('jpeg') || type.includes('jpg')) return '.jpg';
  if (type.includes('webp')) return '.webp';
  return '.jpg';
}

async function downloadImageStream(url) {
  const response = await axios({
    url,
    method: 'GET',
    responseType: 'stream',
    headers: {
      // Some CDNs require an Accept and UA
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    },
    validateStatus: s => s >= 200 && s < 400
  });
  const contentType = response.headers['content-type'] || 'image/jpeg';
  return { stream: response.data, contentType };
}

async function saveLocal({ platform, username, imageUrl }) {
  const { stream, contentType } = await downloadImageStream(imageUrl);
  const ext = extFromContentType(contentType);
  const safePlatform = sanitizeIdentifier(platform);
  const safeUsername = sanitizeIdentifier(username);
  const dir = path.join(process.cwd(), 'images', safePlatform);
  ensureDirSync(dir);
  const filePath = path.join(dir, `${safeUsername}${ext}`);
  const writeStream = fs.createWriteStream(filePath);
  await new Promise((resolve, reject) => {
    stream.pipe(writeStream);
    writeStream.on('finish', resolve);
    writeStream.on('error', reject);
  });
  return {
    mode: 'local',
    path: filePath,
    publicUrl: null,
    contentType
  };
}

async function saveGCS({ platform, username, imageUrl }) {
  if (!Storage) throw new Error('GCS Storage SDK no disponible');
  const bucketName = process.env.GCS_BUCKET;
  if (!bucketName) throw new Error('Defina GCS_BUCKET para usar almacenamiento en Cloud Storage');
  const storage = new Storage();

  const { stream, contentType } = await downloadImageStream(imageUrl);
  const ext = extFromContentType(contentType);
  const safePlatform = sanitizeIdentifier(platform);
  const safeUsername = sanitizeIdentifier(username);
  const objectName = `profiles/${safePlatform}/${safeUsername}${ext}`;
  const bucket = storage.bucket(bucketName);
  const file = bucket.file(objectName);

  await new Promise((resolve, reject) => {
    const writeStream = file.createWriteStream({
      resumable: false,
      contentType,
      metadata: {
        contentType,
        cacheControl: 'public, max-age=604800'
      }
    });
    stream.pipe(writeStream);
    writeStream.on('finish', resolve);
    writeStream.on('error', reject);
  });

  let publicUrl = null;
  try {
    // If bucket has public access or uniform access, this may work
    publicUrl = `https://storage.googleapis.com/${bucketName}/${objectName}`;
  } catch (_) {}

  return {
    mode: 'gcs',
    path: `gs://${bucketName}/${objectName}`,
    publicUrl,
    contentType
  };
}

/**
 * Saves a profile image (GCS when GCS_BUCKET is set; otherwise local).
 * Controlled by SAVE_IMAGES=true
 */
async function saveProfileImageForProfile({ platform, username, imageUrl }) {
  const saveEnabled = String(process.env.SAVE_IMAGES || '').toLowerCase() === 'true';
  if (!saveEnabled) return null;
  if (!imageUrl) return null;

  if (process.env.GCS_BUCKET) {
    return await saveGCS({ platform, username, imageUrl });
  }

  return await saveLocal({ platform, username, imageUrl });
}

module.exports = {
  saveProfileImageForProfile
};
