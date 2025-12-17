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

    // bloquear recursos innecesarios
    try {
      await page.setRequestInterception(true);
      page.on('request', (req) => {
        const r = req.resourceType();
        if (['image', 'stylesheet', 'font', 'media'].includes(r)) {
          try { req.abort(); } catch (e) { req.continue(); }
        } else {
          req.continue();
        }
      });
    } catch (e) {
      // algunos entornos / versiones pueden fallar en setRequestInterception; continuar sin bloqueo.
      console.warn('⚠️ setRequestInterception fallo, continuando sin bloqueo:', e.message || e);
    }

    // variables para capturar datos desde respuestas de red (GraphQL / JSON)
    const networkData = { followers: 0, profileImage: '' };

    // función recursiva para buscar números y urls dentro de objetos JSON
    function findInObject(obj) {
      if (!obj || typeof obj !== 'object') return;
      if (Array.isArray(obj)) {
        for (const it of obj) findInObject(it);
        return;
      }
      for (const k of Object.keys(obj)) {
        const v = obj[k];
        // buscar followerCount / followers
        if (typeof v === 'number' && /follow/i.test(k)) {
          if (v > networkData.followers) networkData.followers = v;
        }
        if (typeof v === 'string') {
          // si hay URLs de imagen comunes
          if (/(avatar|profile|logo|thumbnail)/i.test(k) && v.startsWith('http')) {
            if (!networkData.profileImage) networkData.profileImage = v;
          }
          // a veces follower counts vienen como strings numéricas
          const m = v.match(/^\d+$/);
          if (m && /follow/i.test(k) && parseInt(v) > networkData.followers) {
            networkData.followers = parseInt(v);
          }
        } else if (typeof v === 'object') {
          findInObject(v);
        }
      }
    }

    // escuchar respuestas para atrapar JSON con followerCount
    page.on('response', async (resp) => {
      try {
        const url = resp.url();
        // Interesa especialmente gql.twitch.tv/gql y endpoints con JSON
        if (url.includes('gql.twitch.tv') || url.includes('/helix/') || url.includes('/gql/')) {
          const headers = resp.headers() || {};
          const contentType = (headers['content-type'] || headers['Content-Type'] || '').toLowerCase();
          if (contentType.includes('application/json')) {
            const json = await resp.json().catch(() => null);
            if (json) {
              findInObject(json);
            }
          } else {
            // intentar parsear texto que contenga followerCount
            const text = await resp.text().catch(() => '');
            if (text && (text.includes('followerCount') || text.includes('followers') || text.includes('follower'))) {
              // buscar números simples en el texto
              const m = text.match(/"(?:followerCount|followers|followers_count)"\s*[:=]\s*("?)(\d{1,15})\1/i);
              if (m && m[2]) {
                const v = parseInt(m[2]);
                if (!isNaN(v) && v > networkData.followers) networkData.followers = v;
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

    // usar networkidle2 para esperar XHRs; Cloud Run: timeout largo por seguridad
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 90000 });

    // esperar a que aparezca texto relativo a followers o hasta timeout
    try {
      await page.waitForFunction(() =>
        /followers|seguidores|seguidor(es)?/i.test(document.body.innerText),
        { timeout: 30000 }
      );
    } catch (e) {
      // si no aparece el texto, aún así seguimos (tal vez la info venga por GraphQL interceptada)
      console.warn('⏳ waitForFunction no encontró "followers" en 30s, continuando. ' + (e.message || ''));
    }

    // espera extra para permitir a GraphQL/JS completar solicitudes (10s)
    await page.waitForTimeout(8000);

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
      const patterns = [
        /(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?\s*seguidores/gi,
        /(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?\s*followers/gi,
        /Followers[:\s]+(\d+(?:[.,]\d+)?)/gi
      ];
      for (const pattern of patterns) {
        const matches = bodyText.matchAll(pattern);
        for (const match of matches) {
          const number = match[1];
          const suffix = match[2];
          const count = parseNumber(number, suffix);
          if (count > followers) followers = count;
        }
      }

      // selectores probables (puede cambiar en la UI)
      const selectors = [
        '[data-a-target="followers-count"]',
        '.tw-stat__value',
        'div[data-test-selector="FollowersCount"]',
        '.tw-link[data-test-selector*="followers"]',
      ];
      for (const sel of selectors) {
        const el = document.querySelector(sel);
        if (el && el.textContent) {
          const t = el.textContent.trim();
          const m = t.match(/(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?/i);
          if (m) {
            const c = parseNumber(m[1], m[2]);
            if (c > followers) followers = c;
          }
        }
      }

      // scripts JSON-LD u otros scripts con followerCount
      const scripts = Array.from(document.querySelectorAll('script[type="application/ld+json"], script'));
      for (const s of scripts) {
        try {
          const text = s.textContent || '';
          if (text.includes('"followerCount"') || text.includes('"followers"')) {
            const mm = text.match(/"(?:followerCount|followers|followers_count)"\s*[:=]\s*("?)(\d{1,15})\1/i);
            if (mm && mm[2]) {
              const v = parseInt(mm[2]);
              if (!isNaN(v) && v > followers) followers = v;
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
