const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para canales de YouTube - VERSIÓN MEJORADA
 * Devuelve:
 *  - followers: int | null (suscriptores)
 *  - videos: int (0 si no se encuentra)
 */
async function scrapeYouTube(channelInput) {
  console.log(`📥 [YouTube] Iniciando scraping para: ${channelInput}`);

  let browser;
  try {
    browser = await createBrowser();
    const page = await browser.newPage();

    await page.setViewport({ width: 1920, height: 1080 });
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

    await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });

    // Espera más robusta para que cargue el contenido dinámico
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    await sleep(3000); // Espera inicial

    try {
      await page.waitForSelector('ytd-c4-tabbed-header-renderer, yt-formatted-string', { timeout: 5000 });
    } catch {
      await sleep(2000);
    }

    // ---------------- Extracción mejorada ----------------
    let data = await page.evaluate(() => {
      // Función parseNumber definida directamente en el contexto del navegador
      const parseNumber = (text) => {
        if (!text) return null;
        
        let cleaned = String(text).trim();
        const match = cleaned.match(/([\d\.,]+)\s*([KkMmBb])?/);
        if (!match) return null;
        
        let numStr = match[1];
        const suffix = (match[2] || '').toUpperCase();
        
        // Normaliza formatos
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

      // 1) Meta tags
      try {
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogUrl = document.querySelector('meta[property="og:url"]');

        if (ogTitle?.content) channelName = ogTitle.content;
        if (ogImage?.content) profileImageUrl = ogImage.content;
        if (ogUrl?.content) {
          const m = ogUrl.content.match(/channel\/(UC[a-zA-Z0-9_-]{22})/);
          if (m) channelId = m[1];
        }
      } catch (e) {
        console.error('Error en meta tags:', e);
      }

      // 2) ytInitialData
      try {
        const ytData = window.ytInitialData;
        if (ytData) {
          const header = ytData?.header?.c4TabbedHeaderRenderer;
          const metadata = ytData?.metadata?.channelMetadataRenderer;
          
          if (header) {
            if (header.title) channelName = header.title;
            if (header.channelId) channelId = header.channelId;
            
            // Handle
            if (header.channelHandleText?.runs?.[0]?.text) {
              handle = header.channelHandleText.runs[0].text.replace('@', '');
            }
            
            // Avatar
            if (header.avatar?.thumbnails?.length) {
              profileImageUrl = header.avatar.thumbnails.at(-1).url || profileImageUrl;
            }
            
            // Suscriptores - MEJORADO
            if (header.subscriberCountText) {
              if (header.subscriberCountText.simpleText) {
                followers = parseNumber(header.subscriberCountText.simpleText);
              } else if (header.subscriberCountText.runs?.[0]?.text) {
                followers = parseNumber(header.subscriberCountText.runs[0].text);
              }
            }
            
            // Videos - MEJORADO
            if (header.videosCountText) {
              if (header.videosCountText.simpleText) {
                videos = parseNumber(header.videosCountText.simpleText) || 0;
              } else if (header.videosCountText.runs?.[0]?.text) {
                videos = parseNumber(header.videosCountText.runs[0].text) || 0;
              }
            }
          }
          
          if (metadata) {
            if (!channelName && metadata.title) channelName = metadata.title;
            if (!channelId && metadata.externalId) channelId = metadata.externalId;
            if (!profileImageUrl && metadata.avatar?.thumbnails?.[0]?.url) {
              profileImageUrl = metadata.avatar.thumbnails[0].url;
            }
          }
        }
      } catch (e) {
        console.error('Error en ytInitialData:', e);
      }

      // 3) Selectores DOM modernos - MEJORADO
      try {
        // Buscar el texto que muestra "885 K suscriptores · 2,3 K vídeos"
        const channelHandleEl = document.querySelector('#channel-handle');
        if (channelHandleEl) {
          const handleText = safeText(channelHandleEl).replace('@', '');
          if (handleText && !handle) handle = handleText;
          
          // El texto de stats suele estar justo después
          const parent = channelHandleEl.closest('ytd-c4-tabbed-header-renderer');
          if (parent) {
            const allText = safeText(parent);
            
            // Buscar patrón "X suscriptores" o "X suscriptor"
            if (followers === null) {
              const subsMatch = allText.match(/([\d\.,]+\s*[KkMmBb]?)\s*suscriptore?s?/i);
              if (subsMatch) {
                followers = parseNumber(subsMatch[1]);
              }
            }
            
            // Búsqueda especial para canales pequeños (1-999 suscriptores)
            if (followers === null) {
              const smallMatch = allText.match(/\b(\d{1,3})\s*suscriptore?s?\b/i);
              if (smallMatch && smallMatch[1]) {
                const parsed = parseInt(smallMatch[1], 10);
                if (parsed > 0 && parsed < 1000) {
                  followers = parsed;
                }
              }
            }
            
            // Buscar patrón "X vídeos" o "X vídeo" o "X videos" o "X video"
            if (!videos) {
              const videosMatch = allText.match(/([\d\.,]+\s*[KkMmBb]?)\s*v[ií]deoe?s?/i);
              if (videosMatch) {
                videos = parseNumber(videosMatch[1]) || 0;
              }
            }
          }
        }

        // Selector específico para subscriber count
        if (followers === null) {
          const subElements = document.querySelectorAll('yt-formatted-string[id*="subscriber"], #subscriber-count');
          for (const el of subElements) {
            const text = safeText(el);
            if (text) {
              const parsed = parseNumber(text);
              if (parsed !== null) {
                followers = parsed;
                break;
              }
            }
          }
        }
      } catch (e) {
        console.error('Error en selectores DOM:', e);
      }

      // 4) Búsqueda en todo el body como último recurso
      try {
        const bodyText = document.body.innerText || '';
        
        // Buscar suscriptores si aún no se encontró
        if (followers === null) {
          const patterns = [
            /([\d\.,]+\s*[KkMmBb]?)\s*suscriptore?s?/i,
            /([\d\.,]+\s*[KkMmBb]?)\s*subscribere?s?/i,
            /([\d\.,]+\s*[KkMmBb]?)\s*abonadoe?s?/i
          ];
          
          for (const pattern of patterns) {
            const match = bodyText.match(pattern);
            if (match && match[1]) {
              const parsed = parseNumber(match[1]);
              if (parsed !== null && parsed > 1000) { // Filtro básico de validez
                followers = parsed;
                break;
              }
            }
          }
        }
        
        // Búsqueda especial para suscriptores pequeños (1-999 sin sufijo)
        if (followers === null) {
          const smallMatch = bodyText.match(/\b(\d{1,3})\s*suscriptore?s?\b/i);
          if (smallMatch && smallMatch[1]) {
            const parsed = parseInt(smallMatch[1], 10);
            if (parsed > 0 && parsed < 1000) {
              followers = parsed;
            }
          }
        }
        
        // Buscar videos si aún no se encontró
        if (!videos) {
          const match = bodyText.match(/([\d\.,]+\s*[KkMmBb]?)\s*v[ií]deoe?s?/i);
          if (match && match[1]) {
            videos = parseNumber(match[1]) || 0;
          }
        }
      } catch (e) {
        console.error('Error en búsqueda body:', e);
      }

      // 5) Canonical link para handle
      try {
        if (!handle) {
          const canonical = document.querySelector('link[rel="canonical"]');
          if (canonical?.href && canonical.href.includes('/@')) {
            handle = canonical.href.split('/@').pop().split('/')[0];
          }
        }
      } catch (e) {}

      return { channelName, channelId, handle, profileImageUrl, followers, videos };
    });

    console.log(`📊 [YouTube] Datos extraídos:`, data);

    // ---------------- Fallback: /about page ----------------
    if (data.followers === null) {
      try {
        const aboutUrl = url.replace(/\/$/, '') + '/about';
        console.log(`🔎 [YouTube] Intentando /about: ${aboutUrl}`);
        
        await page.goto(aboutUrl, { waitUntil: 'networkidle2', timeout: 60000 });
        await sleep(2000);

        const aboutData = await page.evaluate(() => {
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
          
          const bodyText = document.body.innerText || '';
          
          let followers = null;
          const match = bodyText.match(/([\d\.,]+\s*[KkMmBb]?)\s*(?:suscriptore?s?|subscribere?s?)/i);
          if (match && match[1]) {
            followers = parseNumber(match[1]);
          }
          
          // Búsqueda especial para números pequeños
          if (followers === null) {
            const smallMatch = bodyText.match(/\b(\d{1,3})\s*suscriptore?s?\b/i);
            if (smallMatch && smallMatch[1]) {
              const parsed = parseInt(smallMatch[1], 10);
              if (parsed > 0 && parsed < 1000) {
                followers = parsed;
              }
            }
          }
          
          return { followers };
        });

        if (aboutData.followers !== null) {
          data.followers = aboutData.followers;
          console.log(`✅ [YouTube] Followers encontrados en /about: ${data.followers}`);
        }
      } catch (e) {
        console.error('Error en /about:', e.message);
      }
    }

    // ---------------- Fallback: /videos page ----------------
    if (!data.videos) {
      try {
        const videosUrl = url.replace(/\/$/, '') + '/videos';
        console.log(`🔎 [YouTube] Intentando /videos: ${videosUrl}`);
        
        await page.goto(videosUrl, { waitUntil: 'networkidle2', timeout: 60000 });
        await sleep(2000);

        const videosData = await page.evaluate(() => {
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
          
          const bodyText = document.body.innerText || '';
          
          let videos = 0;
          const match = bodyText.match(/([\d\.,]+\s*[KkMmBb]?)\s*v[ií]deoe?s?/i);
          if (match && match[1]) {
            videos = parseNumber(match[1]) || 0;
          }
          
          return { videos };
        });

        if (videosData.videos) {
          data.videos = videosData.videos;
          console.log(`✅ [YouTube] Videos encontrados en /videos: ${data.videos}`);
        }
      } catch (e) {
        console.error('Error en /videos:', e.message);
      }
    }

    // Cerrar browser
    try { await browser.close(); } catch (e) {}

    // Log final
    console.log(`✅ [YouTube] Resultado final:`, {
      followers: data.followers,
      videos: data.videos
    });

    // Preparar resultado
    return {
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

  } catch (err) {
    if (browser) {
      try { await browser.close(); } catch {}
    }
    console.error(`❌ [YouTube] Error:`, err);
    throw new Error(`Error scraping YouTube: ${err.message}`);
  }
}

module.exports = scrapeYouTube;