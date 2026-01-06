const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de Threads (Meta)
 * @param {string} username - Username de Threads (sin @)
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeThreads(username) {
  username = username.replace('@', '').trim();
  console.log(`📥 [Threads] Iniciando scraping para: ${username}`);
  
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Interceptar respuestas de la API
    let apiData = null;
    await page.setRequestInterception(true);
    
    page.on('request', request => request.continue());
    
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('/api/graphql') || url.includes('threads.net/api')) {
        try {
          const json = await response.json();
          if (json?.data?.user || json?.data?.userData) {
            apiData = json.data.user || json.data.userData;
          }
        } catch (e) {}
      }
    });

    const url = `https://www.threads.net/@${username}`;
    console.log(`🌐 [Threads] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [Threads] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 8000));

    let profileData = null;

    // Si tenemos datos de la API
    if (apiData) {
      profileData = {
        id: apiData.pk || apiData.id,
        username: apiData.username,
        full_name: apiData.full_name,
        bio: apiData.biography || apiData.bio_text,
        followers: apiData.follower_count || 0,
        following: apiData.following_count || 0,
        profile_image_url: apiData.profile_pic_url || apiData.hd_profile_pic_url_info?.url || '',
        verified: apiData.is_verified || false,
      };
    }

    // Extraer del DOM si no tenemos datos
    if (!profileData) {
      profileData = await page.evaluate(() => {
        // Meta tags
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogDescription = document.querySelector('meta[property="og:description"]');
        
        let followers = 0;
        let fullName = '';
        let bio = '';
        let profileImageUrl = ogImage ? ogImage.content : '';
        
        // Extraer nombre del título
        if (ogTitle) {
          const match = ogTitle.content.match(/^([^(]+)\s*\(@/);
          if (match) fullName = match[1].trim();
          else fullName = ogTitle.content.split('(')[0].trim();
        }
        
        // Extraer bio
        if (ogDescription) {
          bio = ogDescription.content;
        }
        
        function parseNumber(text) {
          const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
          if (!match) return 0;
          let num = parseFloat(match[1].replace(/,/g, '.'));
          const suffix = match[2]?.toUpperCase();
          if (suffix === 'K') num *= 1000;
          else if (suffix === 'M') num *= 1000000;
          else if (suffix === 'B') num *= 1000000000;
          return Math.round(num);
        }
        
        // Buscar followers en el texto
        const bodyText = document.body.innerText;
        const patterns = [
          /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:followers|seguidores)/gi,
        ];
        
        for (const pattern of patterns) {
          const matches = bodyText.matchAll(pattern);
          for (const match of matches) {
            const count = parseNumber(match[0]);
            if (count > followers) followers = count;
          }
        }
        
        // Buscar en scripts JSON
        const scripts = Array.from(document.querySelectorAll('script'));
        for (const script of scripts) {
          const text = script.textContent;
          
          if (text.includes('"follower_count"') || text.includes('"username"')) {
            try {
              const followersMatch = text.match(/"follower_count"[:\s]*(\d+)/);
              if (followersMatch) {
                const count = parseInt(followersMatch[1]);
                if (count > followers) followers = count;
              }
              
              const nameMatch = text.match(/"full_name"[:\s]*"([^"]+)"/);
              if (nameMatch && !fullName) fullName = nameMatch[1];
              
              const bioMatch = text.match(/"biography"[:\s]*"([^"]+)"/);
              if (bioMatch && !bio) bio = bioMatch[1];
              
              const imgMatch = text.match(/"profile_pic_url"[:\s]*"([^"]+)"/);
              if (imgMatch && !profileImageUrl) {
                profileImageUrl = imgMatch[1].replace(/\\u0026/g, '&');
              }
            } catch (e) {}
          }
        }
        
        return {
          followers,
          full_name: fullName,
          bio,
          profile_image_url: profileImageUrl
        };
      });
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Threads');
    }

    const result = {
      id: profileData.id || username,
      username: profileData.username || username,
      full_name: profileData.full_name || '',
      bio: profileData.bio || '',
      followers: profileData.followers || 0,
      following: profileData.following || 0,
      profile_image_url: profileData.profile_image_url || '',
      verified: profileData.verified || false,
      url: `https://www.threads.net/@${username}`,
      platform: 'threads'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'threads',
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
      console.warn('[Threads] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }
    
    console.log(`✅ [Threads] Scraped: ${result.full_name || username}`);
    console.log(`   Followers: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Threads: ${error.message}`);
  }
}

module.exports = scrapeThreads;
