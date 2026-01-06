const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de Twitter/X
 * @param {string} username - Username de Twitter (sin @)
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeTwitter(username) {
  username = username.replace('@', '').trim();
  console.log(`📥 [Twitter/X] Iniciando scraping para: ${username}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Interceptar respuestas de la API GraphQL
    let apiData = null;
    await page.setRequestInterception(true);
    
    page.on('request', request => request.continue());
    
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('/graphql/') && url.includes('UserByScreenName')) {
        try {
          const json = await response.json();
          if (json?.data?.user?.result) {
            apiData = json.data.user.result;
          }
        } catch (e) {}
      }
    });

    const url = `https://twitter.com/${username}`;
    console.log(`🌐 [Twitter/X] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [Twitter/X] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    let profileData = null;

    // Si capturamos datos de la API GraphQL
    if (apiData) {
      const legacy = apiData.legacy || apiData;
      profileData = {
        id: apiData.rest_id || apiData.id,
        username: legacy.screen_name || username,
        full_name: legacy.name,
        bio: legacy.description,
        followers: legacy.followers_count || 0,
        following: legacy.friends_count || 0,
        tweets: legacy.statuses_count || 0,
        likes: legacy.favourites_count || 0,
        // Prefer original/full-size profile image when possible
        profile_image_url: legacy.profile_image_url_https
          ? legacy.profile_image_url_https.replace('_normal', '')
          : '',
        verified: legacy.verified || apiData.is_blue_verified || false,
        location: legacy.location || '',
        created_at: legacy.created_at,
      };
    }

    // Extraer del DOM si no tenemos datos de API
    if (!profileData) {
      profileData = await page.evaluate(() => {
        // Método 1: Meta tags
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogDescription = document.querySelector('meta[property="og:description"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        
        let followers = 0;
        let following = 0;
        let tweets = 0;
        let fullName = '';
        let bio = '';
        let profileImageUrl = ogImage ? ogImage.content : '';
        
        // Extraer nombre del título
        if (ogTitle) {
          const match = ogTitle.content.match(/^([^(]+)\s*\(@/);
          if (match) fullName = match[1].trim();
        }
        
        // Extraer bio de description
        if (ogDescription) {
          bio = ogDescription.content;
        }
        
        function parseNumber(text) {
          if (!text) return 0;
          const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
          if (!match) return 0;
          let num = parseFloat(match[1].replace(/,/g, ''));
          const suffix = match[2]?.toUpperCase();
          if (suffix === 'K') num *= 1000;
          else if (suffix === 'M') num *= 1000000;
          else if (suffix === 'B') num *= 1000000000;
          return Math.round(num);
        }
        
        // Método 2: Buscar en elementos del DOM
        const links = document.querySelectorAll('a[href*="/followers"], a[href*="/following"]');
        for (const link of links) {
          const text = link.textContent || '';
          const href = link.getAttribute('href') || '';
          
          if (href.includes('/followers') || href.includes('/verified_followers')) {
            followers = parseNumber(text) || followers;
          } else if (href.includes('/following')) {
            following = parseNumber(text) || following;
          }
        }
        
        // Buscar tweets/posts
        const headerStats = document.querySelector('[data-testid="primaryColumn"] h2');
        if (headerStats) {
          const parent = headerStats.closest('div');
          if (parent) {
            const text = parent.textContent;
            if (text.includes('posts') || text.includes('Tweets')) {
              tweets = parseNumber(text);
            }
          }
        }
        
        // Buscar nombre y bio en el perfil
        const nameEl = document.querySelector('[data-testid="UserName"]');
        if (nameEl) {
          const spans = nameEl.querySelectorAll('span');
          if (spans.length > 0) fullName = spans[0].textContent.trim();
        }
        
        const bioEl = document.querySelector('[data-testid="UserDescription"]');
        if (bioEl) {
          bio = bioEl.textContent.trim();
        }
        
        // Buscar imagen de perfil
        const avatarImg = document.querySelector('[data-testid="UserAvatar-Container-unknown"] img, img[alt*="Opens profile photo"]');
        if (avatarImg) {
          // Prefer original/full-size profile image when possible
          profileImageUrl = avatarImg.src?.replace('_normal', '') || profileImageUrl;
        }
        
        // Método 3: Buscar en scripts
        const scripts = Array.from(document.querySelectorAll('script'));
        for (const script of scripts) {
          const text = script.textContent;
          
          if (text.includes('"followers_count"') || text.includes('"friends_count"')) {
            try {
              const followersMatch = text.match(/"followers_count"[:\s]*(\d+)/);
              const followingMatch = text.match(/"friends_count"[:\s]*(\d+)/);
              const tweetsMatch = text.match(/"statuses_count"[:\s]*(\d+)/);
              const nameMatch = text.match(/"name"[:\s]*"([^"]+)"/);
              const descMatch = text.match(/"description"[:\s]*"([^"]+)"/);
              
              if (followersMatch) {
                const count = parseInt(followersMatch[1]);
                if (count > followers) followers = count;
              }
              if (followingMatch) following = parseInt(followingMatch[1]) || following;
              if (tweetsMatch) tweets = parseInt(tweetsMatch[1]) || tweets;
              if (nameMatch && !fullName) fullName = nameMatch[1];
              if (descMatch && !bio) bio = descMatch[1];
            } catch (e) {}
          }
        }
        
        return {
          followers,
          following,
          tweets,
          full_name: fullName,
          bio,
          profile_image_url: profileImageUrl
        };
      });
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Twitter/X');
    }

    const result = {
      id: profileData.id || username,
      username: profileData.username || username,
      full_name: profileData.full_name || '',
      bio: profileData.bio || '',
      followers: profileData.followers || 0,
      following: profileData.following || 0,
      tweets: profileData.tweets || 0,
      likes: profileData.likes || 0,
      profile_image_url: profileData.profile_image_url || '',
      verified: profileData.verified || false,
      location: profileData.location || '',
      url: `https://twitter.com/${username}`,
      platform: 'twitter'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'twitter',
        username,
        imageUrl: result.profile_image_url
      });
      if (saved) {
        result.profile_image_saved = true;
        result.profile_image_path = saved.path;
        if (saved.publicUrl) result.profile_image_public_url = saved.publicUrl;
      } else {
        result.profile_image_saved = false;
      }
    } catch (e) {
      console.warn('[Twitter] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }
    
    console.log(`✅ [Twitter/X] Scraped: ${result.full_name || username}`);
    console.log(`   Followers: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Twitter/X: ${error.message}`);
  }
}

module.exports = scrapeTwitter;
