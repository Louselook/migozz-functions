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
 * Crea una instancia de navegador Puppeteer con configuración optimizada para Cloud Run
 * @returns {Promise<Browser>} Instancia del navegador
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

  // En producción, usar el ejecutable configurado
  if (isProduction && process.env.PUPPETEER_EXECUTABLE_PATH) {
    config.executablePath = process.env.PUPPETEER_EXECUTABLE_PATH;
  }

  try {
    const browser = await puppeteerExtra.launch(config);
    console.log('✅ Browser launched successfully');
    return browser;
  } catch (error) {
    console.error('❌ Error launching browser:', error.message);
    throw error;
  }
}

/**
 * ✅ NUEVA: Función helper para esperar (reemplazo de waitForTimeout)
 * @param {number} ms - Milisegundos a esperar
 * @returns {Promise<void>}
 */
async function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = {
  extractUsername,
  createBrowser,
  wait  // ✅ Exportar la nueva función
};