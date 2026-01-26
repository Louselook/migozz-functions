const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

// Singleton browser instance for reuse across requests (Cloud Run / Hot Lambda)
let browserInstance = null;

async function getBrowser() {
  if (browserInstance && browserInstance.isConnected()) {
    return browserInstance;
  }
  console.log('🚀 [YouTube] Launching new browser instance...');
  browserInstance = await createBrowser();
  return browserInstance;
}

/**
 * Scraper para canales de YouTube - VERSIÓN OPTIMIZADA
 * Devuelve:
 *  - followers: int | null (suscriptores)
 *  - videos: int (0 si no se encuentra)
 */
async function scrapeYouTube(channelInput) {
  console.log(`📥 [YouTube] Iniciando scraping para: ${channelInput}`);

  let page;
  try {
    const browser = await getBrowser();
    page = await browser.newPage();

    // Optimización 1: Bloquear recursos innecesarios
    await page.setRequestInterception(true);
    page.on('request', (req) => {
      const resourceType = req.resourceType();
      if (['image', 'stylesheet', 'font', 'media', 'other'].includes(resourceType)) {
        req.abort();
      } else {
        req.continue();
      }
    });

    await page.setViewport({ width: 1280, height: 720 }); // Menor resolución para ahorrar recursos
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // ---------------- URL base ----------------
    let url;
    if (channelInput.startsWith('http')) {
      url = channelInput;
    } else if (channelInput.startsWith('UC') && channelInput.length === 24) {
      url = `https://www.youtube.com/channel/${channelInput}`;
    } else if (channelInput.startsWith('@')) {
      url = `https://www.youtube.com/${channelInput}`;
    } else {
      url = `https://www.youtube.com/@${channelInput}`;
    }

    console.log(`🌐 [YouTube] Navegando a: ${url}`);

    // Optimización 2: waiting menos estricto (domcontentloaded vs networkidle2)
    // Timeout reducido a 15s para fail-fast
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });

    // Optimización 3: Reemplazar sleep fijo por waitForSelector dinámico
    try {
      // Esperar a que aparezca el header o metadata clave
      await page.waitForSelector('ytd-c4-tabbed-header-renderer, #meta, #channel-header', { timeout: 5000 });
    } catch {
      console.log('⚠️ [YouTube] Selector principal no encontrado rápido, continuando...');
    }

    // ---------------- Extracción ----------------
    let data = await page.evaluate(() => {
      // Función parseNumber inyectada
      const parseNumber = (text) => {
        if (!text) return null;

        let cleaned = String(text).trim();
        const match = cleaned.match(/([\d\.,]+)\s*([KkMmBb])?/);
        if (!match) return null;

        let numStr = match[1];
        const suffix = (match[2] || '').toUpperCase();

        if (numStr.includes('.') && numStr.includes(',')) {
          numStr = numStr.replace(/\./g, '').replace(',', '.');
        } else if (numStr.includes(',')) {
          numStr = numStr.replace(',', '.');
        } else if (numStr.includes('.') && numStr.split('.')[1]?.length >= 3) {
          numStr = numStr.replace(/\./g, '');
        }

        let num = parseFloat(numStr);

        if (suffix === 'K') num *= 1000;
        if (suffix === 'M') num *= 1000000;
        if (suffix === 'B') num *= 1000000000;

        if (!isFinite(num)) return null;
        return Math.round(num);
      };

      const safeText = (node) => node ? (node.textContent || node.innerText || '').trim() : '';

      let channelName = '';
      let channelId = '';
      let handle = '';
      let profileImageUrl = '';
      let followers = null;
      let videos = 0;

      // 1) ytInitialData (Suele ser lo más rápido y fiable)
      try {
        const ytData = window.ytInitialData;
        if (ytData) {
          const header = ytData?.header?.c4TabbedHeaderRenderer;
          const metadata = ytData?.metadata?.channelMetadataRenderer;

          if (header) {
            channelName = header.title || channelName;
            channelId = header.channelId || channelId;

            if (header.channelHandleText?.runs?.[0]?.text) {
              handle = header.channelHandleText.runs[0].text.replace('@', '');
            }

            if (header.avatar?.thumbnails?.length) {
              profileImageUrl = header.avatar.thumbnails.at(-1).url || profileImageUrl;
            }

            if (header.subscriberCountText) {
              if (header.subscriberCountText.simpleText) {
                followers = parseNumber(header.subscriberCountText.simpleText);
              } else if (header.subscriberCountText.runs?.[0]?.text) {
                followers = parseNumber(header.subscriberCountText.runs[0].text);
              }
            }

            if (header.videosCountText) {
              if (header.videosCountText.simpleText) {
                videos = parseNumber(header.videosCountText.simpleText) || 0;
              } else if (header.videosCountText.runs?.[0]?.text) {
                videos = parseNumber(header.videosCountText.runs[0].text) || 0;
              }
            }
          }

          if (metadata) {
            if (!channelName) channelName = metadata.title;
            if (!channelId) channelId = metadata.externalId;
            if (!profileImageUrl && metadata.avatar?.thumbnails?.[0]?.url) {
              profileImageUrl = metadata.avatar.thumbnails[0].url;
            }
          }
        }
      } catch (e) {
        // Ignorar errores de parsing
      }

      // Si ya tenemos todo, retornar rápido
      if (followers !== null && videos > 0 && channelName) {
        return { channelName, channelId, handle, profileImageUrl, followers, videos };
      }

      // 2) Selectores DOM (Fallback)
      try {
        const metaTags = {
          title: document.querySelector('meta[property="og:title"]'),
          image: document.querySelector('meta[property="og:image"]'),
          url: document.querySelector('meta[property="og:url"]')
        };

        if (!channelName && metaTags.title) channelName = metaTags.title.content;
        if (!profileImageUrl && metaTags.image) profileImageUrl = metaTags.image.content;

        // Intentar sacar followers del DOM visible
        if (followers === null) {
          // Estrategia: Buscar nodo que contenga "subscribers" o "suscriptores"
          const allText = document.body.innerText;
          const subsMatch = allText.match(/([\d\.,]+\s*[KkMmBb]?)\s*(?:suscriptore?s?|subscribere?s?)/i);
          if (subsMatch) {
            followers = parseNumber(subsMatch[1]);
          }
        }
      } catch (e) { }

      return { channelName, channelId, handle, profileImageUrl, followers, videos };
    });

    console.log(`📊 [YouTube] Datos extraídos (Iteración 1):`, data);

    // ---------------- Fallback: /about page (Solo si falta info crítica) ----------------
    // Optimización: Solo ir a /about si realmente no tenemos followers
    if (data.followers === null) {
      try {
        const aboutUrl = url.replace(/\/$/, '') + '/about';
        console.log(`🔎 [YouTube] Followers no encontrados, saltando a /about: ${aboutUrl}`);

        await page.goto(aboutUrl, { waitUntil: 'domcontentloaded', timeout: 10000 });

        const aboutData = await page.evaluate(() => {
          // Inyectar misma logica simple
          const bodyText = document.body.innerText || '';
          const match = bodyText.match(/([\d\.,]+\s*[KkMmBb]?)\s*(?:suscriptore?s?|subscribere?s?)/i);
          // TODO: Mejorar parsing reutilizando funcion si es posible, o duplicando la logica minima
          if (match) return match[1]; // Devolver raw string
          return null;
        });

        if (aboutData) {
          // Parsear afuera para simplificar
          // (Reimplementamos parseNumber brevemente aqui o extraemos helpers, 
          //  pero para mantener el scope limpio, asumimos que el evaluate arriba devolvió string)
          //  Nota: evaluate tiene su propio scope.
          //  Correction: el scope de evaluate está cerrado. 
          //  Simple fix: traer el string y parsearlo en Node.
          data.followers = parseStringNumber(aboutData);
          console.log(`✅ [YouTube] Followers recuperados de /about: ${data.followers}`);
        }
      } catch (e) {
        console.warn('⚠️ [YouTube] Fallback /about falló o timeout');
      }
    }

    // Prepare result
    const result = {
      id: data.channelId || channelInput,
      username: data.handle || data.channelName || channelInput,
      full_name: data.channelName || '',
      bio: '',
      followers: data.followers,
      videos: data.videos || 0,
      hiddenSubscriberCount: data.followers === null,
      profile_image_url: data.profileImageUrl || '',
      url: data.handle
        ? `https://www.youtube.com/@${data.handle}`
        : `https://www.youtube.com/channel/${data.channelId}`,
      platform: 'youtube'
    };

    // Cerrar la PÁGINA, pero mantener el BROWSER abierto
    await page.close();

    // Guardado de imagen (asíncrono, no bloquear respuesta si es posible, pero aquí debemos esperar para devolver la URL pública)
    try {
      if (result.profile_image_url) {
        const saved = await saveProfileImageForProfile({
          platform: 'youtube',
          username: result.username,
          imageUrl: result.profile_image_url
        });
        if (saved) {
          result.profile_image_saved = true;
          result.profile_image_path = saved.path;
          if (saved.publicUrl) result.profile_image_public_url = saved.publicUrl;
        }
      }
    } catch (e) {
      console.warn('[YouTube] Failed to save profile image:', e.message);
    }

    return result;

  } catch (err) {
    // Si falla algo crítico y tenemos página, cerrarla
    if (page && !page.isClosed()) {
      try { await page.close(); } catch { }
    }
    // Si el error fue de navegador desconectado, limpiar la instancia para la proxima
    if (err.message.includes('Session closed') || err.message.includes('not opened')) {
      browserInstance = null;
    }

    console.error(`❌ [YouTube] Error:`, err);
    throw new Error(`Error scraping YouTube: ${err.message}`);
  }
}

// Helper local para parsear números en el contexto Node (para el fallback)
function parseStringNumber(text) {
  if (!text) return null;
  let cleaned = String(text).trim();
  const match = cleaned.match(/([\d\.,]+)\s*([KkMmBb])?/);
  if (!match) return null;

  let numStr = match[1];
  const suffix = (match[2] || '').toUpperCase();

  if (numStr.includes('.') && numStr.includes(',')) {
    numStr = numStr.replace(/\./g, '').replace(',', '.');
  } else if (numStr.includes(',')) {
    numStr = numStr.replace(',', '.');
  } else if (numStr.includes('.') && numStr.split('.')[1]?.length >= 3) {
    numStr = numStr.replace(/\./g, '');
  }

  let num = parseFloat(numStr);

  if (suffix === 'K') num *= 1000;
  if (suffix === 'M') num *= 1000000;
  if (suffix === 'B') num *= 1000000000;

  if (!isFinite(num)) return null;
  return Math.round(num);
}

module.exports = scrapeYouTube;