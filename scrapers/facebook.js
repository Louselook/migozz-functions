const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de Facebook
 * Facebook es muy restrictivo, usamos múltiples métodos de extracción
 * @param {string} username - Username o ID de Facebook
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeFacebook(username) {
  console.log(`📥 [Facebook] Iniciando scraping para: ${username}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Configurar headers para parecer más legítimo
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9,es;q=0.8',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache'
    });

    // Interceptar GraphQL responses
    let graphqlData = null;
    await page.setRequestInterception(true);
    
    page.on('request', request => request.continue());
    
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('graphql') || url.includes('/api/graphql')) {
        try {
          const text = await response.text();
          // Buscar datos de página o perfil en respuestas GraphQL
          if (text.includes('"page_likers"') || text.includes('"followers_count"')) {
            const followerMatch = text.match(/"(?:page_likers|followers_count|follower_count)"[:\s]*\{?"(?:count|value)"?[:\s]*(\d+)/i);
            if (followerMatch) {
              graphqlData = graphqlData || {};
              graphqlData.followers = parseInt(followerMatch[1]);
            }
          }
        } catch (e) {}
      }
    });

    const url = `https://www.facebook.com/${username}`;
    console.log(`🌐 [Facebook] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [Facebook] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    // Intentar cerrar popups de login si aparecen
    try {
      const closeBtn = await page.$('[aria-label="Close"]');
      if (closeBtn) await closeBtn.click();
    } catch (e) {}

    let profileData = null;

    try {
      profileData = await page.evaluate(() => {
        // Método 1: Meta tags (más confiable para páginas públicas)
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogDescription = document.querySelector('meta[property="og:description"]');
        
        let name = ogTitle ? ogTitle.content : '';
        let profileImageUrl = ogImage ? ogImage.content : '';
        let bio = ogDescription ? ogDescription.content : '';
        let followers = 0;
        
        // Buscar el nombre en h1
        const nameH1 = document.querySelector('h1');
        if (nameH1 && nameH1.textContent) {
          name = nameH1.textContent.trim();
        }
        
        // Método 2: Buscar followers en el texto de la página
        const bodyText = document.body.innerText;
        
        function parseNumber(numStr, suffix) {
          let cleanNum = numStr.replace(/[,\s]/g, '').replace(/\./g, '');
          let num = parseFloat(cleanNum);
          
          if (!suffix) return Math.round(num);
          
          const s = suffix.toUpperCase();
          if (s === 'K' || s === 'MIL') return Math.round(num * 1000);
          if (s === 'M' || s === 'MILLONES' || s === 'MILLION') return Math.round(num * 1000000);
          if (s === 'B' || s === 'BILLION') return Math.round(num * 1000000000);
          
          return Math.round(num);
        }
        
        // Patrones para buscar followers en múltiples idiomas
        const patterns = [
          /(\d+(?:[.,]\d+)?)\s*([KMB]|mil|millones?|million|billion)?\s*(?:followers|seguidores|people follow this)/gi,
          /(?:followers|seguidores|people follow)[:\s]+(\d+(?:[.,]\d+)?)\s*([KMB]|mil|millones?)?/gi,
          /(\d+(?:[.,]\d+)?)\s*([KMB]|mil)?\s*(?:likes?|me gusta)/gi,
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*people like this/gi,
        ];
        
        for (const pattern of patterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const count = parseNumber(match[1], match[2]);
            // Solo tomar números que parezcan followers reales
            if (count > 100 && count > followers) {
              followers = count;
            }
          }
        }
        
        // Método 3: Buscar en elementos específicos
        const followerSelectors = [
          'a[href*="followers"]',
          'a[href*="people_follow"]',
          '[role="main"] span',
        ];
        
        for (const selector of followerSelectors) {
          const elements = document.querySelectorAll(selector);
          for (const el of elements) {
            const text = el.textContent || '';
            if (text.match(/followers|seguidores|follow this/i)) {
              const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB]|mil|millones?)?/i);
              if (match) {
                const count = parseNumber(match[1], match[2]);
                if (count > followers) {
                  followers = count;
                }
              }
            }
          }
        }
        
        // Método 4: Buscar en scripts JSON-LD o datos embebidos
        const scripts = Array.from(document.querySelectorAll('script'));
        for (const script of scripts) {
          try {
            const text = script.textContent;
            
            // Buscar datos estructurados
            if (text.includes('"@type":"Organization"') || text.includes('"@type":"Person"')) {
              try {
                const jsonData = JSON.parse(text);
                if (jsonData.interactionStatistic) {
                  const followerStat = jsonData.interactionStatistic.find(
                    s => s.interactionType?.includes('Follow')
                  );
                  if (followerStat?.userInteractionCount) {
                    const count = parseInt(followerStat.userInteractionCount);
                    if (count > followers) followers = count;
                  }
                }
              } catch (e) {}
            }
            
            // Buscar patrones en cualquier script
            if (text.includes('"follower_count"') || text.includes('"followers_count"')) {
              const match = text.match(/"(?:follower_count|followers_count)"[:\s]+(\d+)/i);
              if (match && match[1]) {
                const count = parseInt(match[1]);
                if (count > followers) followers = count;
              }
            }
            
            // Buscar page_likers (formato de Facebook para páginas)
            if (text.includes('"page_likers"')) {
              const match = text.match(/"page_likers"[:\s]*\{[^}]*"count"[:\s]*(\d+)/i);
              if (match && match[1]) {
                const count = parseInt(match[1]);
                if (count > followers) followers = count;
              }
            }
          } catch (e) {}
        }
        
        // Extraer username de la URL
        const pathname = window.location.pathname;
        const extractedUsername = pathname.replace('/', '').split('/')[0];
        
        return {
          id: extractedUsername,
          username: extractedUsername,
          full_name: name,
          bio: bio,
          followers: followers,
          profile_image_url: profileImageUrl,
        };
      });
    } catch (evalError) {
      console.error('❌ [Facebook] Error en evaluate:', evalError.message);
    }

    await browser.close();

    // Combinar con datos GraphQL interceptados
    if (graphqlData?.followers && graphqlData.followers > (profileData?.followers || 0)) {
      profileData = profileData || {};
      profileData.followers = graphqlData.followers;
    }

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Facebook');
    }

    // Asegurar campos básicos
    profileData.username = profileData.username || username;
    profileData.id = profileData.id || username;
    profileData.url = `https://www.facebook.com/${profileData.username}`;
    profileData.platform = 'facebook';

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'facebook',
        username: profileData.username,
        imageUrl: profileData.profile_image_url
      });
      if (saved) {
        profileData.profile_image_saved = true;
        profileData.profile_image_path = saved.path;
        if (saved.publicUrl) profileData.profile_image_public_url = saved.publicUrl;
      } else {
        profileData.profile_image_saved = false;
      }
    } catch (e) {
      console.warn('[Facebook] Failed to save profile image:', e.message);
      profileData.profile_image_saved = false;
    }
    
    console.log(`✅ [Facebook] Scraped: ${profileData.full_name || profileData.username}`);
    console.log(`   Followers: ${profileData.followers}`);
    
    return profileData;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Facebook: ${error.message}`);
  }
}

module.exports = scrapeFacebook;
