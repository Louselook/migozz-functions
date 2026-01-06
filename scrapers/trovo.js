const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de Trovo - CORREGIDO
 * Timeout reducido y mejor manejo de errores
 * @param {string} username - Username de Trovo
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeTrovo(username) {
  const cleanUsername = username.startsWith('s/') ? username.replace('s/', '') : username;
  
  console.log(`📥 [Trovo] Iniciando scraping para: ${cleanUsername}`);
  
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
    
    page.on('request', request => {
      // Bloquear recursos innecesarios para acelerar la carga
      const resourceType = request.resourceType();
      if (['image', 'stylesheet', 'font', 'media'].includes(resourceType)) {
        request.abort();
      } else {
        request.continue();
      }
    });
    
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('gql.trovo.live') || url.includes('api.trovo.live')) {
        try {
          const text = await response.text();
          const json = JSON.parse(text);
          
          const responses = Array.isArray(json) ? json : [json];
          
          for (const resp of responses) {
            if (resp?.data?.getLiveInfo?.channelInfo) {
              const ch = resp.data.getLiveInfo.channelInfo;
              apiData = apiData || {};
              if (ch.followerNum !== undefined) apiData.followers = ch.followerNum;
              if (ch.nickName) apiData.nickName = ch.nickName;
              if (ch.userName) apiData.userName = ch.userName;
              if (ch.profilePic) apiData.profilePic = ch.profilePic;
              if (ch.uid) apiData.uid = ch.uid;
              if (ch.info) apiData.info = ch.info;
              console.log(`🔍 [Trovo] API interceptada: followers=${ch.followerNum}`);
            }
            
            if (resp?.data?.getChannelInfo) {
              apiData = apiData || {};
              Object.assign(apiData, resp.data.getChannelInfo);
            }
          }
        } catch (e) {}
      }
    });

    const url = `https://trovo.live/s/${cleanUsername}`;
    console.log(`🌐 [Trovo] Navegando a: ${url}`);
    
    // Timeout de 45 segundos para dar más tiempo
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 45000 
    });
    
    // Esperar a que cargue el contenido dinámico
    console.log('⏳ [Trovo] Esperando carga de contenido...');
    
    // Intentar esperar un selector específico de Trovo
    try {
      await page.waitForSelector('[class*="channel-info"], [class*="follower"], [class*="user-info"]', { timeout: 10000 });
    } catch (e) {
      // Si no encuentra el selector, continuar de todos modos
    }
    
    // Scroll para activar lazy loading
    await page.evaluate(() => window.scrollBy(0, 300));
    await new Promise(resolve => setTimeout(resolve, 3000));
    await page.evaluate(() => window.scrollBy(0, -300));
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Si capturamos datos de la API
    if (apiData && apiData.followers !== undefined) {
      await browser.close();
      const result = {
        id: apiData.uid || cleanUsername,
        username: apiData.userName || cleanUsername,
        full_name: apiData.nickName || apiData.userName || cleanUsername,
        bio: apiData.info || '',
        followers: apiData.followers || 0,
        profile_image_url: apiData.profilePic || '',
        is_live: apiData.isLive || false,
        url: `https://trovo.live/s/${cleanUsername}`,
        platform: 'trovo'
      };
      console.log(`✅ [Trovo] Via intercepción: ${result.full_name}, followers: ${result.followers}`);
      return result;
    }

    // Extraer del DOM
    const profileData = await page.evaluate(() => {
      let fullName = '';
      let followers = 0;
      let profileImageUrl = '';
      
      function parseNumber(text) {
        if (!text) return 0;
        text = text.trim().toLowerCase();
        
        // Español: "170 mil"
        const milMatch = text.match(/(\d+(?:[.,]\d+)?)\s*mil\b/i);
        if (milMatch && !text.includes('millon')) {
          return Math.round(parseFloat(milMatch[1].replace(/,/g, '.')) * 1000);
        }
        
        // Millones
        const millonMatch = text.match(/(\d+(?:[.,]\d+)?)\s*mill?on/i);
        if (millonMatch) {
          return Math.round(parseFloat(millonMatch[1].replace(/,/g, '.')) * 1000000);
        }
        
        // K/M/B
        const kmMatch = text.match(/(\d+(?:[.,]\d+)?)\s*([kmb])\b/i);
        if (kmMatch) {
          let num = parseFloat(kmMatch[1].replace(/,/g, '.'));
          const suffix = kmMatch[2].toLowerCase();
          if (suffix === 'k') num *= 1000;
          else if (suffix === 'm') num *= 1000000;
          else if (suffix === 'b') num *= 1000000000;
          return Math.round(num);
        }
        
        // Solo número
        const numMatch = text.match(/(\d+)/);
        if (numMatch) return parseInt(numMatch[1]);
        
        return 0;
      }
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      
      if (ogTitle) fullName = ogTitle.content.replace(' - Trovo', '').replace(' | Trovo', '').trim();
      if (ogImage) profileImageUrl = ogImage.content;
      
      // MÉTODO 1: Buscar en scripts (más confiable)
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent || '';
        
        // followerNum en formato JSON
        const followerNumMatch = text.match(/"followerNum"\s*:\s*(\d+)/);
        if (followerNumMatch) {
          const count = parseInt(followerNumMatch[1]);
          if (count > followers) {
            followers = count;
            console.log('[Trovo Debug] Found followerNum in script:', count);
          }
        }
        
        // subscriber_num
        const subMatch = text.match(/"subscriber_num"\s*:\s*(\d+)/);
        if (subMatch) {
          const count = parseInt(subMatch[1]);
          if (count > followers) followers = count;
        }
        
        const nickMatch = text.match(/"nickName"\s*:\s*"([^"]+)"/);
        if (nickMatch && !fullName) fullName = nickMatch[1];
        
        if (!profileImageUrl) {
          const picMatch = text.match(/"profilePic"\s*:\s*"([^"]+)"/);
          if (picMatch) profileImageUrl = picMatch[1];
        }
      }
      
      // MÉTODO 2: Buscar elementos que contengan el número de seguidores
      // Trovo muestra los seguidores cerca de texto como "Followers" o "seguidores"
      const allText = document.body.innerText;
      
      // Buscar patrones específicos
      const patterns = [
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:Followers|followers|Seguidores|seguidores)/gi,
        /(\d+(?:[.,]\d+)?)\s*mil\s*(?:Followers|followers|Seguidores|seguidores)/gi,
        /(?:Followers|followers|Seguidores|seguidores)[:\s]*(\d+(?:[.,]\d+)?)\s*([KMB])?/gi,
      ];
      
      for (const pattern of patterns) {
        pattern.lastIndex = 0;
        let match;
        while ((match = pattern.exec(allText)) !== null) {
          const count = parseNumber(match[0]);
          if (count > followers) {
            followers = count;
            console.log('[Trovo Debug] Found in text:', match[0], '=', count);
          }
        }
      }
      
      // MÉTODO 3: Buscar en elementos específicos de la UI de Trovo
      // Trovo usa clases como "info-num", "channel-info-followers", etc
      const selectorPatterns = [
        '.channel-info-followers',
        '[class*="follower"]',
        '[class*="Follower"]',
        '.info-num',
        '[class*="subscriberCount"]',
        '[class*="stat"]',
        '[class*="count"]'
      ];
      
      for (const selector of selectorPatterns) {
        try {
          const elements = document.querySelectorAll(selector);
          for (const el of elements) {
            const text = el.textContent?.trim() || '';
            const parentText = el.parentElement?.textContent?.toLowerCase() || '';
            
            // Si el elemento o su padre contiene "follower" o "seguidor"
            if (parentText.includes('follower') || parentText.includes('seguidor') || 
                el.className.toLowerCase().includes('follower')) {
              const count = parseNumber(text);
              if (count > followers) {
                followers = count;
                console.log('[Trovo Debug] Found via selector:', selector, '=', count);
              }
            }
          }
        } catch (e) {}
      }
      
      // MÉTODO 4: Buscar el h1 o elemento de título para el nombre
      if (!fullName) {
        const h1 = document.querySelector('h1');
        if (h1) fullName = h1.textContent.trim();
      }
      
      return { followers, profile_image_url: profileImageUrl, full_name: fullName };
    });

    await browser.close();

    const result = {
      id: cleanUsername,
      username: cleanUsername,
      full_name: profileData.full_name || cleanUsername,
      bio: '',
      followers: profileData.followers || 0,
      profile_image_url: profileData.profile_image_url || '',
      url: `https://trovo.live/s/${cleanUsername}`,
      platform: 'trovo'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'trovo',
        username: result.username,
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
      console.warn('[Trovo] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }
    
    console.log(`✅ [Trovo] Via DOM: ${result.full_name}`);
    console.log(`   Followers: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Trovo: ${error.message}`);
  }
}

module.exports = scrapeTrovo;
