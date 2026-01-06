const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles públicos de Snapchat - MEJORADO
 * Detecta seguidores en formato español (mil, millones) e inglés
 * @param {string} username - Username de Snapchat
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeSnapchat(username) {
  username = username.replace('@', '').trim();
  console.log(`📥 [Snapchat] Iniciando scraping para: ${username}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Interceptar API de Snapchat
    let apiData = null;
    await page.setRequestInterception(true);
    
    page.on('request', request => request.continue());
    
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('api.snapchat.com') || url.includes('/web/')) {
        try {
          const json = await response.json();
          if (json?.userProfile || json?.publicProfileInfo) {
            apiData = json.userProfile || json.publicProfileInfo;
            console.log(`🔍 [Snapchat] API interceptada`);
          }
        } catch (e) {}
      }
    });

    const url = `https://www.snapchat.com/add/${username}`;
    console.log(`🌐 [Snapchat] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2', 
      timeout: 60000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 6000));

    const profileData = await page.evaluate((usernameParam) => {
      let displayName = '';
      let bitmoji = '';
      let snapcode = '';
      let bio = '';
      let subscribers = 0;
      let verified = false;
      
      // Función mejorada para parsear números en español e inglés
      function parseNumber(text) {
        if (!text) return 0;
        text = text.trim().toLowerCase();
        
        // Limpiar el texto - quitar todo excepto números, puntos, comas y letras clave
        
        // Formato español: "170 mil seguidores", "1,5 millones"
        // El patrón debe coincidir con el número seguido de "mil" o "millones"
        
        // Buscar "X mil" o "X,Y mil"
        const milMatch = text.match(/(\d+(?:[.,]\d+)?)\s*mil\b/i);
        if (milMatch && !text.includes('millon')) {
          let num = parseFloat(milMatch[1].replace(/,/g, '.'));
          return Math.round(num * 1000);
        }
        
        // Buscar "X millones" o "X,Y millones"
        const millonMatch = text.match(/(\d+(?:[.,]\d+)?)\s*mill?on/i);
        if (millonMatch) {
          let num = parseFloat(millonMatch[1].replace(/,/g, '.'));
          return Math.round(num * 1000000);
        }
        
        // Patrón para inglés: número + K/M/B
        const englishMatch = text.match(/(\d+(?:[.,]\d+)?)\s*([kmb])\b/i);
        if (englishMatch) {
          let num = parseFloat(englishMatch[1].replace(/,/g, '.'));
          const suffix = englishMatch[2].toLowerCase();
          if (suffix === 'k') num *= 1000;
          else if (suffix === 'm') num *= 1000000;
          else if (suffix === 'b') num *= 1000000000;
          return Math.round(num);
        }
        
        // Solo número sin sufijo
        const numMatch = text.match(/(\d+(?:[.,]\d+)?)/);
        if (numMatch) {
          return Math.round(parseFloat(numMatch[1].replace(/,/g, '.')));
        }
        
        return 0;
      }
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');
      
      if (ogTitle) displayName = ogTitle.content.replace(' on Snapchat', '').replace(' en Snapchat', '').trim();
      if (ogImage) bitmoji = ogImage.content;
      if (ogDescription) bio = ogDescription.content;
      
      // MÉTODO 1: Buscar en el texto visible con patrones mejorados
      const bodyText = document.body.innerText;
      
      // Patrones para español e inglés
      const subscriberPatterns = [
        // Español
        /(\d+(?:[.,]\d+)?)\s*mil(?:lones)?\s*(?:seguidores|suscriptores)/gi,
        /(\d+(?:[.,]\d+)?)\s*(?:seguidores|suscriptores)/gi,
        // Inglés
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:subscribers|followers)/gi,
      ];
      
      for (const pattern of subscriberPatterns) {
        pattern.lastIndex = 0;
        let match;
        while ((match = pattern.exec(bodyText)) !== null) {
          const count = parseNumber(match[0]);
          if (count > subscribers) {
            subscribers = count;
            console.log('[Snapchat Debug] Found subscribers:', count, 'from:', match[0]);
          }
        }
      }
      
      // MÉTODO 2: Buscar elementos específicos que contengan números cerca de "seguidores"
      const allElements = document.querySelectorAll('*');
      for (const el of allElements) {
        const text = el.textContent?.trim() || '';
        
        // Buscar patrón "número + mil + seguidores"
        if (text.match(/\d+\s*mil\s*seguidores/i)) {
          const count = parseNumber(text);
          if (count > subscribers) subscribers = count;
        }
        
        // Buscar patrón "número seguidores" simple
        if (text.match(/^\d+(?:[.,]\d+)?\s*(?:mil(?:lones)?)?\s*seguidores$/i)) {
          const count = parseNumber(text);
          if (count > subscribers) subscribers = count;
        }
      }
      
      // MÉTODO 3: Buscar en scripts JSON
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent || '';
        
        // subscriberCount en JSON
        const subMatch = text.match(/"subscriberCount"\s*:\s*(\d+)/);
        if (subMatch) {
          const count = parseInt(subMatch[1]);
          if (count > subscribers) subscribers = count;
        }
        
        // followerCount
        const followerMatch = text.match(/"followerCount"\s*:\s*(\d+)/);
        if (followerMatch) {
          const count = parseInt(followerMatch[1]);
          if (count > subscribers) subscribers = count;
        }
        
        // displayName
        const nameMatch = text.match(/"displayName"\s*:\s*"([^"]+)"/);
        if (nameMatch && !displayName) displayName = nameMatch[1];
        
        // bitmojiUrl
        const bitmojiMatch = text.match(/"(?:bitmojiUrl|bitmojiAvatarUrl|avatarUrl)"\s*:\s*"([^"]+)"/);
        if (bitmojiMatch && !bitmoji) bitmoji = bitmojiMatch[1];
      }
      
      // Buscar nombre en selectores específicos
      const nameSelectors = [
        '.PublicProfileCard_displayName',
        '[class*="displayName"]',
        '[class*="DisplayName"]',
        'h1',
        '.profile-title',
        '[data-testid="display-name"]'
      ];
      
      for (const sel of nameSelectors) {
        const el = document.querySelector(sel);
        if (el && el.textContent.trim() && !el.textContent.includes('seguidores')) {
          const text = el.textContent.trim();
          if (text.length < 50) { // Evitar textos largos
            displayName = text;
            break;
          }
        }
      }
      
      // Buscar Bitmoji/Avatar
      const avatarSelectors = [
        'img[class*="Bitmoji"]',
        'img[class*="avatar"]',
        'img[class*="Avatar"]',
        '.PublicProfileCard_bitmojiContainer img',
        'img[alt*="Bitmoji"]',
        'img[src*="bitmoji"]',
        'img[src*="avatar"]'
      ];
      
      for (const sel of avatarSelectors) {
        const img = document.querySelector(sel);
        if (img && img.src && !img.src.includes('snapcode')) {
          bitmoji = img.src;
          break;
        }
      }
      
      // Verificación
      if (document.querySelector('[class*="verified"], [class*="Verified"], .badge-verified, [data-testid="verified-badge"]')) {
        verified = true;
      }
      
      // Buscar snapcode
      const snapcodeImg = document.querySelector('img[alt*="Snapcode"], img[src*="snapcode"]');
      if (snapcodeImg) snapcode = snapcodeImg.src;
      
      return {
        displayName: displayName || usernameParam,
        bitmoji,
        snapcode,
        bio,
        subscribers,
        verified
      };
    }, username);

    await browser.close();

    const result = {
      id: username,
      username: username,
      full_name: profileData.displayName || username,
      bio: profileData.bio || '',
      followers: profileData.subscribers || 0,
      profile_image_url: profileData.bitmoji || '',
      snapcode_url: profileData.snapcode || '',
      verified: profileData.verified || false,
      url: `https://www.snapchat.com/add/${username}`,
      platform: 'snapchat'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'snapchat',
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
      console.warn('[Snapchat] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }
    
    console.log(`✅ [Snapchat] Scraped: ${result.full_name}`);
    console.log(`   Followers: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Snapchat: ${error.message}`);
  }
}

module.exports = scrapeSnapchat;
