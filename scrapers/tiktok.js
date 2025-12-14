const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de TikTok
 * Usa múltiples métodos de extracción para mayor confiabilidad
 * @param {string} username - Username de TikTok (sin @)
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeTikTok(username) {
  // Limpiar el username (quitar @ si existe)
  username = username.replace('@', '').trim();
  
  console.log(`📥 [TikTok] Iniciando scraping para: ${username}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Interceptar respuestas de API
    let apiData = null;
    await page.setRequestInterception(true);
    
    page.on('request', request => request.continue());
    
    page.on('response', async response => {
      const url = response.url();
      // Capturar datos de la API interna de TikTok
      if (url.includes('/api/user/detail') || url.includes('webapp/user/detail')) {
        try {
          const json = await response.json();
          if (json?.userInfo) {
            apiData = json.userInfo;
          }
        } catch (e) {}
      }
    });

    const url = `https://www.tiktok.com/@${username}`;
    console.log(`🌐 [TikTok] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [TikTok] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 8000));

    let profileData = null;
    
    // Método 1: Extraer del script __UNIVERSAL_DATA_FOR_REHYDRATION__
    try {
      profileData = await page.evaluate(() => {
        // Buscar en el script de datos universales (método más confiable)
        const scripts = Array.from(document.querySelectorAll('script'));
        
        for (const script of scripts) {
          if (script.id === '__UNIVERSAL_DATA_FOR_REHYDRATION__') {
            try {
              const data = JSON.parse(script.textContent);
              const userDetail = data.__DEFAULT_SCOPE__?.['webapp.user-detail'];
              if (userDetail?.userInfo) {
                const user = userDetail.userInfo.user;
                const stats = userDetail.userInfo.stats;
                return {
                  id: user.id,
                  username: user.uniqueId,
                  full_name: user.nickname,
                  followers: stats.followerCount,
                  following: stats.followingCount,
                  likes: stats.heartCount,
                  videos: stats.videoCount,
                  bio: user.signature,
                  profile_image_url: user.avatarLarger || user.avatarMedium || user.avatarThumb,
                  verified: user.verified,
                  source: 'rehydration'
                };
              }
            } catch (e) {
              console.error('Error parsing rehydration data:', e);
            }
          }
          
          // Método 2: Buscar en SIGI_STATE (formato alternativo)
          if (script.id === 'SIGI_STATE' || script.id === '__NEXT_DATA__') {
            try {
              const data = JSON.parse(script.textContent);
              const userModule = data?.UserModule || data?.props?.pageProps;
              if (userModule?.users) {
                const userKey = Object.keys(userModule.users)[0];
                const user = userModule.users[userKey];
                const stats = userModule.stats?.[userKey];
                return {
                  id: user.id,
                  username: user.uniqueId,
                  full_name: user.nickname,
                  followers: stats?.followerCount || 0,
                  following: stats?.followingCount || 0,
                  likes: stats?.heartCount || 0,
                  videos: stats?.videoCount || 0,
                  bio: user.signature,
                  profile_image_url: user.avatarLarger || user.avatarMedium,
                  verified: user.verified,
                  source: 'sigi_state'
                };
              }
            } catch (e) {}
          }
        }
        
        // Método 3: Buscar en cualquier script con datos de usuario
        for (const script of scripts) {
          try {
            const text = script.textContent;
            if (text.includes('"uniqueId"') && text.includes('"followerCount"')) {
              // Extraer datos con regex como último recurso
              const uniqueIdMatch = text.match(/"uniqueId"\s*:\s*"([^"]+)"/);
              const followerMatch = text.match(/"followerCount"\s*:\s*(\d+)/);
              const nicknameMatch = text.match(/"nickname"\s*:\s*"([^"]+)"/);
              const avatarMatch = text.match(/"avatarLarger"\s*:\s*"([^"]+)"/);
              const bioMatch = text.match(/"signature"\s*:\s*"([^"]*)"/);
              
              if (uniqueIdMatch && followerMatch) {
                return {
                  id: uniqueIdMatch[1],
                  username: uniqueIdMatch[1],
                  full_name: nicknameMatch?.[1] || uniqueIdMatch[1],
                  followers: parseInt(followerMatch[1]),
                  bio: bioMatch?.[1] || '',
                  profile_image_url: avatarMatch?.[1]?.replace(/\\u002F/g, '/') || '',
                  source: 'regex'
                };
              }
            }
          } catch (e) {}
        }
        
        return null;
      });
    } catch (evalError) {
      console.error('❌ [TikTok] Error en evaluate:', evalError.message);
    }

    // Si tenemos datos de la API interceptada, usarlos
    if (!profileData && apiData) {
      profileData = {
        id: apiData.user?.id,
        username: apiData.user?.uniqueId,
        full_name: apiData.user?.nickname,
        followers: apiData.stats?.followerCount || 0,
        following: apiData.stats?.followingCount || 0,
        likes: apiData.stats?.heartCount || 0,
        videos: apiData.stats?.videoCount || 0,
        bio: apiData.user?.signature || '',
        profile_image_url: apiData.user?.avatarLarger || '',
        verified: apiData.user?.verified || false,
        source: 'api_intercept'
      };
    }

    // Método 4: Extracción del DOM como último recurso
    if (!profileData || !profileData.followers) {
      console.log('⚠️ [TikTok] Intentando extracción del DOM...');
      
      const domData = await page.evaluate(() => {
        let followers = 0;
        let fullName = '';
        let bio = '';
        let profileImage = '';
        
        // Buscar en meta tags
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        
        if (ogImage) profileImage = ogImage.content;
        if (ogTitle) fullName = ogTitle.content;
        
        // Buscar followers en el texto
        const bodyText = document.body.innerText;
        
        function parseNumber(numStr, suffix) {
          let num = parseFloat(numStr.replace(/[,\s]/g, '').replace(/\./g, ''));
          if (!suffix) return num;
          const s = suffix.toUpperCase();
          if (s === 'K') return Math.round(num * 1000);
          if (s === 'M') return Math.round(num * 1000000);
          if (s === 'B') return Math.round(num * 1000000000);
          return num;
        }
        
        const patterns = [
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:followers|seguidores)/gi,
          /(?:followers|seguidores)[:\s]+(\d+(?:[.,]\d+)?)\s*([KMB])?/gi,
        ];
        
        for (const pattern of patterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const count = parseNumber(match[1], match[2]);
            if (count > 100 && count > followers) {
              followers = count;
            }
          }
        }
        
        // Buscar nombre y bio en selectores específicos
        const nameEl = document.querySelector('h1[data-e2e="user-title"]') || 
                       document.querySelector('h2[data-e2e="user-subtitle"]');
        if (nameEl) fullName = nameEl.textContent.trim();
        
        const bioEl = document.querySelector('h2[data-e2e="user-bio"]');
        if (bioEl) bio = bioEl.textContent.trim();
        
        return { followers, full_name: fullName, bio, profile_image_url: profileImage };
      });
      
      if (domData.followers > 0) {
        profileData = profileData || {};
        if (domData.followers > (profileData.followers || 0)) {
          profileData.followers = domData.followers;
        }
        if (!profileData.full_name) profileData.full_name = domData.full_name;
        if (!profileData.bio) profileData.bio = domData.bio;
        if (!profileData.profile_image_url) profileData.profile_image_url = domData.profile_image_url;
      }
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de TikTok');
    }

    // Asegurar campos básicos
    profileData.username = profileData.username || username;
    profileData.id = profileData.id || username;
    profileData.url = `https://www.tiktok.com/@${profileData.username}`;
    profileData.platform = 'tiktok';
    
    console.log(`✅ [TikTok] Scraped: ${profileData.full_name} (@${profileData.username})`);
    console.log(`   Followers: ${profileData.followers}`);
    console.log(`   Source: ${profileData.source || 'unknown'}`);
    
    // Limpiar el campo source antes de retornar
    delete profileData.source;
    
    return profileData;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping TikTok: ${error.message}`);
  }
}

module.exports = scrapeTikTok;
