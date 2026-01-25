const { createBrowser, sanitizeProfile, wait } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de Instagram
 * Instagram es muy restrictivo - esto funciona mejor con perfiles públicos
 * @param {string} username - Username de Instagram (sin @)
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeInstagram(username) {
  username = username.replace('@', '').trim();
  console.log(`📥 [Instagram] Iniciando scraping para: ${username}`);

  let browser;

  try {
    browser = await createBrowser();
    const page = await browser.newPage();

    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Configurar headers
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    });

    // Interceptar respuestas de la API
    let apiData = null;
    await page.setRequestInterception(true);

    page.on('request', request => request.continue());

    page.on('response', async response => {
      const url = response.url();
      if (url.includes('/api/v1/users/web_profile_info') ||
        url.includes('graphql/query') ||
        url.includes('/api/v1/users/')) {
        try {
          const json = await response.json();
          if (json?.data?.user || json?.user) {
            apiData = json.data?.user || json.user;
          }
        } catch (e) { }
      }
    });

    const url = `https://www.instagram.com/${username}/`;
    console.log(`🌐 [Instagram] Navegando a: ${url}`);

    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: 60000
    });

    console.log('⏳ [Instagram] Esperando contenido...');
    // Optimized wait: Wait for specific elements or network idle instead of fixed 8s
    console.log('⏳ [Instagram] Waiting for initial load...');
    try {
      // Wait for either the profile picture or a meta tag to appear
      await Promise.race([
        page.waitForSelector('img[alt*="profile"]', { timeout: 8000 }),
        page.waitForSelector('meta[property="og:description"]', { timeout: 8000 }),
        page.waitForNetworkIdle({ idleTime: 500, timeout: 8000 })
      ]);
      // Small buffer to ensure dynamic JS renders stats
      await wait(2000);
    } catch (e) {
      console.log('⚠️ [Instagram] Timeout waiting for specific elements, proceeding with what we have...');
    }

    // Intentar cerrar popups de login
    try {
      const closeButtons = await page.$$('[aria-label="Close"]');
      for (const btn of closeButtons) {
        await btn.click().catch(() => { });
      }
    } catch (e) { }

    let profileData = null;

    // Si tenemos datos de la API, usarlos
    if (apiData) {
      profileData = {
        id: apiData.id || apiData.pk,
        username: apiData.username,
        full_name: apiData.full_name,
        bio: apiData.biography || apiData.bio,
        followers: apiData.edge_followed_by?.count || apiData.follower_count || 0,
        following: apiData.edge_follow?.count || apiData.following_count || 0,
        posts: apiData.edge_owner_to_timeline_media?.count || apiData.media_count || 0,
        profile_image_url: apiData.profile_pic_url_hd || apiData.profile_pic_url || '',
        verified: apiData.is_verified || false,
        is_private: apiData.is_private || false,
      };
    }

    // Si no tenemos datos, extraer del DOM/scripts
    if (!profileData) {
      profileData = await page.evaluate(() => {
        // Método 1: Meta tags
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogDescription = document.querySelector('meta[property="og:description"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');

        let followers = 0;
        let following = 0;
        let posts = 0;
        let fullName = '';
        let bio = '';
        let profileImageUrl = ogImage ? ogImage.content : '';

        // Extraer datos del og:description
        // Formato típico: "X Followers, X Following, X Posts - See Instagram photos..."
        if (ogDescription) {
          const desc = ogDescription.content;

          const followersMatch = desc.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?\s*Followers/i);
          const followingMatch = desc.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?\s*Following/i);
          const postsMatch = desc.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?\s*Posts/i);

          function parseNum(match) {
            if (!match) return 0;
            let num = parseFloat(match[1].replace(/,/g, ''));
            const suffix = match[2]?.toUpperCase();
            if (suffix === 'K') num *= 1000;
            else if (suffix === 'M') num *= 1000000;
            else if (suffix === 'B') num *= 1000000000;
            return Math.round(num);
          }

          followers = parseNum(followersMatch);
          following = parseNum(followingMatch);
          posts = parseNum(postsMatch);
        }

        // Extraer nombre del título
        if (ogTitle) {
          const titleMatch = ogTitle.content.match(/^([^(]+)\s*\(@/);
          if (titleMatch) fullName = titleMatch[1].trim();
        }

        // Método 2: Buscar en scripts JSON
        const scripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
        for (const script of scripts) {
          try {
            const data = JSON.parse(script.textContent);
            if (data['@type'] === 'Person' || data['@type'] === 'ProfilePage') {
              if (data.name) fullName = data.name;
              if (data.description) bio = data.description;
              if (data.image) profileImageUrl = data.image;
              if (data.mainEntity?.interactionStatistic) {
                for (const stat of data.mainEntity.interactionStatistic) {
                  if (stat.interactionType?.includes('Follow')) {
                    followers = parseInt(stat.userInteractionCount) || followers;
                  }
                }
              }
            }
          } catch (e) { }
        }

        // Método 3: Buscar en scripts regulares
        const allScripts = Array.from(document.querySelectorAll('script'));
        for (const script of allScripts) {
          const text = script.textContent;

          if (text.includes('"edge_followed_by"') || text.includes('"follower_count"')) {
            try {
              // Buscar followers
              const followerMatch = text.match(/"(?:edge_followed_by|follower_count)"[:\s]*\{?"count"?[:\s]*(\d+)/);
              if (followerMatch) {
                const count = parseInt(followerMatch[1]);
                if (count > followers) followers = count;
              }

              // Buscar following
              const followingMatch = text.match(/"(?:edge_follow|following_count)"[:\s]*\{?"count"?[:\s]*(\d+)/);
              if (followingMatch) {
                following = parseInt(followingMatch[1]) || following;
              }

              // Buscar posts
              const postsMatch = text.match(/"(?:edge_owner_to_timeline_media|media_count)"[:\s]*\{?"count"?[:\s]*(\d+)/);
              if (postsMatch) {
                posts = parseInt(postsMatch[1]) || posts;
              }

              // Buscar nombre
              const nameMatch = text.match(/"full_name"[:\s]*"([^"]+)"/);
              if (nameMatch && !fullName) fullName = nameMatch[1];

              // Buscar bio
              const bioMatch = text.match(/"biography"[:\s]*"([^"]+)"/);
              if (bioMatch && !bio) bio = bioMatch[1];

              // Buscar imagen
              const imgMatch = text.match(/"profile_pic_url(?:_hd)?"[:\s]*"([^"]+)"/);
              if (imgMatch && !profileImageUrl) {
                profileImageUrl = imgMatch[1].replace(/\\u0026/g, '&');
              }
            } catch (e) { }
          }
        }

        // Método 4: Buscar en elementos del DOM
        const statsElements = document.querySelectorAll('ul li');
        for (const li of statsElements) {
          const text = li.textContent || '';
          if (text.includes('followers') || text.includes('seguidores')) {
            const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
            if (match) {
              let num = parseFloat(match[1].replace(/,/g, ''));
              const suffix = match[2]?.toUpperCase();
              if (suffix === 'K') num *= 1000;
              else if (suffix === 'M') num *= 1000000;
              if (num > followers) followers = Math.round(num);
            }
          }
        }

        return {
          followers,
          following,
          posts,
          full_name: fullName,
          bio,
          profile_image_url: profileImageUrl
        };
      });
    }

    await browser.close();

    if (!profileData) {
      throw new Error('No se pudieron extraer los datos del perfil de Instagram');
    }

    const result = {
      id: profileData.id || username,
      username: profileData.username || username,
      full_name: profileData.full_name || '',
      bio: profileData.bio || '',
      followers: profileData.followers || 0,
      following: profileData.following || 0,
      posts: profileData.posts || 0,
      profile_image_url: profileData.profile_image_url || '',
      verified: profileData.verified || false,
      is_private: profileData.is_private || false,
      url: `https://www.instagram.com/${username}/`,
      platform: 'instagram'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'instagram',
        username,
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
      console.warn('[Instagram] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }

    const sanitizedResult = sanitizeProfile(result, 'instagram');

    console.log(`✅ [Instagram] Scraped: ${sanitizedResult.full_name || username}`);
    console.log(`   Followers: ${sanitizedResult.followers}`);

    return sanitizedResult;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) { }
    }
    throw new Error(`Error scraping Instagram: ${error.message}`);
  }
}

module.exports = scrapeInstagram;
