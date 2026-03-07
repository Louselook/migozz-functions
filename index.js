require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { extractUsername, resolveFacebookShareUrl } = require('./utils/helpers');
const { syncUserNetworks, syncAllUsersThatNeedUpdate, getSyncStatus } = require('./services/socialEcosystemSyncService');
const { generateMemberExcel, generatePreRegisteredExcel } = require('./services/excelExportService');

// Inicializar Firebase Admin (obligatorio antes de cualquier operación)
require('./config/firebaseAdmin');

// Importar todos los scrapers
const scrapeTikTok = require('./scrapers/tiktok');
const scrapeFacebook = require('./scrapers/facebook');
const scrapeTwitch = require('./scrapers/twitch');
const scrapeKick = require('./scrapers/kick');
const scrapeTrovo = require('./scrapers/trovo');
const scrapeYouTube = require('./scrapers/youtube');
const scrapeInstagram = require('./scrapers/instagram');
const scrapeTwitter = require('./scrapers/twitter');
const scrapeSpotify = require('./scrapers/spotify');
const scrapeReddit = require('./scrapers/reddit');
const scrapeThreads = require('./scrapers/threads');
const scrapeLinkedIn = require('./scrapers/linkedin');
const scrapePinterest = require('./scrapers/pinterest');
const scrapeSoundCloud = require('./scrapers/soundcloud');
const scrapeAppleMusic = require('./scrapers/applemusic');
const scrapeDeezer = require('./scrapers/deezer');
const scrapeDiscord = require('./scrapers/discord');
const scrapeSnapchat = require('./scrapers/snapchat');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

// ==================== VALIDACIÓN DE PERFILES ====================

/**
 * Valida que el resultado del scraping corresponda a un perfil real.
 * Retorna { valid: true } o { valid: false, reason: '...' }
 *
 * Señales de perfil inexistente:
 *  - full_name vacío Y profile_image_url vacío → el scraper no encontró nada real
 *  - Facebook redirige a /login cuando el usuario no existe
 *  - YouTube devuelve URL sin channel ID
 *  - username igual a valores genéricos de redirección (login, explore, etc.)
 */
function validateScrapedProfile(result, platform) {
  if (!result) return { valid: false, reason: 'No data returned from scraper' };

  const fullName = (result.full_name || '').trim();
  const imageUrl = (result.profile_image_url || '').trim();
  const username = (result.username || '').trim();
  const url = (result.url || '').trim();
  const id = (result.id || '').trim();

  // 1. Valores genéricos que indican redirección (no un perfil real)
  const invalidUsernames = [
    'login', 'explore', 'signup', 'register', 'watch',
    'search', 'home', 'settings', 'help', 'about',
    'privacy', 'terms', 'accounts', 'directory',
  ];
  if (invalidUsernames.includes(username.toLowerCase())) {
    return { valid: false, reason: `Invalid username detected: "${username}" (redirect page)` };
  }

  // 2. Facebook específico: id === 'login' o redirección
  if (platform === 'facebook') {
    if (id.toLowerCase() === 'login' || username.toLowerCase() === 'login') {
      return { valid: false, reason: 'Facebook redirected to login page — profile not found' };
    }
  }

  // 3. YouTube específico: URL termina en /channel/ sin ID
  if (platform === 'youtube') {
    if (url.endsWith('/channel/') || url.endsWith('/channel')) {
      return { valid: false, reason: 'YouTube channel ID not found — profile does not exist' };
    }
  }

  // 4. Regla general: sin nombre Y sin imagen → no se encontró nada real
  if (!fullName && !imageUrl) {
    return { valid: false, reason: 'Profile not found: no name and no profile image returned' };
  }

  return { valid: true };
}

// Lista de plataformas soportadas
const PLATFORMS = [
  'tiktok', 'facebook', 'twitch', 'kick', 'trovo',
  'youtube', 'instagram', 'twitter', 'spotify', 'reddit',
  'threads', 'linkedin', 'pinterest', 'soundcloud',
  'applemusic', 'deezer', 'discord', 'snapchat'
];

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Migozz Scraper Service',
    version: '3.0.0',
    platforms: PLATFORMS,
    endpoints: PLATFORMS.map(p => `GET /${p}/profile?username_or_link=xxx`)
  });
});

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
    const validation = validateScrapedProfile(result, 'tiktok');
    if (!validation.valid) {
      console.warn(`⚠️ [TikTok] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'tiktok' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [TikTok] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/facebook/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    let inputToProcess = username_or_link.trim();

    // ── Detect and resolve Facebook share links ──────────────────────────────
    // Share URLs look like: https://www.facebook.com/share/1CNr26dt8N/
    // They don't contain a username in the path; we must follow the redirect.
    const isShareUrl = /facebook\.com\/(share|sharer)\//i.test(inputToProcess);
    if (isShareUrl) {
      console.log(`🔗 [Facebook] Share URL detected, resolving redirect...`);
      const resolvedUrl = await resolveFacebookShareUrl(inputToProcess);
      if (!resolvedUrl) {
        return res.status(400).json({
          error: 'unresolvable_share_url',
          message: 'Could not resolve the Facebook share link to a real profile URL. Try using the direct profile URL instead.',
          platform: 'facebook'
        });
      }
      inputToProcess = resolvedUrl;
      console.log(`➡️ [Facebook] Using resolved URL: ${inputToProcess}`);
    }
    // ────────────────────────────────────────────────────────────────────────

    const username = extractUsername(inputToProcess, 'facebook');

    if (!username) {
      return res.status(400).json({
        error: 'username_not_found',
        message: 'Could not extract a username from the provided link. Please use a direct profile URL (e.g. facebook.com/username) or just the username.',
        platform: 'facebook'
      });
    }

    console.log(`📥 [Facebook] Scraping: ${username}`);
    const result = await scrapeFacebook(username);
    const validation = validateScrapedProfile(result, 'facebook');
    if (!validation.valid) {
      console.warn(`⚠️ [Facebook] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'facebook' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Facebook] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});



app.get('/twitch/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'twitch');
    console.log(`📥 [Twitch] Scraping: ${username}`);
    const result = await scrapeTwitch(username);
    const validation = validateScrapedProfile(result, 'twitch');
    if (!validation.valid) {
      console.warn(`⚠️ [Twitch] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'twitch' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Twitch] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/kick/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'kick');
    console.log(`📥 [Kick] Scraping: ${username}`);
    const result = await scrapeKick(username);
    const validation = validateScrapedProfile(result, 'kick');
    if (!validation.valid) {
      console.warn(`⚠️ [Kick] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'kick' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Kick] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/trovo/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'trovo');
    console.log(`📥 [Trovo] Scraping: ${username}`);
    const result = await scrapeTrovo(username);
    const validation = validateScrapedProfile(result, 'trovo');
    if (!validation.valid) {
      console.warn(`⚠️ [Trovo] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'trovo' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Trovo] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

// ==================== NUEVAS RUTAS ====================

app.get('/youtube/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'youtube');
    console.log(`📥 [YouTube] Scraping: ${username}`);
    const result = await scrapeYouTube(username);
    const validation = validateScrapedProfile(result, 'youtube');
    if (!validation.valid) {
      console.warn(`⚠️ [YouTube] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'youtube' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [YouTube] Error:`, error.message);
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
    const validation = validateScrapedProfile(result, 'instagram');
    if (!validation.valid) {
      console.warn(`⚠️ [Instagram] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'instagram' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Instagram] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/twitter/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'twitter');
    console.log(`📥 [Twitter/X] Scraping: ${username}`);
    const result = await scrapeTwitter(username);
    const validation = validateScrapedProfile(result, 'twitter');
    if (!validation.valid) {
      console.warn(`⚠️ [Twitter/X] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'twitter' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Twitter/X] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/spotify/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    console.log(`📥 [Spotify] Scraping: ${username_or_link}`);
    const artistInput = extractUsername(username_or_link, 'spotify');
    console.log(`📥 [Spotify] Scraping: ${artistInput}`);
    const result = await scrapeSpotify(artistInput);
    const validation = validateScrapedProfile(result, 'spotify');
    if (!validation.valid) {
      console.warn(`⚠️ [Spotify] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'spotify' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Spotify] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/reddit/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    console.log(`📥 [Reddit] Scraping: ${username_or_link}`);
    const redditInput = extractUsername(username_or_link, 'reddit');
    console.log(`📥 [Reddit] Scraping: ${redditInput}`);
    const result = await scrapeReddit(redditInput);
    const validation = validateScrapedProfile(result, 'reddit');
    if (!validation.valid) {
      console.warn(`⚠️ [Reddit] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'reddit' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Reddit] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/threads/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'threads');
    console.log(`📥 [Threads] Scraping: ${username}`);
    const result = await scrapeThreads(username);
    const validation = validateScrapedProfile(result, 'threads');
    if (!validation.valid) {
      console.warn(`⚠️ [Threads] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'threads' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Threads] Error:`, error.message);
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
    const validation = validateScrapedProfile(result, 'linkedin');
    if (!validation.valid) {
      console.warn(`⚠️ [LinkedIn] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'linkedin' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [LinkedIn] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/pinterest/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'pinterest');
    console.log(`📥 [Pinterest] Scraping: ${username}`);
    const result = await scrapePinterest(username);
    const validation = validateScrapedProfile(result, 'pinterest');
    if (!validation.valid) {
      console.warn(`⚠️ [Pinterest] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'pinterest' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Pinterest] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/soundcloud/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'soundcloud');
    console.log(`📥 [SoundCloud] Scraping: ${username}`);
    const result = await scrapeSoundCloud(username);
    const validation = validateScrapedProfile(result, 'soundcloud');
    if (!validation.valid) {
      console.warn(`⚠️ [SoundCloud] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'soundcloud' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [SoundCloud] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

// ==================== NUEVAS PLATAFORMAS v3.1 ====================

app.get('/applemusic/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    console.log(`📥 [Apple Music] Scraping: ${username_or_link}`);
    const artistInput = extractUsername(username_or_link, 'applemusic');
    console.log(`📥 [Apple Music] Scraping: ${artistInput}`);
    const result = await scrapeAppleMusic(artistInput);
    const validation = validateScrapedProfile(result, 'applemusic');
    if (!validation.valid) {
      console.warn(`⚠️ [Apple Music] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'applemusic' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Apple Music] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/deezer/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    console.log(`📥 [Deezer] Scraping: ${username_or_link}`);
    const artistInput = extractUsername(username_or_link, 'deezer');
    console.log(`📥 [Deezer] Scraping: ${artistInput}`);
    const result = await scrapeDeezer(artistInput);
    const validation = validateScrapedProfile(result, 'deezer');
    if (!validation.valid) {
      console.warn(`⚠️ [Deezer] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'deezer' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Deezer] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/discord/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    console.log(`📥 [Discord] Scraping: ${username_or_link}`);
    const serverInput = extractUsername(username_or_link, 'discord');
    console.log(`📥 [Discord] Scraping: ${serverInput}`);
    const result = await scrapeDiscord(serverInput);
    const validation = validateScrapedProfile(result, 'discord');
    if (!validation.valid) {
      console.warn(`⚠️ [Discord] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'discord' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Discord] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

app.get('/snapchat/profile', async (req, res) => {
  const { username_or_link } = req.query;
  if (!username_or_link) {
    return res.status(400).json({ error: 'Parámetro username_or_link requerido' });
  }

  try {
    const username = extractUsername(username_or_link, 'snapchat');
    console.log(`📥 [Snapchat] Scraping: ${username}`);
    const result = await scrapeSnapchat(username);
    const validation = validateScrapedProfile(result, 'snapchat');
    if (!validation.valid) {
      console.warn(`⚠️ [Snapchat] Profile not found: ${validation.reason}`);
      return res.status(404).json({ error: 'profile_not_found', message: validation.reason, platform: 'snapchat' });
    }
    res.json(result);
  } catch (error) {
    console.error(`❌ [Snapchat] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

// ==================== EXPORTACIÓN EXCEL ====================

/**
 * Endpoint: GET /export/members
 * Genera y descarga un archivo Excel con los datos de los miembros.
 *
 * Query params:
 *   - startDate (YYYY-MM-DD) — fecha inicio filtro por joinedAt
 *   - endDate   (YYYY-MM-DD) — fecha fin filtro por joinedAt
 *   - adminName (string)     — nombre del administrador que exporta
 */
app.get('/export/members', async (req, res) => {
  const { startDate, endDate, adminName } = req.query;

  try {
    console.log(`\n📥 [API] GET /export/members`);
    console.log(`   Filters: startDate=${startDate || 'all'}, endDate=${endDate || 'all'}, admin=${adminName || 'System'}`);

    const workbook = await generateMemberExcel({ startDate, endDate, adminName });

    const filename = `Migozz_Members_${new Date().toISOString().slice(0, 10)}.xlsx`;

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    await workbook.xlsx.write(res);
    res.end();

    console.log(`[Export] Excel sent: ${filename}`);
  } catch (error) {
    console.error(`[Export] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Endpoint: GET /export/pre-registered
 * Genera y descarga un archivo Excel con los usuarios pre-registrados.
 *
 * Query params:
 *   - startDate (YYYY-MM-DD) — fecha inicio filtro por preRegisteredAt
 *   - endDate   (YYYY-MM-DD) — fecha fin filtro por preRegisteredAt
 *   - adminName (string)     — nombre del administrador que exporta
 */
app.get('/export/pre-registered', async (req, res) => {
  const { startDate, endDate, adminName } = req.query;

  try {
    console.log(`\n[API] GET /export/pre-registered`);
    console.log(`   Filters: startDate=${startDate || 'all'}, endDate=${endDate || 'all'}, admin=${adminName || 'System'}`);

    const workbook = await generatePreRegisteredExcel({ startDate, endDate, adminName });

    const filename = `Migozz_PreRegistered_${new Date().toISOString().slice(0, 10)}.xlsx`;

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    await workbook.xlsx.write(res);
    res.end();

    console.log(`[Export] Excel sent: ${filename}`);
  } catch (error) {
    console.error(`[Export] Error:`, error.message);
    res.status(500).json({ error: error.message });
  }
});

// ==================== RUTAS DE SINCRONIZACIÓN ====================

/**
 * Endpoint: POST /sync/user/{userId}
 * Sincroniza todas las redes sociales de un usuario específico
 * Usado por:
 * - Botón "Actualizar ahora" en la app Flutter
 * - Testing manual
 * - Sincronización bajo demanda
 */
app.post('/sync/user/:userId', async (req, res) => {
  const { userId } = req.params;

  if (!userId) {
    return res.status(400).json({ error: 'userId requerido' });
  }

  // Optional: sync only some platforms
  // - Query: ?platform=instagram  OR  ?platforms=instagram,tiktok
  // - Body: { platforms: ['instagram','tiktok'] }
  const queryPlatform = req.query?.platform;
  const queryPlatforms = req.query?.platforms;
  const bodyPlatforms = req.body?.platforms;

  let platforms = null;
  if (typeof queryPlatform === 'string' && queryPlatform.trim()) {
    platforms = [queryPlatform.trim()];
  } else if (typeof queryPlatforms === 'string' && queryPlatforms.trim()) {
    platforms = queryPlatforms
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  } else if (Array.isArray(bodyPlatforms) && bodyPlatforms.length > 0) {
    platforms = bodyPlatforms.map((s) => String(s || '').trim()).filter(Boolean);
  }

  if (platforms && platforms.length === 0) platforms = null;

  try {
    console.log(`\n📥 [API] POST /sync/user/${userId}`);
    if (platforms) {
      console.log(`   ↳ Platforms filter: ${platforms.join(', ')}`);
    }

    const result = await syncUserNetworks(userId, platforms ? { platforms } : undefined);

    return res.json({
      status: 'success',
      message: 'Usuario sincronizado correctamente',
      data: result,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error(`❌ [Sync] Error:`, error.message);
    return res.status(500).json({
      status: 'error',
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * Endpoint: POST /sync/all-users
 * Sincroniza TODOS los usuarios que necesitan actualización (cada 15 días)
 * Llamado automáticamente por Cloud Scheduler
 * 
 * Cloud Scheduler Config:
 * - Frequency: 0 0 * * * (Diariamente a las 12:00 AM UTC)
 * - URL: https://migozz-functions-[PROJECT_ID].[REGION].run.app/sync/all-users
 * - Auth: Add OIDC token (requiere autenticación de Cloud Run)
 */
app.post('/sync/all-users', async (req, res) => {
  try {
    console.log(`\n📥 [API] POST /sync/all-users - Cloud Scheduler triggered`);
    const result = await syncAllUsersThatNeedUpdate();

    return res.json({
      status: 'success',
      message: 'Sincronización global completada',
      data: result,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error(`❌ [Sync Global] Error:`, error.message);
    return res.status(500).json({
      status: 'error',
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * Endpoint: GET /sync/status
 * Obtiene el estado del servicio de sincronización
 * Retorna estadísticas sobre usuarios sincronizados
 */
app.get('/sync/status', async (req, res) => {
  try {
    console.log(`\n📥 [API] GET /sync/status`);
    const status = await getSyncStatus();

    return res.json({
      status: 'success',
      data: status,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error(`❌ [Status] Error:`, error.message);
    return res.status(500).json({
      status: 'error',
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Migozz Scraper Service v3.1 corriendo en puerto ${PORT}`);
  console.log(`📡 ${PLATFORMS.length} plataformas soportadas:`);
  PLATFORMS.forEach(p => console.log(`   GET /${p}/profile?username_or_link=xxx`));
  console.log(``);
  console.log(`✅ Campos compatibles con social_normalizer.dart`);
});