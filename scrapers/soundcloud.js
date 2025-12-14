const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de SoundCloud - MEJORADO
 * Usa intercepción de API y múltiples métodos de extracción
 * @param {string} username - Username de SoundCloud
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeSoundCloud(username) {
  console.log(`📥 [SoundCloud] Iniciando scraping para: ${username}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Interceptar respuestas de API de SoundCloud
    let apiData = null;
    await page.setRequestInterception(true);
    
    page.on('request', request => request.continue());
    
    page.on('response', async response => {
      const url = response.url();
      // SoundCloud usa api-v2 para datos de usuario
      if (url.includes('api-v2.soundcloud.com/users') || 
          url.includes('api.soundcloud.com/users') ||
          url.includes('/resolve?url=')) {
        try {
          const json = await response.json();
          if (json && (json.followers_count !== undefined || json.id)) {
            apiData = json;
            console.log(`🔍 [SoundCloud] API interceptada: followers=${json.followers_count}`);
          }
        } catch (e) {}
      }
    });

    const url = `https://soundcloud.com/${username}`;
    console.log(`🌐 [SoundCloud] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Si obtuvimos datos de la API
    if (apiData && apiData.followers_count !== undefined) {
      await browser.close();
      
      const result = {
        id: apiData.id?.toString() || username,
        username: apiData.permalink || username,
        full_name: apiData.full_name || apiData.username || username,
        bio: apiData.description || '',
        location: apiData.city || apiData.country_code || '',
        followers: apiData.followers_count || 0,
        following: apiData.followings_count || 0,
        tracks: apiData.track_count || 0,
        profile_image_url: apiData.avatar_url?.replace('-large', '-t500x500') || apiData.avatar_url || '',
        verified: apiData.verified || false,
        url: apiData.permalink_url || `https://soundcloud.com/${username}`,
        platform: 'soundcloud'
      };
      
      console.log(`✅ [SoundCloud] Via API: ${result.full_name}, followers: ${result.followers}`);
      return result;
    }

    const profileData = await page.evaluate(() => {
      let fullName = '';
      let bio = '';
      let followers = 0;
      let following = 0;
      let tracks = 0;
      let profileImageUrl = '';
      let location = '';
      let verified = false;
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');
      
      if (ogTitle) fullName = ogTitle.content;
      if (ogImage) profileImageUrl = ogImage.content;
      if (ogDescription) bio = ogDescription.content;
      
      function parseNumber(text) {
        if (!text) return 0;
        text = text.trim().toLowerCase();
        
        const match = text.match(/(\d+(?:[.,]\d+)?)\s*([kmb])?/i);
        if (!match) return 0;
        
        let num = parseFloat(match[1].replace(/,/g, ''));
        const suffix = match[2]?.toLowerCase();
        
        if (suffix === 'k') num *= 1000;
        else if (suffix === 'm') num *= 1000000;
        else if (suffix === 'b') num *= 1000000000;
        
        return Math.round(num);
      }
      
      // MÉTODO 1: Buscar en __sc_hydration (SoundCloud hydration data)
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent || '';
        
        // SoundCloud almacena datos en window.__sc_hydration
        if (text.includes('__sc_hydration') || text.includes('followers_count')) {
          // followers_count
          const followersMatch = text.match(/"followers_count"\s*:\s*(\d+)/);
          if (followersMatch) {
            const count = parseInt(followersMatch[1]);
            if (count > followers) {
              followers = count;
              console.log('[SoundCloud Debug] Found followers_count:', count);
            }
          }
          
          // followings_count
          const followingMatch = text.match(/"followings_count"\s*:\s*(\d+)/);
          if (followingMatch) {
            following = parseInt(followingMatch[1]) || following;
          }
          
          // track_count
          const tracksMatch = text.match(/"track_count"\s*:\s*(\d+)/);
          if (tracksMatch) {
            tracks = parseInt(tracksMatch[1]) || tracks;
          }
          
          // full_name
          const nameMatch = text.match(/"full_name"\s*:\s*"([^"]+)"/);
          if (nameMatch && !fullName) fullName = nameMatch[1];
          
          // username como fallback
          if (!fullName) {
            const usernameMatch = text.match(/"username"\s*:\s*"([^"]+)"/);
            if (usernameMatch) fullName = usernameMatch[1];
          }
          
          // city
          const cityMatch = text.match(/"city"\s*:\s*"([^"]+)"/);
          if (cityMatch) location = cityMatch[1];
          
          // avatar_url
          const imgMatch = text.match(/"avatar_url"\s*:\s*"([^"]+)"/);
          if (imgMatch && !profileImageUrl) {
            profileImageUrl = imgMatch[1].replace('-large', '-t500x500');
          }
          
          // description
          const descMatch = text.match(/"description"\s*:\s*"([^"]+)"/);
          if (descMatch && !bio) bio = descMatch[1];
          
          // verified
          if (text.includes('"verified":true')) verified = true;
        }
      }
      
      // MÉTODO 2: Buscar en elementos del DOM
      const nameEl = document.querySelector('.profileHeaderInfo__userName, h1[itemprop="name"], .userBadge__username');
      if (nameEl && !fullName) fullName = nameEl.textContent.trim();
      
      // Stats en elementos específicos de SoundCloud
      const statsElements = document.querySelectorAll('.infoStats__stat, [class*="InfoStats"] a');
      for (const el of statsElements) {
        const titleEl = el.querySelector('.infoStats__title, [class*="title"]');
        const valueEl = el.querySelector('.infoStats__value, [class*="value"]');
        
        const title = (titleEl?.textContent || el.title || el.getAttribute('title') || '').toLowerCase();
        const value = valueEl?.textContent || el.textContent || '';
        
        if (title.includes('followers') || title.includes('seguidores')) {
          const count = parseNumber(value);
          if (count > followers) followers = count;
        } else if (title.includes('following')) {
          const count = parseNumber(value);
          if (count > following) following = count;
        } else if (title.includes('tracks') || title.includes('pistas')) {
          const count = parseNumber(value);
          if (count > tracks) tracks = count;
        }
      }
      
      // MÉTODO 3: Buscar en el texto visible
      const bodyText = document.body.innerText;
      
      const followersPatterns = [
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:followers|seguidores)/gi,
      ];
      
      for (const pattern of followersPatterns) {
        pattern.lastIndex = 0;
        let match;
        while ((match = pattern.exec(bodyText)) !== null) {
          const count = parseNumber(match[0]);
          if (count > followers) followers = count;
        }
      }
      
      // Verificado
      if (document.querySelector('.profileHeaderInfo__badge, .sc-verified-badge, [class*="verified"]')) {
        verified = true;
      }
      
      // Location
      const locationEl = document.querySelector('.profileHeaderInfo__location, [class*="location"]');
      if (locationEl && !location) location = locationEl.textContent.trim();
      
      // Bio
      const bioEl = document.querySelector('.truncatedUserDescription__content, [class*="bio"], [itemprop="description"]');
      if (bioEl && !bio) bio = bioEl.textContent.trim();
      
      // Avatar
      if (!profileImageUrl) {
        const avatarEl = document.querySelector('.profileHeaderBackground__image span, .userBadge__avatar span, img.userAvatar__image');
        if (avatarEl) {
          const style = avatarEl.getAttribute('style') || '';
          const urlMatch = style.match(/url\("?([^")\s]+)"?\)/);
          if (urlMatch) profileImageUrl = urlMatch[1].replace('-large', '-t500x500');
        }
        
        // Intentar con img
        const imgEl = document.querySelector('img[src*="soundcloud"][src*="avatar"], img.userAvatar__image');
        if (imgEl && imgEl.src) {
          profileImageUrl = imgEl.src.replace('-large', '-t500x500');
        }
      }
      
      return {
        fullName,
        bio,
        followers,
        following,
        tracks,
        profileImageUrl,
        location,
        verified
      };
    });

    await browser.close();
    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de SoundCloud');
    }

    const result = {
      id: username,
      username: username,
      full_name: profileData.fullName || username,
      bio: profileData.bio || '',
      location: profileData.location || '',
      followers: profileData.followers || 0,
      following: profileData.following || 0,
      tracks: profileData.tracks || 0,
      profile_image_url: profileData.profileImageUrl || '',
      verified: profileData.verified || false,
      url: `https://soundcloud.com/${username}`,
      platform: 'soundcloud'
    };
    
    console.log(`✅ [SoundCloud] Via DOM: ${result.full_name}`);
    console.log(`   Followers: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping SoundCloud: ${error.message}`);
  }
}

module.exports = scrapeSoundCloud;
