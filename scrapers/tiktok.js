const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para perfiles de TikTok
 * @param {string} username - Username de TikTok (sin @)
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeTikTok(username) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const url = `https://www.tiktok.com/@${username}`;
    console.log(`🌐 [TikTok] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [TikTok] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 8000));

    let profileData = null;
    
    try {
      profileData = await page.evaluate(() => {
        const scripts = Array.from(document.querySelectorAll('script'));
        for (const script of scripts) {
          if (script.id === '__UNIVERSAL_DATA_FOR_REHYDRATION__') {
            try {
              const data = JSON.parse(script.textContent);
              const userDetail = data.__DEFAULT_SCOPE__?.['webapp.user-detail'];
              if (userDetail?.userInfo) {
                const user = userDetail.userInfo.user;
                const stats = userDetail.userInfo.stats;
                return {
                  id: user.id,
                  username: user.uniqueId,
                  full_name: user.nickname,
                  followers: stats.followerCount,
                  following: stats.followingCount,
                  likes: stats.heartCount,
                  videos: stats.videoCount,
                  bio: user.signature,
                  profile_image_url: user.avatarLarger || user.avatarMedium || user.avatarThumb,
                  verified: user.verified,
                };
              }
            } catch (e) {
              console.error('Error parsing TikTok data:', e);
            }
          }
        }
        return null;
      });
    } catch (evalError) {
      console.error('❌ [TikTok] Error en evaluate:', evalError.message);
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de TikTok');
    }

    profileData.url = `https://www.tiktok.com/@${profileData.username}`;
    console.log(`✅ [TikTok] Scraped: ${profileData.full_name} (@${profileData.username})`);
    
    return profileData;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping TikTok: ${error.message}`);
  }
}

module.exports = scrapeTikTok;