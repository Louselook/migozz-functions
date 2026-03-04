const axios = require('axios');
const { createBrowser } = require('../utils/helpers');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Apple Music artist scraper.
 *
 * Strategy (permanent, robust):
 *  1. If input is a full music.apple.com URL → navigate directly (most reliable)
 *  2. If input is a numeric artist ID → navigate to music.apple.com/artist/{id}
 *  3. If input is a plain artist name → use iTunes Search API to resolve the
 *     artist ID (instant, no browser, no scraping, public endpoint), then
 *     navigate to the canonical artist URL
 *
 * WHY: Apple Music's /search page changes its DOM frequently and cannot be
 * reliably queried by a headless browser. The iTunes Search API
 * (itunes.apple.com/search) is a stable, documented public endpoint that
 * returns structured JSON — it will not break when Apple changes their UI.
 *
 * @param {string} artistIdOrUrl - Artist name, numeric ID, or full Apple Music URL
 * @returns {Promise<Object>} Profile data
 */

const ITUNES_SEARCH = 'https://itunes.apple.com/search';

async function resolveArtistUrl(artistIdOrUrl) {
  const input = (artistIdOrUrl || '').trim();

  // Case 1: Full Apple Music URL — use as-is
  if (input.includes('music.apple.com')) {
    return input;
  }

  // Case 2: Numeric ID — build canonical URL
  if (/^\d+$/.test(input)) {
    return `https://music.apple.com/us/artist/${input}`;
  }

  // Case 3: Artist name — resolve via iTunes Search API
  console.log(`[Apple Music] 🔍 Resolving artist name via iTunes API: "${input}"`);
  const res = await axios.get(ITUNES_SEARCH, {
    params: { term: input, entity: 'musicArtist', limit: 1 },
    timeout: 10000,
  });

  const results = res.data?.results;
  if (!results || results.length === 0) {
    throw new Error(`Artist not found on iTunes: "${input}"`);
  }

  const artist = results[0];
  const artistId = artist.artistId;
  const canonicalUrl = `https://music.apple.com/us/artist/${artistId}`;
  console.log(`[Apple Music] ✅ iTunes resolved: ${artist.artistName} (ID: ${artistId})`);
  return canonicalUrl;
}

async function scrapeAppleMusic(artistIdOrUrl) {
  console.log(`[Apple Music] Starting scrape for: ${artistIdOrUrl}`);

  let browser;
  let artistUrl;

  try {
    // Step 1: Resolve the canonical artist URL
    artistUrl = await resolveArtistUrl(artistIdOrUrl);
    console.log(`[Apple Music] Navigating to: ${artistUrl}`);
  } catch (resolveErr) {
    throw new Error(`Error scraping Apple Music: ${resolveErr.message}`);
  }

  try {
    browser = await createBrowser();
    const page = await browser.newPage();

    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );

    await page.goto(artistUrl, {
      waitUntil: 'networkidle2',
      timeout: 60000,
    });

    await new Promise((r) => setTimeout(r, 4000));

    const profileData = await page.evaluate(() => {
      let artistName = '';
      let artistId = '';
      let profileImageUrl = '';
      let genres = [];
      let bio = '';

      // Extract artist ID from current URL
      const urlMatch = window.location.href.match(/\/artist\/(\d+)/);
      if (urlMatch) artistId = urlMatch[1];

      // Meta tags (most reliable on the direct artist page)
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');

      if (ogTitle) artistName = ogTitle.content.replace(/ on Apple Music$/, '').replace(/ en Apple Music$/, '').trim();
      if (ogImage) profileImageUrl = ogImage.content;
      if (ogDescription) bio = ogDescription.content;

      // JSON-LD (structured data — very stable)
      const ldScripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (const script of ldScripts) {
        try {
          const data = JSON.parse(script.textContent);
          if (data['@type'] === 'MusicGroup' || data['@type'] === 'Person') {
            if (data.name && !artistName) artistName = data.name;
            if (data.image && !profileImageUrl) profileImageUrl = data.image;
            if (data.description && !bio) bio = data.description;
            if (data.genre) genres = Array.isArray(data.genre) ? data.genre : [data.genre];
          }
        } catch (_) { }
      }

      // H1 fallback
      if (!artistName) {
        const h1 = document.querySelector('h1');
        if (h1) artistName = h1.textContent.trim();
      }

      // Artist image fallback
      if (!profileImageUrl) {
        const imgSelectors = [
          '[class*="artist-artwork"] img',
          '[class*="ArtistHeader"] img',
          'picture img[srcset]',
          '.headings__artwork img',
        ];
        for (const sel of imgSelectors) {
          const img = document.querySelector(sel);
          if (img?.src) { profileImageUrl = img.src; break; }
        }
      }

      // Inline scripts for artwork URL template
      if (!profileImageUrl) {
        const scripts = Array.from(document.querySelectorAll('script'));
        for (const script of scripts) {
          const text = script.textContent;
          if (text.includes('"artwork"') && text.includes('"url"')) {
            try {
              const artMatch = text.match(/"artwork"\s*:\s*\{[^}]*"url"\s*:\s*"([^"]+)"/);
              if (artMatch) {
                profileImageUrl = artMatch[1].replace('{w}', '400').replace('{h}', '400').replace('{f}', 'jpg');
                break;
              }
            } catch (_) { }
          }
        }
      }

      return { artistId, artistName, profileImageUrl, bio, genres, currentUrl: window.location.href };
    });

    await browser.close();

    if (!profileData?.artistName || profileData.artistName === 'An Error Occurred') {
      throw new Error('No se pudieron extraer los datos del artista de Apple Music');
    }

    const result = {
      id: profileData.artistId || artistIdOrUrl,
      username: profileData.artistName.toLowerCase().replace(/\s+/g, ''),
      full_name: profileData.artistName,
      bio: profileData.bio || '',
      genres: profileData.genres || [],
      followers: 0, // Apple Music does not expose follower counts publicly
      profile_image_url: profileData.profileImageUrl || '',
      url: profileData.currentUrl || artistUrl,
      platform: 'applemusic',
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'applemusic',
        username: result.id,
        imageUrl: result.profile_image_url,
      });
      if (saved) {
        result.profile_image_saved = true;
        result.profile_image_path = saved.path;
        if (saved.publicUrl) result.profile_image_public_url = saved.publicUrl;
      } else {
        result.profile_image_saved = false;
      }
    } catch (e) {
      console.warn('[Apple Music] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }

    console.log(`✅ [Apple Music] Scraped: ${result.full_name}`);
    return result;

  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (_) { }
    }
    throw new Error(`Error scraping Apple Music: ${error.message}`);
  }
}

module.exports = scrapeAppleMusic;
