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
    const url = new URL(input);
    const pathname = url.pathname;
    
    switch (platform) {
      case 'tiktok':
        return pathname.replace('/@', '').split('/')[0];
      case 'facebook':
        return pathname.replace('/', '').split('/')[0];
      case 'twitch':
        return pathname.replace('/', '').split('/')[0];
      default:
        return pathname.replace('/', '').split('/')[0];
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