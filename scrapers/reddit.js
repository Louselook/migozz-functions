const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Reddit (usuarios y subreddits)
 * Maneja:
 *  - intento por API pública (intenta also old.reddit si el endpoint moderno da 403)
 *  - fallback con Puppeteer
 *  - fallback adicional a old.reddit.com (DOM clásico) para conseguir avatar, subs/karma.
 */
async function scrapeReddit(input) {
  console.log(`📥 [Reddit] Iniciando scraping para: ${input}`);
  
  // Determinar si es usuario o subreddit
  let type = 'user';
  let name = input;
  
  if (input.startsWith('r/')) {
    type = 'subreddit';
    name = input.replace('r/', '');
  } else if (input.startsWith('u/')) {
    type = 'user';
    name = input.replace('u/', '');
  } else if (input.startsWith('/r/')) {
    type = 'subreddit';
    name = input.replace('/r/', '');
  } else if (input.startsWith('/u/')) {
    type = 'user';
    name = input.replace('/u/', '');
  }

  // Intentar primero con la API pública (si da 403, reintenta con old.reddit.com)
  try {
    const apiData = await fetchRedditAPI(type, name);
    if (apiData) {
      console.log(`✅ [Reddit] Datos obtenidos via API`);
      return apiData;
    }
  } catch (apiError) {
    console.log(`⚠️ [Reddit] API no disponible o bloqueada: ${apiError.message}`);
  }
  
  // Fallback a Puppeteer
  return await scrapeRedditWithPuppeteer(type, name);
}

/**
 * Obtener datos usando la API pública de Reddit.
 * Si la ruta moderna da 403, intenta usar old.reddit.com (suele ser más permisivo para about.json).
 */
async function fetchRedditAPI(type, name) {
  const modernUrl = type === 'subreddit'
    ? `https://www.reddit.com/r/${name}/about.json`
    : `https://www.reddit.com/user/${name}/about.json`;

  const oldUrl = type === 'subreddit'
    ? `https://old.reddit.com/r/${name}/about.json`
    : `https://old.reddit.com/user/${name}/about.json`;

  // helper para request con headers realistas
  async function doFetch(url) {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Referer': 'https://www.reddit.com/'
      }
    });
    return res;
  }

  // Primero intentar la URL moderna
  let response = await doFetch(modernUrl);
  if (response.status === 403 || response.status === 429) {
    // intentar old.reddit
    response = await doFetch(oldUrl);
  }

  if (!response.ok) {
    throw new Error(`API responded with status ${response.status}`);
  }

  const json = await response.json();
  const data = json.data;
  if (!data) throw new Error('Invalid API response');

  if (type === 'subreddit') {
    return {
      id: data.id,
      username: data.display_name,
      full_name: data.title,
      bio: data.public_description || data.description || '',
      followers: data.subscribers || 0,
      active_users: data.accounts_active || 0,
      profile_image_url: (data.icon_img || data.community_icon || '').split('?')[0] || '',
      banner_url: (data.banner_background_image || data.banner_img || '').split('?')[0] || '',
      created_at: data.created_utc ? new Date(data.created_utc * 1000).toISOString() : null,
      is_nsfw: data.over18 || false,
      url: `https://www.reddit.com/r/${name}`,
      platform: 'reddit',
      type: 'subreddit'
    };
  } else {
    return {
      id: data.id,
      username: data.name,
      full_name: data.subreddit?.title || data.name,
      bio: data.subreddit?.public_description || '',
      followers: data.subreddit?.subscribers || 0,
      karma: (data.link_karma || 0) + (data.comment_karma || 0),
      link_karma: data.link_karma || 0,
      comment_karma: data.comment_karma || 0,
      profile_image_url: (data.icon_img || data.snoovatar_img || '').split('?')[0] || '',
      created_at: data.created_utc ? new Date(data.created_utc * 1000).toISOString() : null,
      verified: data.verified || false,
      is_gold: data.is_gold || false,
      url: `https://www.reddit.com/user/${name}`,
      platform: 'reddit',
      type: 'user'
    };
  }
}

/**
 * Scraping con Puppeteer como fallback.
 * - Primero intenta con la versión "nueva" de reddit.
 * - Si no encuentra avatar/estadísticas, intenta automáticamente la versión clásica en old.reddit.com,
 *   que tiene selectores más fáciles de parsear.
 */
async function scrapeRedditWithPuppeteer(type, name) {
  let browser;
  try {
    browser = await createBrowser();
    const page = await browser.newPage();

    await page.setViewport({ width: 1200, height: 900 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const newUrl = type === 'subreddit'
      ? `https://www.reddit.com/r/${name}/`
      : `https://www.reddit.com/user/${name}/`;
    const oldUrl = type === 'subreddit'
      ? `https://old.reddit.com/r/${name}/`
      : `https://old.reddit.com/user/${name}/`;

    console.log(`🌐 [Reddit] Navegando a (nuevo): ${newUrl}`);
    await page.goto(newUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    // dejar que cargue JS y recursos mínimos
    await page.waitForTimeout(3000);

    // Evaluar datos en la versión nueva
    const evaluateNew = await page.evaluate((type) => {
      // utilidades
      function safeAttr(el, attr) { try { return el?.getAttribute(attr) || ''; } catch(e){ return ''; } }
      function textOf(sel){ const el = document.querySelector(sel); return el ? el.innerText.trim() : ''; }

      // buscar meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]')?.content || '';
      const ogImage = document.querySelector('meta[property="og:image"]')?.content || '';
      const ogDesc = document.querySelector('meta[property="og:description"]')?.content || '';

      // new reddit puede poner avatar en <img alt="User avatar"> o en data-testid cards
      let avatar = '';
      const avatarImgs = Array.from(document.querySelectorAll('img'));
      for (const img of avatarImgs) {
        const alt = img.getAttribute('alt') || '';
        if (/avatar/i.test(alt) || /user avatar/i.test(alt) || /snoo/i.test(alt)) {
          avatar = img.src || avatar;
        }

        // fallback: sometimes profile hero image is in og:image
        if (!avatar && img.src && img.src.includes('avatars') ) {
          avatar = img.src;
        }
      }

      // intentos en texto para karma/subs (no muy fiable en new)
      let statText = document.body.innerText || '';
      let numberGuess = 0;
      const m = statText.match(/(\d{1,3}(?:[.,]\d{3})?|\d+(?:[.,]\d+)?)(\s*[KMB])?\s*(karma|subscribers|members|miembros)/i);
      if (m) {
        numberGuess = m[1] ? m[1] : 0;
      }

      return {
        title: ogTitle || textOf('h1') || '',
        description: ogDesc || textOf('[data-testid="profile--bio"]') || '',
        avatar: ogImage || avatar || '',
        statGuess: numberGuess
      };
    }, type);

    // Si la nueva versión no devolvió avatar o datos útiles, intentar old.reddit
    let profileData = evaluateNew;
    if (!profileData.avatar || profileData.avatar.length < 5) {
      console.log('🔁 [Reddit] No se encontró avatar confiable en la versión nueva; probando old.reddit.com');
      await page.goto(oldUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
      await page.waitForTimeout(2000);

      const evaluateOld = await page.evaluate((type) => {
        function parseNumber(text) {
          if (!text) return 0;
          const m = text.replace(/\u00A0/g,' ').match(/([\d.,]+)\s*([KMB])?/i);
          if (!m) return 0;
          let num = parseFloat(m[1].replace(/,/g, ''));
          const suf = (m[2] || '').toUpperCase();
          if (suf === 'K') num *= 1000;
          if (suf === 'M') num *= 1000000;
          if (suf === 'B') num *= 1000000000;
          return Math.round(num);
        }

        let avatar = '';
        let title = '';
        let description = '';
        let subscribers = 0;

        // Subreddit classic layout
        const titleEl = document.querySelector('.titlebox h1') || document.querySelector('h1');
        if (titleEl) title = titleEl.innerText.trim();

        const descEl = document.querySelector('.titlebox .md') || document.querySelector('.usertext-body .md') || document.querySelector('#siteTable');
        if (descEl) description = descEl.innerText.trim();

        // Avatar selectors in old reddit
        const avatarImg = document.querySelector('.side .user a img') || document.querySelector('.user .userimg') || document.querySelector('.avatar img') || document.querySelector('.profile .avatar');
        if (avatarImg) avatar = avatarImg.src || '';

        // subscribers (subreddit) o karma (user) in old layout
        const subEl = document.querySelector('.side .subscribers .number') || document.querySelector('.subscribers') || document.querySelector('.ranking');
        if (subEl) subscribers = parseNumber(subEl.innerText || subEl.textContent);

        // try to find "karma" for user profiles
        const karmaEl = Array.from(document.querySelectorAll('.karma .number, .karma')).map(e=>e.innerText).join(' ');
        const parsedKarma = parseNumber(karmaEl);
        if (parsedKarma) subscribers = Math.max(subscribers, parsedKarma);

        // some pages include an avatar in .userattrs img
        const ua = document.querySelector('.userattrs img');
        if (ua && !avatar) avatar = ua.src || avatar;

        return {
          title: title,
          description: description,
          avatar: avatar,
          subscribers: subscribers
        };
      }, type);

      profileData = evaluateOld;
    }

    // Close browser early
    await browser.close();

    // Normalize values
    const profileImageUrl = (profileData.avatar || '').split('?')[0] || '';
    const followers = profileData.subscribers || profileData.statGuess || 0;
    const fullName = (profileData.title && profileData.title.length) ? profileData.title : name;
    const bio = profileData.description || '';

    return {
      id: name,
      username: name,
      full_name: fullName,
      bio: bio,
      followers: typeof followers === 'number' ? followers : parseInt(followers || 0),
      profile_image_url: profileImageUrl,
      url: type === 'subreddit' 
        ? `https://www.reddit.com/r/${name}` 
        : `https://www.reddit.com/user/${name}`,
      platform: 'reddit',
      type: type
    };

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Reddit: ${error.message}`);
  }
}

module.exports = scrapeReddit;
