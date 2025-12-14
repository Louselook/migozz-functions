const puppeteerExtra = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

puppeteerExtra.use(StealthPlugin());

/**
 * Extrae el username de una URL o lo devuelve limpio si ya es un username
 * @param {string} input - URL o username
 * @param {string} platform - Plataforma (tiktok, facebook, etc.)
 * @returns {string} Username limpio
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
          // URLs como music.apple.com/us/artist/artista/123456
          if (pathname.includes('/artist/')) {
            const parts = pathname.split('/artist/');
            if (parts[1]) {
              const artistPart = parts[1].split('/');
              // Puede ser /artist/nombre/id o /artist/id
              return artistPart[artistPart.length - 1] || artistPart[0];
            }
          }
          return pathname.replace('/', '').split('/')[0];
        case 'deezer':
          // URLs como deezer.com/artist/123456
          if (pathname.includes('/artist/')) {
            return pathname.split('/artist/')[1]?.split('/')[0] || input;
          }
          return pathname.replace('/', '').split('/')[0];
        case 'discord':
          // URLs como discord.gg/codigo o discord.com/invite/codigo
          if (pathname.includes('/invite/')) {
            return pathname.split('/invite/')[1]?.split('/')[0] || input;
          }
          return pathname.replace('/', '').split('/')[0];
        case 'snapchat':
          // URLs como snapchat.com/add/username
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
 * Crea una instancia de navegador Puppeteer con configuración stealth
 * @returns {Promise<Browser>} Instancia del navegador
 */
async function createBrowser() {
  return await puppeteerExtra.launch({
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--window-size=1920,1080',
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process',
      '--disable-blink-features=AutomationControlled'
    ]
  });
}

module.exports = {
  extractUsername,
  createBrowser
};