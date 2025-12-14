const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Pinterest - MEJORADO
 * Extrae la imagen de perfil real del usuario (no el ícono genérico)
 * @param {string} username - Username de Pinterest
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapePinterest(username) {
  username = username.replace('@', '').trim();
  console.log(`📥 [Pinterest] Iniciando scraping para: ${username}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Interceptar respuestas de API de Pinterest
    let apiData = null;
    await page.setRequestInterception(true);
    
    page.on('request', request => request.continue());
    
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('/resource/UserResource') || 
          url.includes('/resource/UserProfileResource') ||
          url.includes('api.pinterest.com') ||
          url.includes('/v3/users/')) {
        try {
          const json = await response.json();
          if (json?.resource_response?.data) {
            apiData = json.resource_response.data;
            console.log(`🔍 [Pinterest] API interceptada`);
          }
        } catch (e) {}
      }
    });

    const url = `https://www.pinterest.com/${username}/`;
    console.log(`🌐 [Pinterest] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Si obtuvimos datos de la API con imagen de perfil real
    if (apiData && apiData.follower_count !== undefined) {
      await browser.close();
      
      // Obtener la mejor imagen disponible (no la genérica)
      let profileImage = '';
      if (apiData.image_xlarge_url && !apiData.image_xlarge_url.includes('default')) {
        profileImage = apiData.image_xlarge_url;
      } else if (apiData.image_large_url && !apiData.image_large_url.includes('default')) {
        profileImage = apiData.image_large_url;
      } else if (apiData.image_medium_url && !apiData.image_medium_url.includes('default')) {
        profileImage = apiData.image_medium_url;
      }
      
      const result = {
        id: apiData.id || username,
        username: apiData.username || username,
        full_name: apiData.full_name || apiData.first_name || username,
        bio: apiData.about || apiData.bio || '',
        followers: apiData.follower_count || 0,
        following: apiData.following_count || 0,
        monthly_views: apiData.pin_count || 0,
        profile_image_url: profileImage,
        url: `https://www.pinterest.com/${username}/`,
        platform: 'pinterest'
      };
      
      console.log(`✅ [Pinterest] Via API: ${result.full_name}, followers: ${result.followers}`);
      return result;
    }

    const profileData = await page.evaluate(() => {
      let fullName = '';
      let bio = '';
      let followers = 0;
      let following = 0;
      let profileImageUrl = '';
      let monthlyViews = 0;
      
      function parseNumber(text) {
        if (!text) return 0;
        text = text.trim().toLowerCase();
        
        // Español: "3,8 mil seguidores"
        const spanishMatch = text.match(/(\d+(?:[.,]\d+)?)\s*mil(?:lones)?/i);
        if (spanishMatch) {
          let num = parseFloat(spanishMatch[1].replace(/,/g, '.'));
          if (text.includes('millon')) num *= 1000000;
          else num *= 1000;
          return Math.round(num);
        }
        
        // Inglés: "3.8K followers"
        const englishMatch = text.match(/(\d+(?:[.,]\d+)?)\s*([kmb])?/i);
        if (englishMatch) {
          let num = parseFloat(englishMatch[1].replace(/,/g, '.'));
          const suffix = englishMatch[2]?.toLowerCase();
          if (suffix === 'k') num *= 1000;
          else if (suffix === 'm') num *= 1000000;
          else if (suffix === 'b') num *= 1000000000;
          return Math.round(num);
        }
        
        return 0;
      }
      
      // MÉTODO 1: Buscar en scripts de Pinterest (__PWS_DATA__, etc)
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent || '';
        
        if (text.includes('follower_count') || text.includes('"full_name"')) {
          // follower_count
          const followersMatch = text.match(/"follower_count"\s*:\s*(\d+)/);
          if (followersMatch) {
            const count = parseInt(followersMatch[1]);
            if (count > followers) followers = count;
          }
          
          // following_count
          const followingMatch = text.match(/"following_count"\s*:\s*(\d+)/);
          if (followingMatch) {
            following = parseInt(followingMatch[1]) || following;
          }
          
          // full_name
          const nameMatch = text.match(/"full_name"\s*:\s*"([^"]+)"/);
          if (nameMatch) fullName = nameMatch[1];
          
          // about/bio
          const bioMatch = text.match(/"about"\s*:\s*"([^"]+)"/);
          if (bioMatch && !bio) bio = bioMatch[1];
          
          // IMAGEN DE PERFIL - Buscar específicamente la imagen del usuario
          // image_xlarge_url es la imagen de perfil grande
          const imgXlargeMatch = text.match(/"image_xlarge_url"\s*:\s*"([^"]+)"/);
          if (imgXlargeMatch && !imgXlargeMatch[1].includes('default') && !imgXlargeMatch[1].includes('pinimg.com/images/')) {
            profileImageUrl = imgXlargeMatch[1];
          }
          
          if (!profileImageUrl) {
            const imgLargeMatch = text.match(/"image_large_url"\s*:\s*"([^"]+)"/);
            if (imgLargeMatch && !imgLargeMatch[1].includes('default') && !imgLargeMatch[1].includes('pinimg.com/images/')) {
              profileImageUrl = imgLargeMatch[1];
            }
          }
          
          if (!profileImageUrl) {
            const imgMediumMatch = text.match(/"image_medium_url"\s*:\s*"([^"]+)"/);
            if (imgMediumMatch && !imgMediumMatch[1].includes('default') && !imgMediumMatch[1].includes('pinimg.com/images/')) {
              profileImageUrl = imgMediumMatch[1];
            }
          }
        }
      }
      
      // MÉTODO 2: Buscar imagen de perfil en el DOM
      // Pinterest pone la imagen de perfil en un elemento específico
      const avatarSelectors = [
        'img[alt*="avatar"]',
        'img[alt*="Avatar"]',
        'img[class*="avatar"]',
        'img[class*="Avatar"]',
        '[data-test-id="avatar"] img',
        '[data-test-id="profile-avatar"] img',
        '.ProfileAvatar img',
        '.userAvatar img',
        // Selector más específico para la imagen de perfil de Pinterest
        'div[data-test-id="profile-header"] img',
        'header img[src*="avatars"]',
        'img[src*="avatars."]',
        'img[src*="/avatars/"]'
      ];
      
      for (const sel of avatarSelectors) {
        try {
          const img = document.querySelector(sel);
          if (img && img.src && 
              !img.src.includes('default') && 
              !img.src.includes('pinimg.com/images/') &&
              !img.src.includes('open_graph')) {
            profileImageUrl = img.src;
            console.log('[Pinterest Debug] Found avatar via selector:', sel);
            break;
          }
        } catch (e) {}
      }
      
      // MÉTODO 3: Buscar todas las imágenes que puedan ser avatares
      if (!profileImageUrl) {
        const allImages = document.querySelectorAll('img');
        for (const img of allImages) {
          const src = img.src || '';
          // Las imágenes de avatar de Pinterest suelen contener "avatars" en la URL
          // o están en el formato específico de avatares
          if (src.includes('avatars') || src.includes('/user/') || src.match(/\/\d+x\d+\/[a-f0-9]+\.jpg/)) {
            if (!src.includes('default') && !src.includes('open_graph') && !src.includes('pinimg.com/images/')) {
              profileImageUrl = src;
              break;
            }
          }
        }
      }
      
      // Meta tags solo como fallback para nombre
      const ogTitle = document.querySelector('meta[property="og:title"]');
      if (ogTitle && !fullName) {
        fullName = ogTitle.content.split('(')[0].trim();
      }
      
      // NO usar og:image porque es el ícono genérico de Pinterest
      
      // Buscar seguidores en el texto
      const bodyText = document.body.innerText;
      const followersPatterns = [
        /(\d+(?:[.,]\d+)?)\s*mil\s*seguidores/gi,
        /(\d+(?:[.,]\d+)?)\s*seguidores/gi,
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*followers/gi,
      ];
      
      for (const pattern of followersPatterns) {
        pattern.lastIndex = 0;
        let match;
        while ((match = pattern.exec(bodyText)) !== null) {
          const count = parseNumber(match[0]);
          if (count > followers) followers = count;
        }
      }
      
      return {
        fullName,
        bio,
        followers,
        following,
        profileImageUrl,
        monthlyViews
      };
    });

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Pinterest');
    }

    const result = {
      id: username,
      username: username,
      full_name: profileData.fullName || username,
      bio: profileData.bio || '',
      followers: profileData.followers || 0,
      following: profileData.following || 0,
      monthly_views: profileData.monthlyViews || 0,
      profile_image_url: profileData.profileImageUrl || '',
      url: `https://www.pinterest.com/${username}/`,
      platform: 'pinterest'
    };
    
    console.log(`✅ [Pinterest] Scraped: ${result.full_name}`);
    console.log(`   Followers: ${result.followers}`);
    console.log(`   Profile Image: ${result.profile_image_url ? 'Found' : 'Not found'}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Pinterest: ${error.message}`);
  }
}

module.exports = scrapePinterest;
