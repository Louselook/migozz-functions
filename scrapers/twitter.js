const axios = require('axios');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

/**
 * Scraper para perfiles de Twitter/X
 *
 * Strategy:
 *  1. Fetch a guest token from Twitter's public endpoint (no login needed)
 *  2. Use the guest token to call the UserByScreenName GraphQL API directly
 *  3. If the API fails (rate-limit, etc.) fall back to a lightweight
 *     Puppeteer scrape of x.com with a mobile UA that bypasses the login wall
 *
 * Why not Puppeteer-first?
 *  X.com now redirects all headless browsers to a login interstitial that
 *  blocks both GraphQL interception and DOM scraping.
 *
 * @param {string} username - Twitter/X handle (without @)
 * @returns {Promise<Object>} Profile data
 */

// Twitter's public bearer token — used only for unauthenticated guest requests.
// This token is embedded in Twitter's own JS bundle and is intentionally public.
const BEARER_TOKEN = 'AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA';

// GraphQL operation ID for UserByScreenName (stable across most Twitter app versions)
const USER_BY_SCREEN_NAME_QUERY_ID = 'G3KGOASz96M-Qu0nwmGXNg';

const GRAPHQL_FEATURES = JSON.stringify({
  hidden_profile_likes_enabled: false,
  hidden_profile_subscriptions_enabled: true,
  responsive_web_graphql_exclude_directive_enabled: true,
  verified_phone_label_enabled: false,
  subscriptions_verification_info_is_identity_verified_enabled: false,
  subscriptions_verification_info_verified_since_enabled: true,
  highlights_tweets_tab_ui_enabled: true,
  creator_subscriptions_tweet_preview_api_enabled: true,
  responsive_web_graphql_skip_user_profile_image_extensions_enabled: false,
  responsive_web_graphql_timeline_navigation_enabled: true,
});

async function getGuestToken() {
  const res = await axios.post(
    'https://api.twitter.com/1.1/guest/activate.json',
    {},
    {
      headers: {
        Authorization: `Bearer ${BEARER_TOKEN}`,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
      timeout: 10000,
    }
  );
  return res.data.guest_token;
}

async function fetchUserViaAPI(username) {
  const guestToken = await getGuestToken();

  const variables = JSON.stringify({ screen_name: username, withSafetyModeUserFields: true });
  const url =
    `https://twitter.com/i/api/graphql/${USER_BY_SCREEN_NAME_QUERY_ID}/UserByScreenName` +
    `?variables=${encodeURIComponent(variables)}&features=${encodeURIComponent(GRAPHQL_FEATURES)}`;

  const res = await axios.get(url, {
    headers: {
      Authorization: `Bearer ${BEARER_TOKEN}`,
      'x-guest-token': guestToken,
      'x-twitter-client-language': 'en',
      'x-twitter-active-user': 'yes',
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      Referer: 'https://twitter.com/',
    },
    timeout: 15000,
  });

  const result = res.data?.data?.user?.result;
  if (!result) throw new Error('User not found in GraphQL response');

  const legacy = result.legacy || result;
  return {
    id: result.rest_id || result.id || username,
    username: legacy.screen_name || username,
    full_name: legacy.name || '',
    bio: legacy.description || '',
    followers: legacy.followers_count || 0,
    following: legacy.friends_count || 0,
    tweets: legacy.statuses_count || 0,
    likes: legacy.favourites_count || 0,
    profile_image_url: legacy.profile_image_url_https
      ? legacy.profile_image_url_https.replace('_normal', '')
      : '',
    verified: legacy.verified || result.is_blue_verified || false,
    location: legacy.location || '',
    created_at: legacy.created_at || '',
  };
}

async function scrapeTwitter(username) {
  username = username.replace('@', '').trim();
  console.log(`📥 [Twitter/X] Iniciando scraping para: ${username}`);

  // ── Method 1: Guest token + GraphQL API (fast, no browser needed) ──────────
  try {
    console.log(`🔑 [Twitter/X] Trying guest token API...`);
    const data = await fetchUserViaAPI(username);
    console.log(`✅ [Twitter/X] Scraped via API: ${data.full_name}`);
    console.log(`   Followers: ${data.followers}`);

    const result = {
      ...data,
      url: `https://x.com/${username}`,
      platform: 'twitter',
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'twitter',
        username,
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
      console.warn('[Twitter] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }

    return result;
  } catch (apiError) {
    console.warn(`⚠️ [Twitter/X] API failed (${apiError.response?.status || apiError.message}), falling back to Puppeteer...`);
  }

  // ── Method 2: Puppeteer fallback — navigate to x.com with mobile UA ────────
  // A mobile user-agent avoids the login interstitial on x.com in many cases.
  const { createBrowser } = require('../utils/helpers');
  let browser;
  try {
    browser = await createBrowser();
    const page = await browser.newPage();

    await page.setViewport({ width: 390, height: 844 }); // mobile viewport
    await page.setUserAgent(
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
    );
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
    });

    // Intercept GraphQL API calls from within the page
    let apiData = null;
    await page.setRequestInterception(true);
    page.on('request', (req) => req.continue());
    page.on('response', async (response) => {
      const url = response.url();
      if (url.includes('/graphql/') && url.includes('UserByScreenName')) {
        try {
          const json = await response.json();
          if (json?.data?.user?.result) apiData = json.data.user.result;
        } catch (_) { }
      }
    });

    const xUrl = `https://x.com/${username}`;
    console.log(`🌐 [Twitter/X] Puppeteer navigating to: ${xUrl}`);
    await page.goto(xUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await new Promise((r) => setTimeout(r, 8000));

    let profileData = null;

    if (apiData) {
      const legacy = apiData.legacy || apiData;
      profileData = {
        id: apiData.rest_id || username,
        username: legacy.screen_name || username,
        full_name: legacy.name || '',
        bio: legacy.description || '',
        followers: legacy.followers_count || 0,
        following: legacy.friends_count || 0,
        tweets: legacy.statuses_count || 0,
        likes: legacy.favourites_count || 0,
        profile_image_url: legacy.profile_image_url_https
          ? legacy.profile_image_url_https.replace('_normal', '')
          : '',
        verified: legacy.verified || apiData.is_blue_verified || false,
        location: legacy.location || '',
        created_at: legacy.created_at || '',
      };
    } else {
      // DOM fallback
      profileData = await page.evaluate(() => {
        const ogImage = document.querySelector('meta[property="og:image"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const nameEl = document.querySelector('[data-testid="UserName"]');
        const bioEl = document.querySelector('[data-testid="UserDescription"]');

        let fullName = '';
        if (nameEl) {
          const spans = nameEl.querySelectorAll('span');
          if (spans.length > 0) fullName = spans[0].textContent.trim();
        }
        if (!fullName && ogTitle) {
          const m = ogTitle.content.match(/^([^(]+)\s*\(@/);
          if (m) fullName = m[1].trim();
        }

        let followers = 0;
        const links = document.querySelectorAll('a[href*="/followers"]');
        for (const link of links) {
          const text = link.textContent || '';
          const m = text.match(/(\d[\d,.]*)([KMB])?/i);
          if (m) {
            let n = parseFloat(m[1].replace(/,/g, ''));
            if (m[2]?.toUpperCase() === 'K') n *= 1000;
            if (m[2]?.toUpperCase() === 'M') n *= 1_000_000;
            if (n > followers) followers = Math.round(n);
          }
        }

        return {
          full_name: fullName,
          bio: bioEl ? bioEl.textContent.trim() : '',
          followers,
          profile_image_url: ogImage?.content || '',
        };
      });
    }

    await browser.close();

    if (!profileData?.full_name && !profileData?.profile_image_url) {
      throw new Error('No se pudieron extraer los datos del perfil de Twitter/X');
    }

    const result = {
      id: profileData.id || username,
      username: profileData.username || username,
      full_name: profileData.full_name || '',
      bio: profileData.bio || '',
      followers: profileData.followers || 0,
      following: profileData.following || 0,
      tweets: profileData.tweets || 0,
      likes: profileData.likes || 0,
      profile_image_url: profileData.profile_image_url || '',
      verified: profileData.verified || false,
      location: profileData.location || '',
      url: `https://x.com/${username}`,
      platform: 'twitter',
    };

    try {
      const saved = await saveProfileImageForProfile({
        platform: 'twitter',
        username,
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
      console.warn('[Twitter] Failed to save profile image:', e.message);
      result.profile_image_saved = false;
    }

    console.log(`✅ [Twitter/X] Scraped via Puppeteer: ${result.full_name || username}`);
    console.log(`   Followers: ${result.followers}`);
    return result;
  } catch (error) {
    if (browser) {
      try { await browser.close(); } catch (_) { }
    }
    throw new Error(`Error scraping Twitter/X: ${error.message}`);
  }
}

module.exports = scrapeTwitter;
