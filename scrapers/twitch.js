const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Twitch
 * @param {string} username - Username de Twitch
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeTwitch(username) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const url = `https://www.twitch.tv/${username}`;
    console.log(`🌐 [Twitch] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [Twitch] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 8000));

    let profileData = null;

    try {
      profileData = await page.evaluate(() => {
        // Método 1: Buscar en meta tags
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        
        // Método 2: Buscar en el DOM
        let username = window.location.pathname.replace('/', '').split('/')[0];
        let followers = 0;
        let profileImageUrl = ogImage ? ogImage.content : '';
        
        // Intentar extraer followers del texto de la página
        const bodyText = document.body.textContent;
        
        // Patrones para detectar seguidores
        const patterns = [
          /(\d+(?:,\d+)*(?:\.\d+)?[KMB]?)\s+followers/i,
          /(\d+(?:,\d+)*(?:\.\d+)?[KMB]?)\s+seguidores/i,
        ];
        
        for (const pattern of patterns) {
          const match = bodyText.match(pattern);
          if (match) {
            const value = match[1].replace(/,/g, '');
            if (value.includes('K')) followers = Math.round(parseFloat(value) * 1000);
            else if (value.includes('M')) followers = Math.round(parseFloat(value) * 1000000);
            else if (value.includes('B')) followers = Math.round(parseFloat(value) * 1000000000);
            else followers = parseInt(value);
            break;
          }
        }
        
        // Método 3: Buscar datos en scripts de la página
        const scripts = Array.from(document.querySelectorAll('script'));
        for (const script of scripts) {
          try {
            const text = script.textContent;
            
            // Buscar datos del usuario en estructuras JSON
            if (text.includes('"followerCount"') || text.includes('"followers"')) {
              const followerMatch = text.match(/"followerCount["\s:]+(\d+)/i) || 
                                   text.match(/"followers["\s:]+(\d+)/i);
              if (followerMatch && followerMatch[1]) {
                followers = parseInt(followerMatch[1]);
              }
            }
            
            // Buscar imagen de perfil
            if (text.includes('"profileImageURL"') || text.includes('"logo"')) {
              const imageMatch = text.match(/"profileImageURL["\s:]+["']([^"']+)["']/i) ||
                                text.match(/"logo["\s:]+["']([^"']+)["']/i);
              if (imageMatch && imageMatch[1] && !profileImageUrl) {
                profileImageUrl = imageMatch[1];
              }
            }
            
            // Buscar username oficial
            if (text.includes('"login"') && text.includes(username)) {
              const usernameMatch = text.match(/"login["\s:]+["']([^"']+)["']/i);
              if (usernameMatch && usernameMatch[1]) {
                username = usernameMatch[1];
              }
            }
          } catch (e) {
            // Continuar con el siguiente script
          }
        }
        
        return {
          username: username,
          followers: followers,
          profile_image_url: profileImageUrl,
        };
      });
    } catch (evalError) {
      console.error('❌ [Twitch] Error en evaluate:', evalError.message);
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Twitch');
    }

    profileData.url = `https://www.twitch.tv/${profileData.username}`;
    console.log(`✅ [Twitch] Scraped: @${profileData.username}`);
    console.log(`   Followers: ${profileData.followers}`);
    
    return profileData;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Twitch: ${error.message}`);
  }
}

module.exports = scrapeTwitch;