const { createBrowser } = require('../utils/helpers');

/**
 * Fetch con reintentos para manejar errores 403
 */
async function fetchWithRetry(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) return response;
      
      // Si es 403, esperar más tiempo antes de reintentar
      if (response.status === 403 && i < maxRetries - 1) {
        console.log(`⏳ [Reddit] Reintento ${i + 1}/${maxRetries} después de 403`);
        await new Promise(resolve => setTimeout(resolve, (i + 1) * 2000));
        continue;
      }
      
      throw new Error(`API responded with status ${response.status}`);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      console.log(`⏳ [Reddit] Reintento ${i + 1}/${maxRetries} después de error`);
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}

/**
 * Scraper para perfiles de Reddit (usuarios y subreddits)
 * @param {string} input - Username (u/xxx) o subreddit (r/xxx)
 * @returns {Promise<Object>} Datos del perfil
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
  
  // Intentar primero con la API pública de Reddit
  try {
    const apiData = await fetchRedditAPI(type, name);
    if (apiData) {
      console.log(`✅ [Reddit] Datos obtenidos via API`);
      return apiData;
    }
  } catch (apiError) {
    console.log(`⚠️ [Reddit] API no disponible: ${apiError.message}`);
  }
  
  // Fallback a Puppeteer
  return await scrapeRedditWithPuppeteer(type, name);
}

/**
 * Obtener datos usando la API pública de Reddit
 */
async function fetchRedditAPI(type, name) {
  const apiUrl = type === 'subreddit' 
    ? `https://www.reddit.com/r/${name}/about.json`
    : `https://www.reddit.com/user/${name}/about.json`;
  
  const response = await fetchWithRetry(apiUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'Accept': 'application/json',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Referer': 'https://www.reddit.com/',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin'
    }
  });
  
  if (!response.ok) {
    throw new Error(`API responded with status ${response.status}`);
  }
  
  const json = await response.json();
  const data = json.data;
  
  if (!data) {
    throw new Error('Invalid API response');
  }
  
  if (type === 'subreddit') {
    return {
      id: data.id,
      username: data.display_name,
      full_name: data.title,
      bio: data.public_description || data.description || '',
      followers: data.subscribers || 0,
      active_users: data.accounts_active || 0,
      profile_image_url: data.icon_img?.split('?')[0] || data.community_icon?.split('?')[0] || '',
      banner_url: data.banner_background_image?.split('?')[0] || '',
      created_at: new Date(data.created_utc * 1000).toISOString(),
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
      profile_image_url: data.icon_img?.split('?')[0] || data.snoovatar_img || '',
      created_at: new Date(data.created_utc * 1000).toISOString(),
      verified: data.verified || false,
      is_gold: data.is_gold || false,
      url: `https://www.reddit.com/user/${name}`,
      platform: 'reddit',
      type: 'user'
    };
  }
}

/**
 * Scraping con Puppeteer como fallback
 */
async function scrapeRedditWithPuppeteer(type, name) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
    );

    const url = type === 'subreddit'
      ? `https://www.reddit.com/r/${name}/`
      : `https://www.reddit.com/user/${name}/`;
    
    console.log(`🌐 [Reddit] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    // Esperar a que el contenido de Reddit se cargue
    try {
      await page.waitForSelector('shreddit-app', { timeout: 10000 });
    } catch (e) {
      console.log(`⚠️ [Reddit] shreddit-app no encontrado, continuando...`);
    }
    
    await new Promise(resolve => setTimeout(resolve, 3000));

    const profileData = await page.evaluate((type) => {
      let name = '';
      let title = '';
      let description = '';
      let subscribers = 0;
      let karma = 0;
      let profileImageUrl = '';
      let linkKarma = 0;
      let commentKarma = 0;
      let createdAt = null;
      let verified = false;
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');
      
      if (ogTitle) title = ogTitle.content;
      if (ogImage) profileImageUrl = ogImage.content;
      if (ogDescription) description = ogDescription.content;
      
      // Buscar en scripts con datos estructurados
      const scripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
      for (const script of scripts) {
        try {
          const data = JSON.parse(script.textContent);
          if (data['@type'] === 'ProfilePage') {
            if (data.image) profileImageUrl = data.image;
            if (data.name) name = data.name;
          }
        } catch (e) {}
      }
      
      // Buscar subscribers/karma en el body
      const bodyText = document.body.innerText;
      
      function parseNumber(text) {
        const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
        if (!match) return 0;
        let num = parseFloat(match[1].replace(/,/g, ''));
        const suffix = match[2]?.toUpperCase();
        if (suffix === 'K') num *= 1000;
        else if (suffix === 'M') num *= 1000000;
        else if (suffix === 'B') num *= 1000000000;
        return Math.round(num);
      }
      
      if (type === 'subreddit') {
        // Buscar members/subscribers
        const patterns = [
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:members|subscribers|miembros)/gi,
        ];
        
        for (const pattern of patterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const count = parseNumber(match[0]);
            if (count > subscribers) subscribers = count;
          }
        }
      } else {
        // Buscar karma
        const karmaPatterns = [
          /(\d+(?:[.,]\d+)?[KMB]?)\s*(?:post\s+)?karma/gi,
          /karma[:\s]*(\d+(?:[.,]\d+)?[KMB]?)/gi
        ];
        
        for (const pattern of karmaPatterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const count = parseNumber(match[0]);
            if (count > karma) karma = count;
          }
        }
      }
      
      // Buscar en scripts de estado
      const stateScripts = Array.from(document.querySelectorAll('script'))
        .filter(s => s.textContent && s.textContent.length > 0);
      
      for (const script of stateScripts) {
        const text = script.textContent;
        
        if (text.includes('"subscribers"') || text.includes('"karma"') || text.includes('"totalKarma"')) {
          try {
            // Buscar subscribers
            const subsMatch = text.match(/"subscribers"[:\s]*(\d+)/);
            if (subsMatch) {
              const count = parseInt(subsMatch[1]);
              if (count > subscribers) subscribers = count;
            }
            
            // Buscar karma total
            const totalKarmaMatch = text.match(/"(?:total_karma|totalKarma)"[:\s]*(\d+)/);
            if (totalKarmaMatch && type === 'user') {
              const count = parseInt(totalKarmaMatch[1]);
              if (count > karma) karma = count;
            }
            
            // Buscar link_karma
            const linkKarmaMatch = text.match(/"link_karma"[:\s]*(\d+)/);
            if (linkKarmaMatch) {
              linkKarma = parseInt(linkKarmaMatch[1]);
            }
            
            // Buscar comment_karma
            const commentKarmaMatch = text.match(/"comment_karma"[:\s]*(\d+)/);
            if (commentKarmaMatch) {
              commentKarma = parseInt(commentKarmaMatch[1]);
            }
            
            // Buscar verified
            const verifiedMatch = text.match(/"verified"[:\s]*(true|false)/);
            if (verifiedMatch) {
              verified = verifiedMatch[1] === 'true';
            }
            
            // Buscar created_utc
            const createdMatch = text.match(/"created_utc"[:\s]*(\d+)/);
            if (createdMatch) {
              createdAt = new Date(parseInt(createdMatch[1]) * 1000).toISOString();
            }
          } catch (e) {}
        }
      }
      
      return {
        name: title,
        description,
        subscribers,
        karma,
        linkKarma,
        commentKarma,
        profileImageUrl,
        verified,
        createdAt
      };
    }, type);

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos de Reddit');
    }

    const baseResult = {
      id: name,
      username: name,
      full_name: profileData.name || name,
      bio: profileData.description || '',
      profile_image_url: profileData.profileImageUrl || '',
      url: type === 'subreddit' 
        ? `https://www.reddit.com/r/${name}` 
        : `https://www.reddit.com/user/${name}`,
      platform: 'reddit',
      type: type
    };

    if (type === 'user') {
      return {
        ...baseResult,
        followers: 0,
        karma: profileData.karma || 0,
        link_karma: profileData.linkKarma || 0,
        comment_karma: profileData.commentKarma || 0,
        verified: profileData.verified || false,
        ...(profileData.createdAt && { created_at: profileData.createdAt })
      };
    } else {
      return {
        ...baseResult,
        followers: profileData.subscribers || 0
      };
    }

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Reddit: ${error.message}`);
  }
}

module.exports = scrapeReddit;