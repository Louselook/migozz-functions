const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de Facebook
 * @param {string} username - Username o ID de Facebook
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeFacebook(username) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    });

    const url = `https://www.facebook.com/${username}`;
    console.log(`🌐 [Facebook] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [Facebook] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    let profileData = null;

    try {
      profileData = await page.evaluate(() => {
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        
        const nameH1 = document.querySelector('h1');
        const nameSpan = document.querySelector('span[dir="auto"]');
        const name = nameH1?.textContent?.trim() || nameSpan?.textContent?.trim() || (ogTitle ? ogTitle.content : '');
        
        let followers = 0;
        const bodyText = document.body.textContent;
        
        const patterns = [
          /(\d+(?:,\d+)*(?:\.\d+)?[KMB]?)\s+followers/i,
          /(\d+(?:,\d+)*(?:\.\d+)?[KMB]?)\s+people follow this/i,
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
        
        const username = window.location.pathname.replace('/', '').split('/')[0];
        
        return {
          id: username,
          username: name,
          email: '',
          profile_image_url: ogImage ? ogImage.content : '',
          url: `https://www.facebook.com/${username}`,
          followers: followers,
        };
      });
    } catch (evalError) {
      console.error('❌ [Facebook] Error en evaluate:', evalError.message);
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Facebook');
    }

    console.log(`✅ [Facebook] Scraped: ${profileData.username}`);
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