const express = require('express');
const cors = require('cors');
const { extractUsername } = require('./utils/helpers');

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
    const username = extractUsername(username_or_link, 'facebook');
    console.log(`📥 [Facebook] Scraping: ${username}`);
    const result = await scrapeFacebook(username);
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
    const result = await scrapeSpotify(username_or_link);
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
    const result = await scrapeReddit(username_or_link);
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
    const result = await scrapeAppleMusic(username_or_link);
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
    const result = await scrapeDeezer(username_or_link);
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
    const result = await scrapeDiscord(username_or_link);
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
    res.json(result);
  } catch (error) {
    console.error(`❌ [Snapchat] Error:`, error.message);
    res.status(500).json({ error: error.message });
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