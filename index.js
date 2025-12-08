const express = require('express');
const cors = require('cors');
const { extractUsername } = require('./utils/helpers');
const scrapeTikTok = require('./scrapers/tiktok');
const scrapeFacebook = require('./scrapers/facebook');
const scrapeTwitch = require('./scrapers/twitch');
const scrapeKick  = require('./scrapers/kick');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'Migozz Scraper Service',
    version: '2.5.0',
    platforms: ['tiktok', 'facebook', 'twitch', 'kick']
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

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Migozz Scraper Service v2.5 corriendo en puerto ${PORT}`);
  console.log(`📡 Rutas disponibles:`);
  console.log(`   GET /tiktok/profile?username_or_link=xxx`);
  console.log(`   GET /facebook/profile?username_or_link=xxx`);
  console.log(`   GET /twitch/profile?username_or_link=xxx`);
  console.log(`   GET /kick/profile?username_or_link=xxx`);
  console.log(``);
  console.log(`✅ Campos compatibles con social_normalizer.dart`);
});