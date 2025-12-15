const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Reddit (usuarios y subreddits) - VERSIÓN MEJORADA
 * Garantiza extracción de profile_image_url
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
    if (apiData && apiData.profile_image_url) {
      console.log(`✅ [Reddit] Datos obtenidos via API`);
      console.log(`   Profile Image: ${apiData.profile_image_url}`);
      return apiData;
    } else if (apiData) {
      console.log(`⚠️ [Reddit] API sin imagen, intentando Puppeteer...`);
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
  
  console.log(`🌐 [Reddit API] Fetching: ${apiUrl}`);
  
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
  
  console.log(`🔍 [Reddit API] Response keys:`, Object.keys(data));
  
  if (type === 'subreddit') {
    // Para subreddits
    let profileImage = '';
    
    if (data.icon_img && !data.icon_img.includes('styles/')) {
      profileImage = data.icon_img.split('?')[0];
    } else if (data.community_icon && !data.community_icon.includes('styles/')) {
      profileImage = data.community_icon.split('?')[0];
    }
    
    console.log(`🔍 [Reddit API] Subreddit image: ${profileImage}`);
    
    return {
      id: data.id,
      username: data.display_name,
      full_name: data.title,
      bio: data.public_description || data.description || '',
      followers: data.subscribers || 0,
      active_users: data.accounts_active || 0,
      profile_image_url: profileImage,
      banner_url: data.banner_background_image?.split('?')[0] || '',
      created_at: new Date(data.created_utc * 1000).toISOString(),
      is_nsfw: data.over18 || false,
      url: `https://www.reddit.com/r/${name}`,
      platform: 'reddit',
      type: 'subreddit'
    };
  } else {
    // Para usuarios
    let profileImage = '';
    
    // 🔍 MÉTODO 1: icon_img (imagen principal)
    if (data.icon_img && 
        !data.icon_img.includes('default_avatars') &&
        !data.icon_img.includes('styles/')) {
      profileImage = data.icon_img.split('?')[0];
      console.log(`✅ [Reddit API] Using icon_img: ${profileImage}`);
    }
    
    // 🔍 MÉTODO 2: snoovatar_img (avatar personalizado)
    if (!profileImage && data.snoovatar_img) {
      profileImage = data.snoovatar_img;
      console.log(`✅ [Reddit API] Using snoovatar_img: ${profileImage}`);
    }
    
    // 🔍 MÉTODO 3: subreddit.icon_img (perfil de usuario como subreddit)
    if (!profileImage && data.subreddit && data.subreddit.icon_img) {
      const subIcon = data.subreddit.icon_img;
      if (!subIcon.includes('default_avatars') && !subIcon.includes('styles/')) {
        profileImage = subIcon.split('?')[0];
        console.log(`✅ [Reddit API] Using subreddit.icon_img: ${profileImage}`);
      }
    }
    
    console.log(`🔍 [Reddit API] Final profile_image_url: ${profileImage || 'NOT FOUND'}`);
    
    return {
      id: data.id,
      username: data.name,
      full_name: data.subreddit?.title || data.name,
      bio: data.subreddit?.public_description || '',
      followers: data.subreddit?.subscribers || 0,
      karma: (data.link_karma || 0) + (data.comment_karma || 0),
      link_karma: data.link_karma || 0,
      comment_karma: data.comment_karma || 0,
      profile_image_url: profileImage,
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
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const url = type === 'subreddit'
      ? `https://www.reddit.com/r/${name}/`
      : `https://www.reddit.com/user/${name}/`;
    
    console.log(`🌐 [Reddit Puppeteer] Navegando a: ${url}`);
    
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
      
      // 🔍 MEJORADO: Buscar imagen de perfil en múltiples lugares
      if (ogImage && !ogImage.content.includes('default')) {
        profileImageUrl = ogImage.content;
        console.log('[Puppeteer] Found og:image:', profileImageUrl);
      }
      
      if (ogDescription) description = ogDescription.content;
      
      // 🔍 Buscar en elementos del DOM
      if (!profileImageUrl) {
        const avatarSelectors = [
          'img[alt*="avatar" i]',
          'img[class*="Avatar"]',
          'img[src*="avatars"]',
          'img[src*="styles.redd"]',
          '.ProfileCard img',
          '[data-testid="profile-avatar"] img',
        ];
        
        for (const sel of avatarSelectors) {
          try {
            const img = document.querySelector(sel);
            if (img && img.src && 
                !img.src.includes('default') && 
                !img.src.includes('pixel.reddit')) {
              profileImageUrl = img.src;
              console.log('[Puppeteer] Found via selector:', sel, profileImageUrl);
              break;
            }
          } catch (e) {}
        }
      }
      
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
      
      // 🔍 Buscar en scripts
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent;
        
        // Buscar estadísticas
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
        
        // 🔍 Buscar imagen en JSON
        if (!profileImageUrl) {
          try {
            // Buscar icon_img en JSON
            const iconMatch = text.match(/"icon_img"[:\s]*"([^"]+)"/);
            if (iconMatch && !iconMatch[1].includes('default')) {
              profileImageUrl = iconMatch[1].split('?')[0];
              console.log('[Puppeteer] Found icon_img in script:', profileImageUrl);
            }
            
            // Buscar snoovatar_img
            if (!profileImageUrl) {
              const snooMatch = text.match(/"snoovatar_img"[:\s]*"([^"]+)"/);
              if (snooMatch) {
                profileImageUrl = snooMatch[1];
                console.log('[Puppeteer] Found snoovatar_img in script:', profileImageUrl);
              }
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

    console.log(`✅ [Reddit Puppeteer] Extracted profile_image_url: ${profileData.profileImageUrl || 'NOT FOUND'}`);

    return {
      id: name,
      username: name,
      full_name: profileData.name || name,
      bio: profileData.description || '',
      followers: profileData.subscribers,
      karma: profileData.subscribers, // En Puppeteer usamos karma como followers
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