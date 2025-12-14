const { createBrowser } = require('../utils/helpers');

/**
 * Scraper para servidores de Discord (usando discord.me, top.gg, o invites)
 * Discord no tiene perfiles públicos de usuarios, solo servidores
 * @param {string} serverIdOrInvite - ID del servidor, código de invitación o URL
 * @returns {Promise<Object>} Datos del servidor
 */
async function scrapeDiscord(serverIdOrInvite) {
  console.log(`📥 [Discord] Iniciando scraping para: ${serverIdOrInvite}`);
  
  // Extraer código de invitación si es URL
  let inviteCode = serverIdOrInvite;
  if (serverIdOrInvite.includes('discord.gg/') || serverIdOrInvite.includes('discord.com/invite/')) {
    const match = serverIdOrInvite.match(/(?:discord\.gg\/|discord\.com\/invite\/)([a-zA-Z0-9-]+)/);
    if (match) inviteCode = match[1];
  }
  
  // Método 1: Intentar con la API de invitaciones de Discord
  try {
    const apiData = await fetchDiscordInviteAPI(inviteCode);
    if (apiData && apiData.full_name) {
      console.log(`✅ [Discord] Datos obtenidos via API de invitación`);
      return apiData;
    }
  } catch (apiError) {
    console.log(`⚠️ [Discord] API de invitación no disponible: ${apiError.message}`);
  }
  
  // Método 2: Fallback a Puppeteer (discord.me o top.gg)
  return await scrapeDiscordWithPuppeteer(inviteCode);
}

/**
 * Obtener datos usando la API pública de invitaciones de Discord
 */
async function fetchDiscordInviteAPI(inviteCode) {
  // Discord tiene una API pública para obtener info de invitaciones
  const apiUrl = `https://discord.com/api/v9/invites/${inviteCode}?with_counts=true&with_expiration=true`;
  
  const response = await fetch(apiUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json'
    }
  });
  
  if (!response.ok) {
    throw new Error(`Invite API responded with status ${response.status}`);
  }
  
  const data = await response.json();
  
  if (!data.guild) {
    throw new Error('Invalid invite or expired');
  }
  
  const guild = data.guild;
  
  // Construir URL del icono
  let iconUrl = '';
  if (guild.icon) {
    const ext = guild.icon.startsWith('a_') ? 'gif' : 'png';
    iconUrl = `https://cdn.discordapp.com/icons/${guild.id}/${guild.icon}.${ext}?size=512`;
  }
  
  // Construir URL del banner
  let bannerUrl = '';
  if (guild.banner) {
    bannerUrl = `https://cdn.discordapp.com/banners/${guild.id}/${guild.banner}.png?size=1024`;
  }
  
  return {
    id: guild.id,
    username: guild.vanity_url_code || inviteCode,
    full_name: guild.name,
    bio: guild.description || '',
    followers: data.approximate_member_count || 0,
    online_members: data.approximate_presence_count || 0,
    profile_image_url: iconUrl,
    banner_url: bannerUrl,
    verified: guild.verified || false,
    partnered: guild.partnered || false,
    premium_tier: guild.premium_subscription_count || 0,
    features: guild.features || [],
    url: `https://discord.gg/${guild.vanity_url_code || inviteCode}`,
    invite_code: inviteCode,
    platform: 'discord'
  };
}

/**
 * Scraping con Puppeteer como fallback (usando discord.me o top.gg)
 */
async function scrapeDiscordWithPuppeteer(serverIdOrInvite) {
  let browser;
  
  try {
    browser = await createBrowser();
    const page = await browser.newPage();
    
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    // Intentar top.gg primero
    let url = `https://top.gg/servers/${serverIdOrInvite}`;
    console.log(`🌐 [Discord] Navegando a: ${url}`);
    
    await page.goto(url, { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 4000));

    let profileData = await page.evaluate(() => {
      let serverName = '';
      let description = '';
      let members = 0;
      let iconUrl = '';
      let tags = [];
      
      // Meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');
      
      if (ogTitle) serverName = ogTitle.content.replace(' | Top.gg', '').trim();
      if (ogImage) iconUrl = ogImage.content;
      if (ogDescription) description = ogDescription.content;
      
      // Título
      const h1 = document.querySelector('h1');
      if (h1 && !serverName) serverName = h1.textContent.trim();
      
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
      
      // Buscar miembros en el texto
      const bodyText = document.body.innerText;
      const membersPatterns = [
        /(\d+(?:[.,]\d+)?)\s*([KMB])?\s*(?:members|miembros)/gi,
      ];
      
      for (const pattern of membersPatterns) {
        const matches = bodyText.matchAll(pattern);
        for (const match of matches) {
          const count = parseNumber(match[0]);
          if (count > members) members = count;
        }
      }
      
      // Buscar tags
      const tagEls = document.querySelectorAll('[class*="tag"], [class*="Tag"], .badge');
      tagEls.forEach(el => {
        const text = el.textContent.trim();
        if (text && text.length < 30) tags.push(text);
      });
      
      return {
        serverName,
        description,
        members,
        iconUrl,
        tags: tags.slice(0, 10)
      };
    });

    // Si no encontramos datos en top.gg, intentar discord.me
    if (!profileData.serverName) {
      url = `https://discord.me/${serverIdOrInvite}`;
      console.log(`🌐 [Discord] Intentando discord.me: ${url}`);
      
      await page.goto(url, { 
        waitUntil: 'domcontentloaded', 
        timeout: 60000 
      });
      
      await new Promise(resolve => setTimeout(resolve, 4000));
      
      profileData = await page.evaluate(() => {
        let serverName = '';
        let description = '';
        let members = 0;
        let iconUrl = '';
        
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogDescription = document.querySelector('meta[property="og:description"]');
        
        if (ogTitle) serverName = ogTitle.content;
        if (ogImage) iconUrl = ogImage.content;
        if (ogDescription) description = ogDescription.content;
        
        const h1 = document.querySelector('h1');
        if (h1 && !serverName) serverName = h1.textContent.trim();
        
        const bodyText = document.body.innerText;
        const membersMatch = bodyText.match(/(\d+(?:,\d+)?)\s*(?:members|miembros)/i);
        if (membersMatch) {
          members = parseInt(membersMatch[1].replace(/,/g, ''));
        }
        
        return { serverName, description, members, iconUrl, tags: [] };
      });
    }

    await browser.close();

    if (!profileData || !profileData.serverName) {
      throw new Error('No se pudieron extraer los datos del servidor de Discord');
    }

    const result = {
      id: serverIdOrInvite,
      username: serverIdOrInvite,
      full_name: profileData.serverName,
      bio: profileData.description || '',
      followers: profileData.members || 0,
      profile_image_url: profileData.iconUrl || '',
      tags: profileData.tags || [],
      url: `https://discord.gg/${serverIdOrInvite}`,
      platform: 'discord'
    };
    
    console.log(`✅ [Discord] Scraped: ${result.full_name}`);
    console.log(`   Members: ${result.followers}`);
    
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (e) {}
    }
    throw new Error(`Error scraping Discord: ${error.message}`);
  }
}

module.exports = scrapeDiscord;
