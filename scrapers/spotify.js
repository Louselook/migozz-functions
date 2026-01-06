const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de artistas en Spotify
 * @param {string} artistInput - Nombre del artista, ID o URL
 * @returns {Promise<Object>} Datos del artista
 */
async function scrapeSpotify(artistInput) {
  console.log(`📥 [Spotify] Iniciando scraping para: ${artistInput}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Determinar URL
    let url;
    if (artistInput.includes('spotify.com')) {
      url = artistInput;
    } else if (artistInput.match(/^[0-9A-Za-z]{22}$/)) {
      // Es un Spotify ID
      url = `https://open.spotify.com/artist/${artistInput}`;
    } else {
      // Buscar el artista
      url = `https://open.spotify.com/search/${encodeURIComponent(artistInput)}/artists`;
    }
    
    console.log(`🌐 [Spotify] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Si es búsqueda, hacer click en el primer resultado
    if (url.includes('/search/')) {
      console.log('🔍 [Spotify] Buscando artista...');
      try {
        await page.waitForSelector('[data-testid="top-result-card"] a, [data-testid="search-category-card-0"] a', { timeout: 10000 });
        const firstResult = await page.$('[data-testid="top-result-card"] a, [data-testid="search-category-card-0"] a');
        if (firstResult) {
          await firstResult.click();
          await new Promise(resolve => setTimeout(resolve, 5000));
        }
      } catch (e) {
        console.log('⚠️ [Spotify] No se encontró el artista en búsqueda');
      }
    }

    // Extraer datos del artista
    const profileData = await page.evaluate(() => {
      let artistName = '';
      let artistId = '';
      let monthlyListeners = 0;
      let followers = 0;
      let profileImageUrl = '';
      let verified = false;
      let genres = [];
      
      // Método 1: Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogUrl = document.querySelector('meta[property="og:url"]');
      
      if (ogTitle) artistName = ogTitle.content;
      if (ogImage) profileImageUrl = ogImage.content;
      
      // Extraer ID de la URL
      if (ogUrl) {
        const match = ogUrl.content.match(/artist\/([0-9A-Za-z]{22})/);
        if (match) artistId = match[1];
      }
      
      // Si no tenemos ID, intentar de la URL actual
      if (!artistId) {
        const urlMatch = window.location.pathname.match(/artist\/([0-9A-Za-z]{22})/);
        if (urlMatch) artistId = urlMatch[1];
      }
      
      // Método 2: Buscar en el DOM
      // Nombre del artista
      const nameEl = document.querySelector('h1[data-testid="entityTitle"], span[data-testid="entityTitle"]');
      if (nameEl) artistName = nameEl.textContent.trim();
      
      // Monthly listeners
      const listenersEl = document.querySelector('[data-testid="monthly-listeners-label"]');
      if (listenersEl) {
        const text = listenersEl.textContent;
        const match = text.match(/(\d+(?:[.,]\d+)?)/);
        if (match) {
          monthlyListeners = parseInt(match[1].replace(/[.,]/g, ''));
        }
      }
      
      // Buscar en el texto de la página
      const bodyText = document.body.innerText;
      
      // Buscar monthly listeners en diferentes formatos
      const listenersPatterns = [
        /(\d+(?:[.,]\d+)?)\s*(?:monthly listeners|oyentes mensuales)/gi,
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:monthly listeners|oyentes mensuales)/gi,
      ];
      
      for (const pattern of listenersPatterns) {
        const matches = bodyText.matchAll(pattern);
        for (const match of matches) {
          let num = parseInt(match[1].replace(/[.,]/g, ''));
          const suffix = match[2]?.toUpperCase();
          if (suffix === 'K') num *= 1000;
          else if (suffix === 'M') num *= 1000000;
          else if (suffix === 'B') num *= 1000000000;
          if (num > monthlyListeners) monthlyListeners = num;
        }
      }
      
      // Buscar followers
      const followersPatterns = [
        /(\d+(?:[.,]\d+)?)\s*(?:followers|seguidores)/gi,
      ];
      
      for (const pattern of followersPatterns) {
        const matches = bodyText.matchAll(pattern);
        for (const match of matches) {
          let num = parseInt(match[1].replace(/[.,]/g, ''));
          if (num > followers && num !== monthlyListeners) followers = num;
        }
      }
      
      // Método 3: Buscar en scripts
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent;
        
        if (text.includes('"artist"') || text.includes('"monthlyListeners"')) {
          try {
            // Monthly listeners
            const mlMatch = text.match(/"monthlyListeners"[:\s]*(\d+)/);
            if (mlMatch) {
              const count = parseInt(mlMatch[1]);
              if (count > monthlyListeners) monthlyListeners = count;
            }
            
            // Followers
            const followersMatch = text.match(/"followers"[:\s]*\{[^}]*"total"[:\s]*(\d+)/);
            if (followersMatch) {
              followers = parseInt(followersMatch[1]) || followers;
            }
            
            // Artist name
            const nameMatch = text.match(/"name"[:\s]*"([^"]+)"[^}]*"type"[:\s]*"artist"/i);
            if (nameMatch && !artistName) artistName = nameMatch[1];
            
            // Genres
            const genresMatch = text.match(/"genres"[:\s]*\[([^\]]+)\]/);
            if (genresMatch) {
              const genresList = genresMatch[1].match(/"([^"]+)"/g);
              if (genresList) {
                genres = genresList.map(g => g.replace(/"/g, ''));
              }
            }
            
            // Image
            const imgMatch = text.match(/"images"[:\s]*\[\s*\{[^}]*"url"[:\s]*"([^"]+)"/);
            if (imgMatch && !profileImageUrl) profileImageUrl = imgMatch[1];
            
            // Verified
            if (text.includes('"verified":true') || text.includes('"isVerified":true')) {
              verified = true;
            }
          } catch (e) {}
        }
      }
      
      // Imagen del artista
      if (!profileImageUrl) {
        const artistImg = document.querySelector('[data-testid="entity-image"] img, .artist-header img');
        if (artistImg) profileImageUrl = artistImg.src;
      }
      
      return {
        artistId,
        artistName,
        monthlyListeners,
        followers,
        profileImageUrl,
        verified,
        genres
      };
    });

    await browser.close();

    if (!profileData || !profileData.artistName) {
      throw new Error('No se pudieron extraer los datos del artista de Spotify');
    }

    const result = {
      id: profileData.artistId || artistInput,
      username: profileData.artistName,
      full_name: profileData.artistName,
      bio: profileData.genres?.join(', ') || '',
      followers: profileData.followers || profileData.monthlyListeners,
      monthly_listeners: profileData.monthlyListeners,
      profile_image_url: profileData.profileImageUrl,
      verified: profileData.verified,
      genres: profileData.genres,
      url: profileData.artistId 
        ? `https://open.spotify.com/artist/${profileData.artistId}` 
        : `https://open.spotify.com/search/${encodeURIComponent(artistInput)}`,
      platform: 'spotify'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'spotify',
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
      console.warn('[Spotify] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }
    
    console.log(`✅ [Spotify] Scraped: ${result.full_name}`);
    console.log(`   Monthly Listeners: ${result.monthly_listeners}`);
    console.log(`   Followers: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Spotify: ${error.message}`);
  }
}

module.exports = scrapeSpotify;
