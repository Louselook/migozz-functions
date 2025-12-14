const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para canales de YouTube
 * @param {string} channelInput - Username, ID o URL del canal
 * @returns {Promise<Object>} Datos del canal
 */
async function scrapeYouTube(channelInput) {
  console.log(`📥 [YouTube] Iniciando scraping para: ${channelInput}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Determinar la URL correcta
    let url;
    if (channelInput.startsWith('http')) {
      url = channelInput;
    } else if (channelInput.startsWith('UC') && channelInput.length === 24) {
      // Es un channel ID
      url = `https://www.youtube.com/channel/${channelInput}`;
    } else if (channelInput.startsWith('@')) {
      url = `https://www.youtube.com/${channelInput}`;
    } else {
      // Intentar como handle
      url = `https://www.youtube.com/@${channelInput}`;
    }
    
    console.log(`🌐 [YouTube] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [YouTube] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Extraer datos del canal
    const profileData = await page.evaluate(() => {
      let channelName = '';
      let subscribers = 0;
      let profileImageUrl = '';
      let channelId = '';
      let handle = '';
      let description = '';
      let totalVideos = 0;
      
      // Método 1: Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogUrl = document.querySelector('meta[property="og:url"]');
      const metaDescription = document.querySelector('meta[name="description"]');
      
      if (ogTitle) channelName = ogTitle.content;
      if (ogImage) profileImageUrl = ogImage.content;
      if (metaDescription) description = metaDescription.content;
      
      // Extraer channel ID de la URL
      if (ogUrl) {
        const urlMatch = ogUrl.content.match(/channel\/(UC[a-zA-Z0-9_-]{22})/);
        if (urlMatch) channelId = urlMatch[1];
      }
      
      // Método 2: Buscar en el DOM
      const subscriberEl = document.querySelector('#subscriber-count');
      if (subscriberEl) {
        const text = subscriberEl.textContent;
        const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
        if (match) {
          let num = parseFloat(match[1].replace(',', '.'));
          const suffix = match[2]?.toUpperCase();
          if (suffix === 'K') num *= 1000;
          else if (suffix === 'M') num *= 1000000;
          else if (suffix === 'B') num *= 1000000000;
          subscribers = Math.round(num);
        }
      }
      
      // Buscar handle
      const handleEl = document.querySelector('#channel-handle');
      if (handleEl) {
        handle = handleEl.textContent.trim().replace('@', '');
      }
      
      // Método 3: Buscar en scripts de datos
      const scripts = Array.from(document.querySelectorAll('script'));
      for (const script of scripts) {
        const text = script.textContent;
        
        // Buscar ytInitialData
        if (text.includes('ytInitialData')) {
          try {
            const match = text.match(/var ytInitialData = ({.+?});/s);
            if (match) {
              const data = JSON.parse(match[1]);
              
              // Buscar en header
              const header = data?.header?.c4TabbedHeaderRenderer;
              if (header) {
                if (header.title) channelName = header.title;
                if (header.channelId) channelId = header.channelId;
                if (header.channelHandleText?.runs?.[0]?.text) {
                  handle = header.channelHandleText.runs[0].text.replace('@', '');
                }
                if (header.avatar?.thumbnails) {
                  const avatars = header.avatar.thumbnails;
                  profileImageUrl = avatars[avatars.length - 1]?.url || profileImageUrl;
                }
                if (header.subscriberCountText?.simpleText) {
                  const subText = header.subscriberCountText.simpleText;
                  const subMatch = subText.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
                  if (subMatch) {
                    let num = parseFloat(subMatch[1].replace(',', '.'));
                    const suffix = subMatch[2]?.toUpperCase();
                    if (suffix === 'K') num *= 1000;
                    else if (suffix === 'M') num *= 1000000;
                    else if (suffix === 'B') num *= 1000000000;
                    if (num > subscribers) subscribers = Math.round(num);
                  }
                }
                if (header.videosCountText?.runs?.[0]?.text) {
                  const videoMatch = header.videosCountText.runs[0].text.match(/(\d+(?:[.,]\d+)?)/);
                  if (videoMatch) totalVideos = parseInt(videoMatch[1].replace(/[.,]/g, ''));
                }
              }
              
              // Buscar metadata
              const metadata = data?.metadata?.channelMetadataRenderer;
              if (metadata) {
                if (!channelName && metadata.title) channelName = metadata.title;
                if (!channelId && metadata.externalId) channelId = metadata.externalId;
                if (!description && metadata.description) description = metadata.description;
                if (!profileImageUrl && metadata.avatar?.thumbnails?.[0]?.url) {
                  profileImageUrl = metadata.avatar.thumbnails[0].url;
                }
              }
            }
          } catch (e) {}
        }
      }
      
      // Buscar subscribers en texto si aún no tenemos
      if (!subscribers) {
        const bodyText = document.body.innerText;
        const patterns = [
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:subscribers|suscriptores)/gi,
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:abonados)/gi,
        ];
        
        for (const pattern of patterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            let num = parseFloat(match[1].replace(',', '.'));
            const suffix = match[2]?.toUpperCase();
            if (suffix === 'K') num *= 1000;
            else if (suffix === 'M') num *= 1000000;
            else if (suffix === 'B') num *= 1000000000;
            if (num > subscribers) subscribers = Math.round(num);
          }
        }
      }
      
      return {
        channelId,
        channelName,
        handle,
        subscribers,
        totalVideos,
        description,
        profileImageUrl
      };
    });

    await browser.close();

    if (!profileData || (!profileData.channelName && !profileData.handle)) {
      throw new Error('No se pudieron extraer los datos del canal de YouTube');
    }

    const result = {
      id: profileData.channelId || channelInput,
      username: profileData.handle || profileData.channelName,
      full_name: profileData.channelName,
      bio: profileData.description || '',
      followers: profileData.subscribers,
      videos: profileData.totalVideos,
      profile_image_url: profileData.profileImageUrl,
      url: `https://www.youtube.com/@${profileData.handle || channelInput}`,
      platform: 'youtube'
    };
    
    console.log(`✅ [YouTube] Scraped: ${result.full_name}`);
    console.log(`   Subscribers: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping YouTube: ${error.message}`);
  }
}

module.exports = scrapeYouTube;
