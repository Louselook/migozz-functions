const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Kick
 * @param {string} username - Username de Kick
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeKick(username) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const url = `https://kick.com/${username}`;
    console.log(`🌐 [Kick] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    console.log('⏳ [Kick] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    let profileData = null;

    try {
      profileData = await page.evaluate(() => {
        // Buscar en meta tags
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        
        let username = window.location.pathname.replace('/', '').split('/')[0];
        let followers = 0;
        let profileImageUrl = ogImage ? ogImage.content : '';
        
        // Función para convertir texto con K/M/B a número
        function parseNumber(numStr, suffix) {
          // Remover espacios y convertir comas europeas (83,7) a puntos (83.7)
          let cleanNum = numStr.replace(/\s/g, '');
          
          // Si tiene coma, asumimos formato europeo: 83,7 mil = 83.7K
          if (cleanNum.includes(',')) {
            cleanNum = cleanNum.replace(',', '.');
          }
          
          let num = parseFloat(cleanNum);
          
          if (!suffix) return Math.round(num);
          
          const suffixLower = suffix.toLowerCase();
          if (suffixLower === 'k' || suffixLower === 'mil') return Math.round(num * 1000);
          if (suffixLower === 'm' || suffixLower === 'millones') return Math.round(num * 1000000);
          if (suffixLower === 'b') return Math.round(num * 1000000000);
          
          return Math.round(num);
        }
        
        // Buscar en el texto completo
        const bodyText = document.body.innerText;
        
        // Patrones para buscar followers (español: seguidores, mil, millones)
        const patterns = [
          /(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?\s*seguidores/gi,
          /(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?\s*followers/gi,
          /seguidores[:\s]+(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?/gi,
          /followers[:\s]+(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?/gi,
        ];
        
        for (const pattern of patterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const number = match[1];
            const suffix = match[2];
            
            const count = parseNumber(number, suffix);
            
            if (count > 100 && count > followers) {
              followers = count;
            }
          }
        }
        
        // Buscar en selectores específicos (Kick puede usar clases diferentes)
        const selectors = [
          '[data-test="followers-count"]',
          '.follower-count',
          '.followers-count',
          '[class*="follower"]',
        ];
        
        for (const selector of selectors) {
          const el = document.querySelector(selector);
          if (el && el.textContent) {
            const text = el.textContent.trim();
            const match = text.match(/(\d+(?:[.,]\d+)?)\s*(mil|millones|k|m|b)?/i);
            if (match) {
              const count = parseNumber(match[1], match[2]);
              if (count > followers) {
                followers = count;
              }
            }
          }
        }
        
        // Buscar imagen de perfil en diferentes lugares
        if (!profileImageUrl) {
          const imgSelectors = [
            'img[alt*="profile"]',
            'img[class*="avatar"]',
            'img[class*="profile"]',
            '.channel-avatar img',
            '[class*="ProfilePicture"] img',
          ];
          
          for (const selector of imgSelectors) {
            const img = document.querySelector(selector);
            if (img && img.src) {
              profileImageUrl = img.src;
              break;
            }
          }
        }
        
        // Buscar en scripts JSON
        const scripts = Array.from(document.querySelectorAll('script'));
        for (const script of scripts) {
          try {
            const text = script.textContent;
            
            // Buscar datos de followers en JSON
            if (text.includes('"followers_count"') || text.includes('"followersCount"')) {
              const match = text.match(/"(?:followers_count|followersCount)"[:\s]+(\d+)/i);
              if (match && match[1]) {
                const count = parseInt(match[1]);
                if (count > followers) {
                  followers = count;
                }
              }
            }
            
            // Buscar imagen de perfil en JSON
            if (!profileImageUrl && text.includes('"profile_pic"')) {
              const imgMatch = text.match(/"profile_pic"[:\s]+"([^"]+)"/i);
              if (imgMatch && imgMatch[1]) {
                profileImageUrl = imgMatch[1];
              }
            }
            
            // Otro formato común
            if (!profileImageUrl && text.includes('"avatar"')) {
              const imgMatch = text.match(/"avatar"[:\s]+"([^"]+)"/i);
              if (imgMatch && imgMatch[1]) {
                profileImageUrl = imgMatch[1];
              }
            }
          } catch (e) {
            // Ignorar errores
          }
        }
        
        // Buscar el username en el título si no lo tenemos
        if (ogTitle && ogTitle.content) {
          const titleMatch = ogTitle.content.match(/^([^\s-|]+)/);
          if (titleMatch && titleMatch[1]) {
            username = titleMatch[1].trim();
          }
        }
        
        return {
          username: username,
          followers: followers,
          profile_image_url: profileImageUrl,
        };
      });
    } catch (evalError) {
      console.error('❌ [Kick] Error en evaluate:', evalError.message);
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Kick');
    }

    profileData.url = `https://kick.com/${profileData.username}`;
    console.log(`✅ [Kick] Scraped: @${profileData.username}`);
    console.log(`   Followers: ${profileData.followers}`);
    
    return profileData;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Kick: ${error.message}`);
  }
}

module.exports = scrapeKick;