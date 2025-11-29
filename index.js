const express = require('express');
const puppeteerExtra = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const cors = require('cors');

puppeteerExtra.use(StealthPlugin());

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'Migozz Scraper Service',
    version: '2.2.0',
    platforms: ['tiktok', 'instagram', 'linkedin', 'facebook']
  });
});

// ==================== HELPER FUNCTIONS ====================

function extractUsername(input, platform) {
  if (!input) return '';
  input = input.trim();
  
  if (input.startsWith('http://') || input.startsWith('https://')) {
    const url = new URL(input);
    const pathname = url.pathname;
    
    switch (platform) {
      case 'tiktok':
        return pathname.replace('/@', '').split('/')[0];
      case 'instagram':
        return pathname.replace('/', '').split('/')[0];
      case 'linkedin':
        return pathname.replace('/in/', '').replace('/', '').split('/')[0];
      case 'facebook':
        return pathname.replace('/', '').split('/')[0];
      default:
        return pathname.replace('/', '').split('/')[0];
    }
  }
  
  return input.replace('@', '');
}

async function createBrowser() {
  return await puppeteerExtra.launch({
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--window-size=1920,1080',
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process',
      '--disable-blink-features=AutomationControlled'
    ]
  });
}

// ==================== RUTAS ====================

app.get('/tiktok/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'tiktok');
    console.log(`📥 [TikTok] Scraping: ${username}`);
    const result = await scrapeTikTok(username);
    res.json(result);
  } catch (error) {
    console.error(`❌ [TikTok] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/instagram/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'instagram');
    console.log(`📥 [Instagram] Scraping: ${username}`);
    const result = await scrapeInstagram(username);
    res.json(result);
  } catch (error) {
    console.error(`❌ [Instagram] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/linkedin/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'linkedin');
    console.log(`📥 [LinkedIn] Scraping: ${username}`);
    const result = await scrapeLinkedIn(username);
    res.json(result);
  } catch (error) {
    console.error(`❌ [LinkedIn] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/facebook/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'facebook');
    console.log(`📥 [Facebook] Scraping: ${username}`);
    const result = await scrapeFacebook(username);
    res.json(result);
  } catch (error) {
    console.error(`❌ [Facebook] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

// ==================== SCRAPERS ====================

// TikTok - MEJORADO
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
    
    // Cambio importante: domcontentloaded en vez de networkidle0
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

// Instagram - MEJORADO
async function scrapeInstagram(username) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const url = `https://www.instagram.com/${username}/`;
    console.log(`🌐 [Instagram] Navegando a: ${url}`);
    
    // Cambio importante: domcontentloaded
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [Instagram] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 8000));

    let profileData = null;

    try {
      profileData = await page.evaluate(() => {
        const scripts = Array.from(document.querySelectorAll('script'));
        
        // Método 1: window._sharedData
        for (const script of scripts) {
          const text = script.textContent;
          
          if (text.includes('window._sharedData')) {
            try {
              const match = text.match(/window\._sharedData = ({.*?});/);
              if (match) {
                const data = JSON.parse(match[1]);
                const user = data.entry_data?.ProfilePage?.[0]?.graphql?.user;
                
                if (user) {
                  return {
                    id: user.id,
                    username: user.username,
                    full_name: user.full_name,
                    followers: user.edge_followed_by?.count || 0,
                    following: user.edge_follow?.count || 0,
                    mediaCount: user.edge_owner_to_timeline_media?.count || 0,
                    bio: user.biography,
                    profile_image_url: user.profile_pic_url_hd || user.profile_pic_url,
                    verified: user.is_verified,
                  };
                }
              }
            } catch (e) {
              console.error('Error parsing Instagram _sharedData:', e);
            }
          }
        }
        
        // Método 2: Meta tags
        const metaDescription = document.querySelector('meta[name="description"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        
        let followers = 0;
        let following = 0;
        let posts = 0;
        
        if (metaDescription) {
          const desc = metaDescription.content;
          
          const followersMatch = desc.match(/(\d+(?:,\d+)*(?:\.\d+)?[KMB]?)\s+Followers/i);
          if (followersMatch) {
            const value = followersMatch[1].replace(/,/g, '');
            if (value.includes('K')) followers = Math.round(parseFloat(value) * 1000);
            else if (value.includes('M')) followers = Math.round(parseFloat(value) * 1000000);
            else if (value.includes('B')) followers = Math.round(parseFloat(value) * 1000000000);
            else followers = parseInt(value);
          }
          
          const followingMatch = desc.match(/(\d+(?:,\d+)*(?:\.\d+)?[KMB]?)\s+Following/i);
          if (followingMatch) {
            const value = followingMatch[1].replace(/,/g, '');
            if (value.includes('K')) following = Math.round(parseFloat(value) * 1000);
            else if (value.includes('M')) following = Math.round(parseFloat(value) * 1000000);
            else following = parseInt(value);
          }
          
          const postsMatch = desc.match(/(\d+(?:,\d+)*)\s+Posts/i);
          if (postsMatch) {
            posts = parseInt(postsMatch[1].replace(/,/g, ''));
          }
        }
        
        const username = window.location.pathname.replace(/\//g, '');
        
        return {
          id: username,
          username: username,
          full_name: ogTitle ? ogTitle.content.split('(')[0].trim() : '',
          followers: followers,
          following: following,
          mediaCount: posts,
          bio: metaDescription ? metaDescription.content : '',
          profile_image_url: ogImage ? ogImage.content : '',
          verified: false,
        };
      });
    } catch (evalError) {
      console.error('❌ [Instagram] Error en evaluate:', evalError.message);
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Instagram');
    }

    profileData.url = `https://www.instagram.com/${profileData.username}/`;
    console.log(`✅ [Instagram] Scraped: ${profileData.full_name} (@${profileData.username})`);
    console.log(`   Followers: ${profileData.followers}, Following: ${profileData.following}`);
    
    return profileData;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Instagram: ${error.message}`);
  }
}

// LinkedIn - MEJORADO
async function scrapeLinkedIn(username) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    const url = `https://www.linkedin.com/in/${username}/`;
    console.log(`🌐 [LinkedIn] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    console.log('⏳ [LinkedIn] Esperando contenido...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    let profileData = null;

    try {
      profileData = await page.evaluate(() => {
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogDescription = document.querySelector('meta[property="og:description"]');
        
        const name = document.querySelector('h1.text-heading-xlarge')?.textContent?.trim() || 
                     document.querySelector('.top-card-layout__title')?.textContent?.trim() ||
                     (ogTitle ? ogTitle.content : '');
        
        const headline = document.querySelector('.text-body-medium')?.textContent?.trim() ||
                        document.querySelector('.top-card-layout__headline')?.textContent?.trim() ||
                        (ogDescription ? ogDescription.content : '');
        
        const location = document.querySelector('.text-body-small.inline.t-black--light.break-words')?.textContent?.trim() ||
                        document.querySelector('.top-card__subline-item')?.textContent?.trim() || '';
        
        const avatarImg = document.querySelector('.pv-top-card-profile-picture__image') ||
                         document.querySelector('img.profile-photo-edit__preview');
        const avatarUrl = avatarImg?.src || (ogImage ? ogImage.content : '');
        
        const username = window.location.pathname.replace('/in/', '').replace(/\//g, '');
        
        return {
          id: username,
          url: `https://www.linkedin.com/in/${username}/`,
          username: username,
          full_name: name,
          headline: headline,
          profile_image_url: avatarUrl,
          connections: 0,
          followers: 0,
          location: location,
          about: headline,
          current_company: '',
          current_position: headline,
        };
      });
    } catch (evalError) {
      console.error('❌ [LinkedIn] Error en evaluate:', evalError.message);
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de LinkedIn');
    }

    console.log(`✅ [LinkedIn] Scraped: ${profileData.full_name}`);
    return profileData;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping LinkedIn: ${error.message}`);
  }
}

// Facebook - MEJORADO
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

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Migozz Scraper Service v2.2 corriendo en puerto ${PORT}`);
  console.log(`📡 Rutas disponibles:`);
  console.log(`   GET /tiktok/profile?username_or_link=xxx`);
  console.log(`   GET /instagram/profile?username_or_link=xxx`);
  console.log(`   GET /linkedin/profile?username_or_link=xxx`);
  console.log(`   GET /facebook/profile?username_or_link=xxx`);
  console.log(``);
  console.log(`✅ Campos compatibles con social_normalizer.dart`);
});