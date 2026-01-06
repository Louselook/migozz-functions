const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de Deezer (artistas)
 * Usa la API pública de Deezer primero, luego Puppeteer como fallback
 * @param {string} artistIdOrName - ID del artista o nombre para buscar
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeDeezer(artistIdOrName) {
  console.log(`📥 [Deezer] Iniciando scraping para: ${artistIdOrName}`);
  
  // Método 1: Intentar con la API pública de Deezer
  try {
    const apiData = await fetchDeezerAPI(artistIdOrName);
    if (apiData && apiData.full_name) {
      console.log(`✅ [Deezer] Datos obtenidos via API`);
      return apiData;
    }
  } catch (apiError) {
    console.log(`⚠️ [Deezer] API no disponible: ${apiError.message}`);
  }
  
  // Método 2: Fallback a Puppeteer
  return await scrapeDeezerWithPuppeteer(artistIdOrName);
}

/**
 * Obtener datos usando la API pública de Deezer
 */
async function fetchDeezerAPI(artistIdOrName) {
  let artistId = artistIdOrName;
  
  // Si no es un ID numérico, buscar el artista
  if (!/^\d+$/.test(artistIdOrName)) {
    const searchUrl = `https://api.deezer.com/search/artist?q=${encodeURIComponent(artistIdOrName)}&limit=1`;
    const searchResponse = await fetch(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    
    if (!searchResponse.ok) {
      throw new Error(`Search API responded with status ${searchResponse.status}`);
    }
    
    const searchData = await searchResponse.json();
    
    if (!searchData.data || searchData.data.length === 0) {
      throw new Error('Artist not found in Deezer');
    }
    
    artistId = searchData.data[0].id;
  }
  
  // Obtener detalles del artista
  const artistUrl = `https://api.deezer.com/artist/${artistId}`;
  const response = await fetch(artistUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
  });
  
  if (!response.ok) {
    throw new Error(`Artist API responded with status ${response.status}`);
  }
  
  const artist = await response.json();
  
  if (artist.error) {
    throw new Error(artist.error.message || 'Artist not found');
  }
  
  return {
    id: artist.id?.toString() || artistIdOrName,
    username: artist.name?.toLowerCase().replace(/\s+/g, '') || artistIdOrName,
    full_name: artist.name || artistIdOrName,
    bio: '',
    followers: artist.nb_fan || 0,
    albums: artist.nb_album || 0,
    profile_image_url: artist.picture_xl || artist.picture_big || artist.picture_medium || artist.picture || '',
    url: artist.link || `https://www.deezer.com/artist/${artist.id}`,
    platform: 'deezer'
  };
}

/**
 * Scraping con Puppeteer como fallback
 */
async function scrapeDeezerWithPuppeteer(artistIdOrName) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Construir URL
    let url;
    if (/^\d+$/.test(artistIdOrName)) {
      url = `https://www.deezer.com/artist/${artistIdOrName}`;
    } else {
      url = `https://www.deezer.com/search/${encodeURIComponent(artistIdOrName)}`;
    }

    console.log(`🌐 [Deezer] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    // Si es búsqueda, hacer clic en el primer artista
    if (url.includes('/search/')) {
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      const artistLink = await page.$('a[href*="/artist/"]');
      if (artistLink) {
        await artistLink.click();
        await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 30000 }).catch(() => {});
      }
    }
    
    await new Promise(resolve => setTimeout(resolve, 4000));

    const profileData = await page.evaluate(() => {
      let artistName = '';
      let artistId = '';
      let profileImageUrl = '';
      let fans = 0;
      
      // Extraer ID de la URL
      const urlMatch = window.location.href.match(/\/artist\/(\d+)/);
      if (urlMatch) artistId = urlMatch[1];
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      
      if (ogTitle) artistName = ogTitle.content.replace(' - Deezer', '').replace(' | Deezer', '').trim();
      if (ogImage) profileImageUrl = ogImage.content;
      
      // Título
      const h1 = document.querySelector('h1');
      if (h1 && !artistName) artistName = h1.textContent.trim();
      
      // Buscar fans/seguidores
      const bodyText = document.body.innerText;
      
      function parseNumber(text) {
        const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
        if (!match) return 0;
        let num = parseFloat(match[1].replace(/,/g, '.').replace(/\s/g, ''));
        const suffix = match[2]?.toUpperCase();
        if (suffix === 'K') num *= 1000;
        else if (suffix === 'M') num *= 1000000;
        else if (suffix === 'B') num *= 1000000000;
        return Math.round(num);
      }
      
      // Patrones para fans
      const fansPatterns = [
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:fans|seguidores|followers)/gi,
      ];
      
      for (const pattern of fansPatterns) {
        const matches = bodyText.matchAll(pattern);
        for (const match of matches) {
          const count = parseNumber(match[0]);
          if (count > fans) fans = count;
        }
      }
      
      // Buscar en scripts JSON
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent;
        if (text.includes('"NB_FAN"') || text.includes('"nb_fan"')) {
          try {
            const fansMatch = text.match(/"(?:NB_FAN|nb_fan)"[:\s]*(\d+)/i);
            if (fansMatch) {
              const count = parseInt(fansMatch[1]);
              if (count > fans) fans = count;
            }
            
            const nameMatch = text.match(/"(?:ART_NAME|name)"[:\s]*"([^"]+)"/);
            if (nameMatch && !artistName) artistName = nameMatch[1];
            
            const imgMatch = text.match(/"(?:ART_PICTURE|picture)"[:\s]*"([^"]+)"/);
            if (imgMatch && !profileImageUrl) {
              profileImageUrl = `https://e-cdns-images.dzcdn.net/images/artist/${imgMatch[1]}/500x500.jpg`;
            }
          } catch (e) {}
        }
      }
      
      return {
        artistId,
        artistName,
        profileImageUrl,
        fans,
        currentUrl: window.location.href
      };
    });

    await browser.close();

    if (!profileData || !profileData.artistName) {
      throw new Error('No se pudieron extraer los datos del artista de Deezer');
    }

    const result = {
      id: profileData.artistId || artistIdOrName,
      username: profileData.artistName.toLowerCase().replace(/\s+/g, ''),
      full_name: profileData.artistName,
      bio: '',
      followers: profileData.fans || 0,
      profile_image_url: profileData.profileImageUrl || '',
      url: profileData.currentUrl || `https://www.deezer.com/artist/${profileData.artistId}`,
      platform: 'deezer'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'deezer',
        username: result.id,
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
      console.warn('[Deezer] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }
    
    console.log(`✅ [Deezer] Scraped: ${result.full_name}`);
    console.log(`   Fans: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Deezer: ${error.message}`);
  }
}

module.exports = scrapeDeezer;
