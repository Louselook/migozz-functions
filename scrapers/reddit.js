const { createBrowser } = require('../utils/helpers');

/**
 * Fetch con reintentos para manejar errores 403
 */
async function fetchWithRetry(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) return response;
      
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
  
  // Fallback a Puppeteer con old.reddit.com
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
 * Scraping con Puppeteer usando old.reddit.com
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

    // Usar old.reddit.com que es más fácil de scrapear
    const url = type === 'subreddit'
      ? `https://old.reddit.com/r/${name}/about`
      : `https://old.reddit.com/user/${name}/about`;
    
    console.log(`🌐 [Reddit] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 2000));

    const profileData = await page.evaluate((type) => {
      let username = '';
      let karma = 0;
      let linkKarma = 0;
      let commentKarma = 0;
      let subscribers = 0;
      let createdAt = null;
      let profileImageUrl = '';
      let bio = '';
      
      if (type === 'user') {
        // Extraer datos del usuario
        const titleElement = document.querySelector('.titlebox h1');
        if (titleElement) {
          username = titleElement.textContent.trim();
        }
        
        // Extraer karma
        const karmaElements = document.querySelectorAll('.karma');
        karmaElements.forEach(el => {
          const text = el.textContent.toLowerCase();
          if (text.includes('link karma')) {
            const match = text.match(/(\d+(?:,\d+)*)/);
            if (match) linkKarma = parseInt(match[1].replace(/,/g, ''));
          } else if (text.includes('comment karma')) {
            const match = text.match(/(\d+(?:,\d+)*)/);
            if (match) commentKarma = parseInt(match[1].replace(/,/g, ''));
          }
        });
        
        karma = linkKarma + commentKarma;
        
        // Extraer fecha de creación
        const ageElement = document.querySelector('.age time');
        if (ageElement) {
          createdAt = ageElement.getAttribute('datetime');
        }
        
        // Extraer imagen de perfil
        const imgElement = document.querySelector('.profile-img');
        if (imgElement) {
          profileImageUrl = imgElement.src;
        }
        
      } else {
        // Extraer datos del subreddit
        const titleElement = document.querySelector('.titlebox h1');
        if (titleElement) {
          username = titleElement.textContent.replace('/r/', '').trim();
        }
        
        // Extraer subscribers
        const subscribersElement = document.querySelector('.subscribers .number');
        if (subscribersElement) {
          const text = subscribersElement.textContent.replace(/,/g, '');
          subscribers = parseInt(text) || 0;
        }
        
        // Extraer descripción
        const descElement = document.querySelector('.md');
        if (descElement) {
          bio = descElement.textContent.trim();
        }
        
        // Extraer imagen
        const imgElement = document.querySelector('.icon-img');
        if (imgElement) {
          profileImageUrl = imgElement.src;
        }
      }
      
      return {
        username,
        karma,
        linkKarma,
        commentKarma,
        subscribers,
        createdAt,
        profileImageUrl,
        bio
      };
    }, type);

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos de Reddit');
    }

    const baseResult = {
      id: name,
      username: profileData.username || name,
      full_name: profileData.username || name,
      bio: profileData.bio || '',
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
        verified: false,
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