const { createBrowser } = require('../utils/helpers');

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
  
  const response = await fetch(apiUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json'
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
      // id: data.id,
      // username: data.display_name,
      // full_name: data.title,
      // bio: data.public_description || data.description || '',
      // followers: data.subscribers || 0,
      // active_users: data.accounts_active || 0,
      // profile_image_url: data.icon_img?.split('?')[0] || data.community_icon?.split('?')[0] || '',
      // banner_url: data.banner_background_image?.split('?')[0] || '',
      // created_at: new Date(data.created_utc * 1000).toISOString(),
      // is_nsfw: data.over18 || false,
      // url: `https://www.reddit.com/r/${name}`,
      // platform: 'reddit',
      // type: 'subreddit'
    };
  } else {
    return {
      // id: data.id,
      // username: data.name,
      // full_name: data.subreddit?.title || data.name,
      // bio: data.subreddit?.public_description || '',
      // followers: data.subreddit?.subscribers || 0,
      // karma: (data.link_karma || 0) + (data.comment_karma || 0),
      // link_karma: data.link_karma || 0,
      // comment_karma: data.comment_karma || 0,
      // profile_image_url: data.icon_img?.split('?')[0] || data.snoovatar_img || '',
      // created_at: new Date(data.created_utc * 1000).toISOString(),
      // verified: data.verified || false,
      // is_gold: data.is_gold || false,
      // url: `https://www.reddit.com/user/${name}`,
      // platform: 'reddit',
      // type: 'user'
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
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const url = type === 'subreddit'
      ? `https://www.reddit.com/r/${name}/`
      : `https://www.reddit.com/user/${name}/`;
    
    console.log(`🌐 [Reddit] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 5000));

    const profileData = await page.evaluate((type) => {
      let name = '';
      let title = '';
      let description = '';
      let subscribers = 0;
      let profileImageUrl = '';
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');
      
      if (ogTitle) title = ogTitle.content;
      if (ogImage) profileImageUrl = ogImage.content;
      if (ogDescription) description = ogDescription.content;
      
      // Buscar subscribers/karma
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
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*karma/gi,
        ];
        
        for (const pattern of karmaPatterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const count = parseNumber(match[0]);
            if (count > subscribers) subscribers = count;
          }
        }
      }
      
      // Buscar en scripts
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent;
        
        if (text.includes('"subscribers"') || text.includes('"karma"')) {
          try {
            const subsMatch = text.match(/"subscribers"[:\s]*(\d+)/);
            if (subsMatch) {
              const count = parseInt(subsMatch[1]);
              if (count > subscribers) subscribers = count;
            }
            
            const karmaMatch = text.match(/"(?:total_karma|link_karma)"[:\s]*(\d+)/);
            if (karmaMatch && type === 'user') {
              const count = parseInt(karmaMatch[1]);
              if (count > subscribers) subscribers = count;
            }
          } catch (e) {}
        }
      }
      
      return {
        name: title,
        description,
        subscribers,
        profileImageUrl
      };
    }, type);

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos de Reddit');
    }

    return {
      id: name,
      username: name,
      full_name: profileData.name || name,
      bio: profileData.description || '',
      followers: profileData.subscribers,
      profile_image_url: profileData.profileImageUrl || '',
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
