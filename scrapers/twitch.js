const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Twitch - Optimizado para Cloud Run (Puppeteer)
 * @param {string} username - Username de Twitch
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeTwitch(username) {
  let browser;
  try {
    browser = await createBrowser();
    const page = await browser.newPage();

    // viewport + UA
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Agregar headers adicionales
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1'
    });

    // NO bloquear recursos - Twitch necesita cargar todo
    console.log('📦 [Twitch] Permitiendo carga completa de recursos...');

    // variables para capturar datos desde respuestas de red (GraphQL / JSON)
    const networkData = { followers: 0, profileImage: '' };
    let graphqlCaptured = false;

    // función recursiva para buscar números y urls dentro de objetos JSON
    function findInObject(obj, depth = 0) {
      if (!obj || typeof obj !== 'object' || depth > 10) return;
      if (Array.isArray(obj)) {
        for (const it of obj) findInObject(it, depth + 1);
        return;
      }
      for (const k of Object.keys(obj)) {
        const v = obj[k];
        
        // Buscar followerCount / followers con más variaciones
        if (typeof v === 'number' && /follow/i.test(k)) {
          if (v > networkData.followers && v < 1000000000) {
            console.log(`   📊 Encontrado ${k}: ${v}`);
            networkData.followers = v;
            graphqlCaptured = true;
          }
        }
        
        if (typeof v === 'string') {
          // URLs de imagen
          if (/(avatar|profile|logo|thumbnail|profileImageURL)/i.test(k) && v.startsWith('http')) {
            if (!networkData.profileImage) {
              networkData.profileImage = v;
              console.log(`   🖼️ Imagen encontrada: ${v.substring(0, 50)}...`);
            }
          }
          // follower counts como strings
          const m = v.match(/^\d+$/);
          if (m && /follow/i.test(k) && parseInt(v) > networkData.followers) {
            const num = parseInt(v);
            if (num < 1000000000) {
              console.log(`   📊 Encontrado ${k} (string): ${num}`);
              networkData.followers = num;
              graphqlCaptured = true;
            }
          }
        } else if (typeof v === 'object') {
          findInObject(v, depth + 1);
        }
      }
    }

    // escuchar respuestas para atrapar JSON con followerCount
    page.on('response', async (resp) => {
      try {
        const url = resp.url();
        const status = resp.status();
        
        // Log de todas las solicitudes GraphQL
        if (url.includes('gql.twitch.tv')) {
          console.log(`   🔍 GraphQL request: ${status}`);
        }
        
        // Interesa especialmente gql.twitch.tv/gql y endpoints con JSON
        if (url.includes('gql.twitch.tv') || url.includes('/helix/') || url.includes('/api/')) {
          if (status !== 200) {
            console.log(`   ⚠️ Non-200 response: ${status} from ${url.substring(0, 50)}`);
            return;
          }
          
          const headers = resp.headers() || {};
          const contentType = (headers['content-type'] || headers['Content-Type'] || '').toLowerCase();
          
          if (contentType.includes('application/json')) {
            try {
              const json = await resp.json();
              if (json) {
                console.log(`   🔍 Analizando respuesta JSON...`);
                findInObject(json);
              }
            } catch (e) {
              console.warn(`   ⚠️ Error parseando JSON: ${e.message}`);
            }
          } else {
            // intentar parsear texto que contenga followerCount
            const text = await resp.text().catch(() => '');
            if (text && (text.includes('followerCount') || text.includes('followers'))) {
              console.log(`   🔍 Texto con "followers" encontrado, parseando...`);
              
              // Buscar números
              const patterns = [
                /"(?:followerCount|followers|followersCount)"\s*[:=]\s*("?)(\d{1,15})\1/gi,
                /"followers"\s*[:=]\s*\{\s*"totalCount"\s*[:=]\s*(\d+)/gi,
              ];
              
              for (const pattern of patterns) {
                const matches = text.matchAll(pattern);
                for (const match of matches) {
                  const num = parseInt(match[2] || match[1]);
                  if (!isNaN(num) && num > networkData.followers && num < 1000000000) {
                    console.log(`   📊 Followers encontrados en texto: ${num}`);
                    networkData.followers = num;
                    graphqlCaptured = true;
                  }
                }
              }
              
              // buscar URL de imagen
              const imgMatch = text.match(/"(?:profileImageURL|profile_pic|avatar|thumbnail|logo)"\s*[:=]\s*"(https?:\/\/[^"]+)"/i);
              if (imgMatch && imgMatch[1] && !networkData.profileImage) {
                networkData.profileImage = imgMatch[1];
              }
            }
          }
        }
      } catch (e) {
        // ignorar errores de parseo
      }
    });

    const url = `https://www.twitch.tv/${username}`;
    console.log(`🌐 [Twitch] Navegando a: ${url}`);

    // Navegar a la página
    await page.goto(url, { 
      waitUntil: 'networkidle0',  // Esperar a que no haya solicitudes de red
      timeout: 90000 
    });

    console.log('⏳ [Twitch] Página cargada, esperando contenido...');

    // Esperar más tiempo para que cargue el JavaScript
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Intentar hacer scroll para activar carga lazy
    await page.evaluate(() => {
      window.scrollBy(0, 500);
    });
    await new Promise(resolve => setTimeout(resolve, 2000));

    console.log('🔍 [Twitch] Extrayendo datos del DOM...');

    // Evaluar selectores / meta tags en el DOM
    let domData = await page.evaluate(() => {
      function parseNumber(numStr, suffix) {
        if (!numStr) return 0;
        let s = String(numStr).trim();
        s = s.replace(/[^\d.,]/g, '');
        if (s.indexOf('.') > -1 && s.indexOf(',') > -1) {
          s = s.replace(/\./g, '').replace(',', '.');
        } else if (s.indexOf(',') > -1 && s.indexOf('.') === -1) {
          s = s.replace(',', '.');
        } else {
          s = s.replace(/,/g, '');
        }
        const num = parseFloat(s);
        if (isNaN(num)) return 0;
        if (!suffix) return Math.round(num);
        const suf = String(suffix).toLowerCase();
        if (suf === 'k' || suf === 'mil') return Math.round(num * 1e3);
        if (suf === 'm' || suf === 'millones') return Math.round(num * 1e6);
        if (suf === 'b') return Math.round(num * 1e9);
        return Math.round(num);
      }

      const ogImage = document.querySelector('meta[property="og:image"]') || document.querySelector('meta[name="og:image"]');
      let username = window.location.pathname.replace('/', '').split('/')[0] || '';
      let followers = 0;
      let profileImageUrl = ogImage ? ogImage.content : '';

      // buscar patrones en el body
      const bodyText = document.body.innerText || '';
      console.log('Body text length:', bodyText.length);
      
      const patterns = [
        /(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?\s*seguidores/gi,
        /(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?\s*followers/gi,
        /(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?\s*follower/gi,
        /Followers[:\s]+(\d+(?:[.,]\d+)?)\s*(k|m|b)?/gi,
      ];
      
      for (const pattern of patterns) {
        const matches = bodyText.matchAll(pattern);
        for (const match of matches) {
          const number = match[1];
          const suffix = match[2];
          const count = parseNumber(number, suffix);
          if (count > followers && count < 1000000000) {
            console.log('Found in body:', count);
            followers = count;
          }
        }
      }

      // selectores más amplios
      const selectors = [
        '[data-a-target="followers-count"]',
        '[data-a-target*="follower"]',
        '.tw-stat__value',
        'div[data-test-selector="FollowersCount"]',
        '.tw-link[data-test-selector*="followers"]',
        'p[data-a-target*="follower"]',
        'span[data-a-target*="follower"]',
        // Nuevos selectores para la UI actualizada de Twitch
        'button[aria-label*="Follow"]',
        'div[class*="ScFollowerCount"]',
        'div[class*="follower"]',
      ];
      
      for (const sel of selectors) {
        try {
          const elements = document.querySelectorAll(sel);
          for (const el of elements) {
            if (el && el.textContent) {
              const t = el.textContent.trim();
              const m = t.match(/(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?/i);
              if (m) {
                const c = parseNumber(m[1], m[2]);
                if (c > followers && c < 1000000000) {
                  console.log(`Found in ${sel}:`, c);
                  followers = c;
                }
              }
            }
          }
        } catch (e) {
          // continue
        }
      }

      // scripts JSON-LD u otros scripts con followerCount
      const scripts = Array.from(document.querySelectorAll('script[type="application/ld+json"], script'));
      for (const s of scripts) {
        try {
          const text = s.textContent || '';
          if (text.includes('"followerCount"') || text.includes('"followers"') || text.includes('followers')) {
            // Múltiples patrones
            const patterns = [
              /"(?:followerCount|followers|followersCount)"\s*[:=]\s*("?)(\d{1,15})\1/gi,
              /"followers"\s*[:=]\s*\{\s*"totalCount"\s*[:=]\s*(\d+)/gi,
            ];
            
            for (const pattern of patterns) {
              const matches = text.matchAll(pattern);
              for (const match of matches) {
                const v = parseInt(match[2] || match[1]);
                if (!isNaN(v) && v > followers && v < 1000000000) {
                  console.log('Found in script:', v);
                  followers = v;
                }
              }
            }
          }
          if (!profileImageUrl) {
            const imgMatch = text.match(/"(?:profileImageURL|profile_pic|avatar|thumbnail|logo)"\s*[:=]\s*"(https?:\/\/[^"]+)"/i);
            if (imgMatch && imgMatch[1]) profileImageUrl = imgMatch[1];
          }
        } catch (e) { /* ignore */ }
      }

      return { username, followers, profileImageUrl };
    });

    console.log(`📊 [Twitch] DOM followers: ${domData.followers}`);
    console.log(`📊 [Twitch] Network followers: ${networkData.followers}`);
    console.log(`🔍 [Twitch] GraphQL captured: ${graphqlCaptured}`);

    // combinar datos: preferimos networkData si es > 0 (viene de GraphQL)
    const finalFollowers = Math.max(domData.followers || 0, networkData.followers || 0);
    const finalProfileImage = domData.profileImageUrl || networkData.profileImage || '';

    const profileData = {
      username: domData.username || username,
      followers: finalFollowers,
      profile_image_url: finalProfileImage,
      url
    };

    console.log(`✅ [Twitch] Scraped: @${profileData.username}`);
    console.log(`   Followers: ${profileData.followers}`);

    if (profileData.followers === 0) {
      console.warn('⚠️ [Twitch] No se pudieron obtener seguidores. Posibles causas:');
      console.warn('   - Twitch está bloqueando el scraper');
      console.warn('   - El perfil no existe o está suspendido');
      console.warn('   - Los selectores de Twitch han cambiado');
    }

    return profileData;
  } catch (error) {
    throw new Error(`Error scraping Twitch: ${error.message || error}`);
  } finally {
    if (browser) {
      try { await browser.close(); } catch (e) { /* ignore */ }
    }
  }
}

module.exports = scrapeTwitch;