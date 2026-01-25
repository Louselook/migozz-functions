const { createBrowser, sanitizeProfile, wait } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de LinkedIn (públicos)
 * LinkedIn es muy restrictivo - solo funciona con perfiles públicos
 * @param {string} profileInput - Username o URL del perfil
 * @returns {Promise<Object>} Datos del perfil
 */
async function scrapeLinkedIn(profileInput) {
  console.log(`📥 [LinkedIn] Iniciando scraping para: ${profileInput}`);

  let browser;

  try {
    browser = await createBrowser();
    const page = await browser.newPage();

    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Determinar URL
    let url;
    if (profileInput.includes('linkedin.com')) {
      url = profileInput;
    } else {
      url = `https://www.linkedin.com/in/${profileInput}/`;
    }

    console.log(`🌐 [LinkedIn] Navegando a: ${url}`);

    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: 60000
    });

    // Optimized wait
    console.log('⏳ [LinkedIn] Waiting for initial load...');
    try {
      await Promise.race([
        page.waitForSelector('.text-heading-xlarge, h1.top-card-layout__title', { timeout: 8000 }),
        page.waitForSelector('.top-card-layout__entity-image', { timeout: 8000 }),
        page.waitForNetworkIdle({ idleTime: 500, timeout: 8000 })
      ]);
      await wait(2000); // Small buffer
    } catch (e) {
      console.log('⚠️ [LinkedIn] Timeout waiting for elements, proceeding...');
    }

    const profileData = await page.evaluate(() => {
      let fullName = '';
      let headline = '';
      let location = '';
      let followers = 0;
      let connections = 0;
      let profileImageUrl = '';
      let companyName = '';

      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');

      if (ogTitle) fullName = ogTitle.content.split(' - ')[0].split(' | ')[0].trim();
      if (ogImage) profileImageUrl = ogImage.content;
      if (ogDescription) headline = ogDescription.content;

      function parseNumber(text) {
        const match = text.match(/(\d+(?:[.,]\d+)?)\s*([KMB])?/i);
        if (!match) return 0;
        let num = parseFloat(match[1].replace(/,/g, ''));
        const suffix = match[2]?.toUpperCase();
        if (suffix === 'K') num *= 1000;
        else if (suffix === 'M') num *= 1000000;
        else if (suffix === 'B') num *= 1000000000;
        return Math.round(num);
      }

      // Buscar en el texto
      const bodyText = document.body.innerText;

      // Buscar followers
      const followersPatterns = [
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:followers|seguidores)/gi,
      ];

      for (const pattern of followersPatterns) {
        const matches = bodyText.matchAll(pattern);
        for (const match of matches) {
          const count = parseNumber(match[0]);
          if (count > followers) followers = count;
        }
      }

      // Buscar connections
      const connectionsMatch = bodyText.match(/(\d+)\+?\s*(?:connections|conexiones)/i);
      if (connectionsMatch) {
        connections = parseInt(connectionsMatch[1]);
      }

      // Buscar en elementos del DOM
      const nameEl = document.querySelector('.text-heading-xlarge, h1.top-card-layout__title');
      if (nameEl) fullName = nameEl.textContent.trim();

      const headlineEl = document.querySelector('.text-body-medium, .top-card-layout__headline');
      if (headlineEl) headline = headlineEl.textContent.trim();

      const locationEl = document.querySelector('.text-body-small.inline, .top-card-layout__location');
      if (locationEl) location = locationEl.textContent.trim();

      // Imagen de perfil
      const avatarEl = document.querySelector('.pv-top-card-profile-picture__image, .top-card-layout__entity-image');
      if (avatarEl) profileImageUrl = avatarEl.src;

      // Buscar en JSON-LD
      const scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (const script of scripts) {
        try {
          const data = JSON.parse(script.textContent);
          if (data['@type'] === 'Person') {
            if (data.name) fullName = data.name;
            if (data.image?.contentUrl) profileImageUrl = data.image.contentUrl;
            if (data.worksFor?.[0]?.name) companyName = data.worksFor[0].name;
            if (data.address?.addressLocality) location = data.address.addressLocality;
          }
        } catch (e) { }
      }

      return {
        fullName,
        headline,
        location,
        followers,
        connections,
        profileImageUrl,
        companyName
      };
    });

    await browser.close();

    if (!profileData || !profileData.fullName) {
      throw new Error('No se pudieron extraer los datos del perfil de LinkedIn. Puede que el perfil sea privado.');
    }

    const result = {
      id: profileInput,
      username: profileInput,
      full_name: profileData.fullName,
      bio: profileData.headline || '',
      location: profileData.location || '',
      company: profileData.companyName || '',
      followers: profileData.followers,
      connections: profileData.connections,
      profile_image_url: profileData.profileImageUrl,
      url: `https://www.linkedin.com/in/${profileInput}/`,
      platform: 'linkedin'
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'linkedin',
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
      console.warn('[LinkedIn] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }

    console.log(`✅ [LinkedIn] Scraped: ${result.full_name}`);
    console.log(`   Followers: ${result.followers}`);
    console.log(`   Connections: ${result.connections}`);

    const sanitizedResult = sanitizeProfile(result, 'linkedin');

    console.log(`✅ [LinkedIn] Scraped: ${sanitizedResult.full_name}`);
    console.log(`   Followers: ${sanitizedResult.followers}`);
    console.log(`   Connections: ${sanitizedResult.connections}`); // This will be undefined in sanitized result

    return sanitizedResult;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) { }
    }
    throw new Error(`Error scraping LinkedIn: ${error.message}`);
  }
}

module.exports = scrapeLinkedIn;
