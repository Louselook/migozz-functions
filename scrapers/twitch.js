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
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    console.log('⏳ [Twitch] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 12000));

    let profileData = null;

    try {
      profileData = await page.evaluate(() => {
        // Método 1: Buscar en meta tags
        const ogImage = document.querySelector('meta[property="og:image"]');
        
        let username = window.location.pathname.replace('/', '').split('/')[0];
        let followers = 0;
        let profileImageUrl = ogImage ? ogImage.content : '';
        
        // Función simplificada para convertir texto con K/M/B a número
        function parseNumber(numStr, suffix) {
          // Limpiar el número: remover comas y espacios
          let num = parseFloat(numStr.replace(/[,\s]/g, '').replace(/\./g, ''));
          
          if (!suffix) return num;
          
          const suffixUpper = suffix.toUpperCase();
          if (suffixUpper === 'K') return Math.round(num * 1000);
          if (suffixUpper === 'M') return Math.round(num * 1000000);
          if (suffixUpper === 'B') return Math.round(num * 1000000000);
          
          return num;
        }
        
        // Buscar en el texto completo de la página
        const bodyText = document.body.innerText;
        
        // Patrones para buscar followers
        const patterns = [
          // Formato: "16 M seguidores" o "570.945 seguidores"
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*seguidores/gi,
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*followers/gi,
        ];
        
        for (const pattern of patterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const number = match[1];   // "16" o "570.945"
            const suffix = match[2];    // "M" o undefined
            
            const count = parseNumber(number, suffix);
            
            // Solo tomar números que tengan sentido como followers (> 100)
            if (count > 100 && count > followers) {
              followers = count;
            }
          }
        }
        
        // Método 2: Buscar en selectores específicos de Twitch
        const selectors = [
          '[data-a-target="followers-count"]',
          '.tw-stat__value',
          'div[data-test-selector="FollowersCount"]',
        ];
        
        for (const selector of selectors) {
          const el = document.querySelector(selector);
          if (el && el.textContent) {
            const text = el.textContent.trim();
            const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
            if (match) {
              const count = parseNumber(match[1], match[2]);
              if (count > followers) {
                followers = count;
              }
            }
          }
        }
        
        // Método 3: Buscar en scripts JSON
        const scripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
        for (const script of scripts) {
          try {
            const data = JSON.parse(script.textContent);
            if (data.interactionStatistic) {
              const followersStat = data.interactionStatistic.find(
                stat => stat['@type'] === 'InteractionCounter' && 
                        stat.interactionType === 'http://schema.org/FollowAction'
              );
              if (followersStat && followersStat.userInteractionCount) {
                const count = parseInt(followersStat.userInteractionCount);
                if (count > followers) {
                  followers = count;
                }
              }
            }
          } catch (e) {
            // Ignorar errores de parsing
          }
        }
        
        // Método 4: Buscar en otros scripts
        const allScripts = Array.from(document.querySelectorAll('script'));
        for (const script of allScripts) {
          try {
            const text = script.textContent;
            
            if (text.includes('"followerCount"') || text.includes('"followers"')) {
              // Buscar patrón: "followerCount":16000000 o "followers":16000000
              const match = text.match(/"(?:followerCount|followers)"[:\s]+(\d+)/i);
              if (match && match[1]) {
                const count = parseInt(match[1]);
                if (count > followers) {
                  followers = count;
                }
              }
            }
            
            // Buscar imagen de perfil
            if (!profileImageUrl && (text.includes('"profileImageURL"') || text.includes('"logo"'))) {
              const imgMatch = text.match(/"(?:profileImageURL|logo)"[:\s]+"([^"]+)"/i);
              if (imgMatch && imgMatch[1]) {
                profileImageUrl = imgMatch[1];
              }
            }
          } catch (e) {
            // Ignorar errores
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