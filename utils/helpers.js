const puppeteerExtraBase = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

// Prefer puppeteer-core (system Chrome) when provided; fall back to full puppeteer.
let puppeteer;
if (process.env.PUPPETEER_EXECUTABLE_PATH) {
  try {
    const puppeteerCore = require('puppeteer-core');
    puppeteer = puppeteerExtraBase.addExtra(puppeteerCore);
  } catch (_) {
    // If core missing, try full
    const puppeteerFull = require('puppeteer');
    puppeteer = puppeteerExtraBase.addExtra(puppeteerFull);
  }
} else {
  // Local development or no path provided -> use full puppeteer (bundled Chromium)
  try {
    const puppeteerFull = require('puppeteer');
    puppeteer = puppeteerExtraBase.addExtra(puppeteerFull);
  } catch (_) {
    // Fallback to core if full not present (unlikely if installed)
    const puppeteerCore = require('puppeteer-core');
    puppeteer = puppeteerExtraBase.addExtra(puppeteerCore);
  }
}

puppeteer.use(StealthPlugin());

/**
 * Extracts the username from a URL, or returns a cleaned username.
 * @param {string} input - URL or username
 * @param {string} platform - Platform (tiktok, facebook, etc.)
 * @returns {string} Clean username
 */
function extractUsername(input, platform) {
  if (!input) return '';
  input = input.trim();

  if (input.startsWith('http://') || input.startsWith('https://')) {
    try {
      const url = new URL(input);
      const pathname = url.pathname;

      switch (platform) {
        case 'tiktok':
          return pathname.replace('/@', '').split('/')[0];
        case 'facebook':
          return pathname.replace('/', '').split('/')[0];
        case 'twitch':
          return pathname.replace('/', '').split('/')[0];
        case 'kick':
          return pathname.replace('/', '').split('/')[0];
        case 'trovo':
          if (pathname.startsWith('/s/')) {
            return pathname.replace('/s/', '').split('/')[0];
          }
          return pathname.replace('/', '').split('/')[0];
        case 'youtube':
          if (pathname.startsWith('/@')) {
            return pathname.replace('/@', '').split('/')[0];
          }
          if (pathname.startsWith('/channel/')) {
            return pathname.replace('/channel/', '').split('/')[0];
          }
          if (pathname.startsWith('/c/')) {
            return pathname.replace('/c/', '').split('/')[0];
          }
          return pathname.replace('/', '').split('/')[0];
        case 'instagram':
          return pathname.replace('/', '').split('/')[0];
        case 'twitter':
          return pathname.replace('/', '').split('/')[0];
        case 'threads':
          return pathname.replace('/@', '').replace('/', '').split('/')[0];
        case 'spotify':
          if (pathname.includes('/artist/')) {
            return pathname.split('/artist/')[1]?.split('/')[0] || input;
          }
          return input;
        case 'reddit':
          if (pathname.startsWith('/r/')) {
            return 'r/' + pathname.replace('/r/', '').split('/')[0];
          }
          if (pathname.startsWith('/user/') || pathname.startsWith('/u/')) {
            return 'u/' + pathname.replace('/user/', '').replace('/u/', '').split('/')[0];
          }
          return pathname.replace('/', '').split('/')[0];
        case 'rumble':
          if (pathname.startsWith('/c/')) {
            return pathname.replace('/c/', '').split('/')[0];
          }
          return pathname.replace('/', '').split('/')[0];
        case 'linkedin':
          if (pathname.startsWith('/in/')) {
            return pathname.replace('/in/', '').split('/')[0];
          }
          if (pathname.startsWith('/company/')) {
            return pathname.replace('/company/', '').split('/')[0];
          }
          return pathname.replace('/', '').split('/')[0];
        case 'pinterest':
          return pathname.replace('/', '').split('/')[0];
        case 'soundcloud':
          return pathname.replace('/', '').split('/')[0];
        case 'applemusic':
          if (pathname.includes('/artist/')) {
            const parts = pathname.split('/artist/');
            if (parts[1]) {
              const artistPart = parts[1].split('/');
              return artistPart[artistPart.length - 1] || artistPart[0];
            }
          }
          return pathname.replace('/', '').split('/')[0];
        case 'deezer':
          if (pathname.includes('/artist/')) {
            return pathname.split('/artist/')[1]?.split('/')[0] || input;
          }
          return pathname.replace('/', '').split('/')[0];
        case 'discord':
          if (pathname.includes('/invite/')) {
            return pathname.split('/invite/')[1]?.split('/')[0] || input;
          }
          return pathname.replace('/', '').split('/')[0];
        case 'snapchat':
          if (pathname.includes('/add/')) {
            return pathname.split('/add/')[1]?.split('/')[0] || input;
          }
          return pathname.replace('/', '').split('/')[0];
        default:
          return pathname.replace('/', '').split('/')[0];
      }
    } catch (e) {
      return input;
    }
  }

  return input.replace('@', '');
}

/**
 * Creates a Puppeteer browser instance with Cloud Run friendly defaults.
 * Notes:
 * - If you install `puppeteer-core`, you must provide Chrome via `PUPPETEER_EXECUTABLE_PATH`.
 * - If you install `puppeteer`, Chromium is downloaded automatically during `npm install`.
 * @returns {Promise<Browser>} Browser instance
 */
async function createBrowser() {
  const isProduction = process.env.NODE_ENV === 'production';

  const config = {
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--disable-software-rasterizer',
      '--disable-extensions',
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process',
      '--disable-blink-features=AutomationControlled',
      '--no-first-run',
      '--no-zygote',
      '--disable-background-timer-throttling',
      '--disable-backgrounding-occluded-windows',
      '--disable-renderer-backgrounding',
      '--window-size=1920,1080',
    ]
  };

  // Use system Chrome when provided (recommended with puppeteer-core)
  if (process.env.PUPPETEER_EXECUTABLE_PATH) {
    config.executablePath = process.env.PUPPETEER_EXECUTABLE_PATH;
  }

  try {
    const browser = await puppeteer.launch(config);
    console.log('Browser launched successfully');
    return browser;
  } catch (error) {
    console.error('Error launching browser:', error.message);
    throw error;
  }
}

/**
 * Wait helper (replacement for page.waitForTimeout).
 * @param {number} ms - Milliseconds
 * @returns {Promise<void>}
 */
async function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Sanitizes profile data to enforce strict public-data policy.
 * Masks or removes private/sensitive fields based on platform.
 * @param {Object} data - Raw profile data
 * @param {string} platform - Platform name (instagram, tiktok, linkedin)
 * @returns {Object} Sanitized data
 */
function sanitizeProfile(data, platform) {
  if (!data) return null;

  const allowedFieldsBase = ['id', 'username', 'full_name', 'profile_image_url', 'followers', 'verified', 'url', 'platform', 'profile_image_saved', 'profile_image_path', 'profile_image_public_url'];

  // Platform-specific allowances
  const platformAllowances = {
    instagram: [], // Only base fields
    tiktok: [],    // Only base fields
    linkedin: [],  // Only base fields
    // Other platforms can retain their current behavior or be restricted later
    default: []
  };

  const allowed = new Set([...allowedFieldsBase, ...(platformAllowances[platform] || [])]);
  const sanitized = {};

  // For platforms not strictly enforced yet, return original data (optional strategy)
  // But for the target 3, we enforce strictness.
  const strictPlatforms = ['instagram', 'tiktok', 'linkedin'];
  if (!strictPlatforms.includes(platform)) {
    return data;
  }

  Object.keys(data).forEach(key => {
    if (allowed.has(key)) {
      sanitized[key] = data[key];
    }
  });

  return sanitized;
}

module.exports = {
  extractUsername,
  createBrowser,
  wait,
  sanitizeProfile
};