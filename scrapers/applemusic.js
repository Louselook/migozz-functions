const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Apple Music (artistas)
 * @param {string} artistIdOrUrl - ID del artista o URL de Apple Music
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeAppleMusic(artistIdOrUrl) {
  console.log(`📥 [Apple Music] Iniciando scraping para: ${artistIdOrUrl}`);
  
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
    if (artistIdOrUrl.includes('music.apple.com')) {
      url = artistIdOrUrl;
    } else if (/^\d+$/.test(artistIdOrUrl)) {
      // Es un ID numérico
      url = `https://music.apple.com/artist/${artistIdOrUrl}`;
    } else {
      // Buscar el artista
      url = `https://music.apple.com/us/search?term=${encodeURIComponent(artistIdOrUrl)}`;
    }

    console.log(`🌐 [Apple Music] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    // Si es búsqueda, hacer clic en el primer artista
    if (url.includes('/search')) {
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Buscar y hacer clic en el primer resultado de artista
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
      let genres = [];
      let latestRelease = '';
      let bio = '';
      
      // Extraer ID de la URL
      const urlMatch = window.location.href.match(/\/artist\/(\d+)/);
      if (urlMatch) artistId = urlMatch[1];
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');
      
      if (ogTitle) artistName = ogTitle.content.replace(' on Apple Music', '').replace(' en Apple Music', '').trim();
      if (ogImage) profileImageUrl = ogImage.content;
      if (ogDescription) bio = ogDescription.content;
      
      // Título de la página
      const titleEl = document.querySelector('h1');
      if (titleEl && !artistName) artistName = titleEl.textContent.trim();
      
      // Buscar nombre en selectores específicos
      const nameSelectors = [
        '[class*="artist-header"] h1',
        '[class*="ArtistHeader"] h1',
        '.headings__title',
        '[data-testid="artist-name"]'
      ];
      
      for (const sel of nameSelectors) {
        const el = document.querySelector(sel);
        if (el) {
          artistName = el.textContent.trim();
          break;
        }
      }
      
      // Buscar imagen del artista
      const imgSelectors = [
        '[class*="artist-artwork"] img',
        '[class*="ArtistHeader"] img',
        'picture img[srcset]',
        '.headings__artwork img'
      ];
      
      for (const sel of imgSelectors) {
        const img = document.querySelector(sel);
        if (img && (img.src || img.srcset)) {
          profileImageUrl = img.src || img.srcset.split(' ')[0];
          break;
        }
      }
      
      // Buscar géneros
      const genreEls = document.querySelectorAll('[class*="genre"], [class*="Genre"]');
      genreEls.forEach(el => {
        const text = el.textContent.trim();
        if (text && !genres.includes(text)) genres.push(text);
      });
      
      // Buscar en JSON-LD
      const ldScripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (const script of ldScripts) {
        try {
          const data = JSON.parse(script.textContent);
          if (data['@type'] === 'MusicGroup' || data['@type'] === 'Person') {
            if (data.name) artistName = data.name;
            if (data.image) profileImageUrl = data.image;
            if (data.description) bio = data.description;
            if (data.genre) {
              genres = Array.isArray(data.genre) ? data.genre : [data.genre];
            }
          }
        } catch (e) {}
      }
      
      // Buscar en scripts de datos
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent;
        if (text.includes('"artistName"') || text.includes('"name"')) {
          try {
            // Buscar nombre del artista
            const nameMatch = text.match(/"artistName"\s*:\s*"([^"]+)"/);
            if (nameMatch && !artistName) artistName = nameMatch[1];
            
            // Buscar artwork
            const artMatch = text.match(/"artwork"\s*:\s*\{[^}]*"url"\s*:\s*"([^"]+)"/);
            if (artMatch && !profileImageUrl) profileImageUrl = artMatch[1].replace('{w}', '400').replace('{h}', '400');
          } catch (e) {}
        }
      }
      
      return {
        artistId,
        artistName,
        profileImageUrl,
        bio,
        genres,
        currentUrl: window.location.href
      };
    });

    await browser.close();

    if (!profileData || !profileData.artistName) {
      throw new Error('No se pudieron extraer los datos del artista de Apple Music');
    }

    const result = {
      id: profileData.artistId || artistIdOrUrl,
      username: profileData.artistName.toLowerCase().replace(/\s+/g, ''),
      full_name: profileData.artistName,
      bio: profileData.bio || '',
      genres: profileData.genres || [],
      followers: 0, // Apple Music no muestra seguidores públicamente
      profile_image_url: profileData.profileImageUrl || '',
      url: profileData.currentUrl || `https://music.apple.com/artist/${profileData.artistId}`,
      platform: 'applemusic'
    };
    
    console.log(`✅ [Apple Music] Scraped: ${result.full_name}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Apple Music: ${error.message}`);
  }
}

module.exports = scrapeAppleMusic;
