/**
 * Social Ecosystem Synchronization Service
 * 
 * Responsabilidades:
 * 1. Sincronizar datos de todas las redes sociales de un usuario
 * 2. Guardar historial de sincronización en Firestore
 * 3. Actualizar lastSocialEcosystemSync en el documento del usuario
 * 4. Manejar errores por plataforma sin fallar toda la sincronización
 */

const { db } = require('../config/firebaseAdmin');
const { extractUsername } = require('../utils/helpers');

// Importar todos los scrapers
const scrapeTikTok = require('../scrapers/tiktok');
const scrapeFacebook = require('../scrapers/facebook');
const scrapeTwitch = require('../scrapers/twitch');
const scrapeKick = require('../scrapers/kick');
const scrapeTrovo = require('../scrapers/trovo');
const scrapeYouTube = require('../scrapers/youtube');
const scrapeInstagram = require('../scrapers/instagram');
const scrapeTwitter = require('../scrapers/twitter');
const scrapeSpotify = require('../scrapers/spotify');
const scrapeReddit = require('../scrapers/reddit');
const scrapeThreads = require('../scrapers/threads');
const scrapeLinkedIn = require('../scrapers/linkedin');
const scrapePinterest = require('../scrapers/pinterest');
const scrapeSoundCloud = require('../scrapers/soundcloud');
const scrapeAppleMusic = require('../scrapers/applemusic');
const scrapeDeezer = require('../scrapers/deezer');
const scrapeDiscord = require('../scrapers/discord');
const scrapeSnapchat = require('../scrapers/snapchat');

// Mapeo de scrapers
const SCRAPERS = {
  tiktok: scrapeTikTok,
  facebook: scrapeFacebook,
  twitch: scrapeTwitch,
  kick: scrapeKick,
  trovo: scrapeTrovo,
  youtube: scrapeYouTube,
  instagram: scrapeInstagram,
  twitter: scrapeTwitter,
  spotify: scrapeSpotify,
  reddit: scrapeReddit,
  threads: scrapeThreads,
  linkedin: scrapeLinkedIn,
  pinterest: scrapePinterest,
  soundcloud: scrapeSoundCloud,
  applemusic: scrapeAppleMusic,
  deezer: scrapeDeezer,
  discord: scrapeDiscord,
  snapchat: scrapeSnapchat,
};

function isPlainObject(value) {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

function removeUndefinedDeep(value) {
  if (Array.isArray(value)) {
    return value
      .map(removeUndefinedDeep)
      .filter(v => v !== undefined);
  }

  if (isPlainObject(value)) {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      if (v === undefined) continue;
      const cleaned = removeUndefinedDeep(v);
      if (cleaned === undefined) continue;
      out[k] = cleaned;
    }
    return out;
  }

  return value;
}

/**
 * Normaliza un item de socialEcosystem del usuario a una lista de entradas.
 * Soporta 2 formatos:
 *  A) { platform: 'instagram', username: 'x' }
 *  B) { instagram: { username: 'x', ... } } (formato actual en tu app)
 */
function normalizeSocialEcosystemEntry(entry) {
  const items = [];

  if (!entry) return items;

  // Formato A
  if (isPlainObject(entry) && entry.platform && entry.username) {
    const platform = String(entry.platform).toLowerCase();
    const usernameRaw = String(entry.username);
    if (platform && usernameRaw) {
      items.push({
        platform,
        username: extractUsername(usernameRaw, platform),
      });
    }
    return items;
  }

  // Formato B
  if (isPlainObject(entry)) {
    for (const [platformKey, platformData] of Object.entries(entry)) {
      const platform = String(platformKey).toLowerCase();
      if (!platform || !SCRAPERS[platform]) continue;

      let usernameCandidate = null;
      if (typeof platformData === 'string') {
        usernameCandidate = platformData;
      } else if (isPlainObject(platformData)) {
        usernameCandidate =
          platformData.username ||
          platformData.id ||
          platformData.url;
      }

      if (!usernameCandidate) continue;

      items.push({
        platform,
        username: extractUsername(String(usernameCandidate), platform),
      });
    }
  }

  return items;
}

function upsertPlatformInSocialEcosystem(socialEcosystem, platform, platformPayload) {
  const next = Array.isArray(socialEcosystem) ? [...socialEcosystem] : [];
  const payloadClean = removeUndefinedDeep(platformPayload);

  // Buscar item existente del tipo { platform: {...} }
  const idx = next.findIndex(
    (item) => isPlainObject(item) && Object.prototype.hasOwnProperty.call(item, platform),
  );

  if (idx >= 0) {
    const existing = next[idx];
    const existingData = isPlainObject(existing[platform]) ? existing[platform] : {};
    next[idx] = {
      ...existing,
      [platform]: {
        ...existingData,
        ...payloadClean,
      },
    };
  } else {
    next.push({
      [platform]: payloadClean,
    });
  }

  return next;
}

/**
 * Sincroniza todas las redes sociales de un usuario
 * @param {string} userId - ID del usuario en Firestore
 * @returns {Promise<Object>} Resultado de la sincronización
 */
async function syncUserNetworks(userId) {
  console.log(`\n🔄 [SyncService] Iniciando sincronización para usuario: ${userId}`);
  
  const syncStartTime = new Date();
  const results = {
    userId,
    syncedAt: syncStartTime,
    successful: [],
    failed: [],
    skipped: [],
    totalTime: 0,
  };

  try {
    // 1. Obtener usuario de Firestore
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error(`Usuario no encontrado: ${userId}`);
    }

    const userData = userDoc.data();
    const socialEcosystem = userData.socialEcosystem || [];

    console.log(`✅ Usuario encontrado: ${userData.displayName}`);
    console.log(`📊 Redes a sincronizar: ${socialEcosystem.length}`);

    if (socialEcosystem.length === 0) {
      console.log('⚠️ El usuario no tiene redes sociales agregadas');
      results.skipped = ['Sin redes sociales'];
      return results;
    }

    // 2. Normalizar lista de redes a sincronizar (soporta estructura actual del front)
    const networksToSync = [];
    for (const entry of socialEcosystem) {
      networksToSync.push(...normalizeSocialEcosystemEntry(entry));
    }

    if (networksToSync.length === 0) {
      console.log('⚠️ No se pudieron interpretar redes sociales (estructura inesperada)');
      results.skipped = ['Estructura socialEcosystem inválida'];
      return results;
    }

    // Copia que vamos a ir actualizando con los datos scrapeados
    let updatedSocialEcosystem = socialEcosystem;

    // 3. Iterar sobre cada red social
    for (const { platform, username } of networksToSync) {
      console.log(`\n   🌐 Scrapeando ${platform}: ${username}...`);

      try {
        const scraper = SCRAPERS[platform];
        if (!scraper) {
          throw new Error(`Scraper no disponible para ${platform}`);
        }

        const profileDataRaw = await scraper(username);
        const profileData = removeUndefinedDeep(profileDataRaw || {});

        // Guardar en historial (sanitizado)
        await saveToHistory(userId, platform, profileData);

        // Actualizar el socialEcosystem del usuario con la data fresca
        updatedSocialEcosystem = upsertPlatformInSocialEcosystem(
          updatedSocialEcosystem,
          platform,
          profileData,
        );

        results.successful.push({
          platform,
          username,
          followers: profileData.followers ?? null,
          timestamp: new Date(),
        });

        const followersText = profileData.followers ?? 'N/A';
        console.log(`   ✅ ${platform}: ${followersText} followers`);
      } catch (error) {
        console.error(`   ❌ ${platform} Error:`, error.message);
        results.failed.push({
          platform,
          username,
          error: error.message,
          timestamp: new Date(),
        });
      }
    }

    // 4. Actualizar usuario en Firestore
    const syncEndTime = new Date();

    const existingStatus = isPlainObject(userData.socialEcosystemSyncStatus)
      ? userData.socialEcosystemSyncStatus
      : {};

    await db.collection('users').doc(userId).update(
      removeUndefinedDeep({
        socialEcosystem: updatedSocialEcosystem,
        lastSocialEcosystemSync: syncEndTime,
        socialEcosystemSyncStatus: {
          ...existingStatus,
          successful: results.successful.length,
          failed: results.failed.length,
          lastSyncTime: syncEndTime,
          updatedAt: syncEndTime,
        },
      }),
    );

    results.totalTime = syncEndTime - syncStartTime;

    console.log(`\n✅ Sincronización completada en ${results.totalTime}ms`);
    console.log(`   Exitosas: ${results.successful.length}`);
    console.log(`   Fallidas: ${results.failed.length}`);

    return results;
  } catch (error) {
    console.error(`❌ Error sincronizando usuario ${userId}:`, error.message);
    throw error;
  }
}

/**
 * Sincroniza TODOS los usuarios que necesitan actualización
 * Llamado por Cloud Scheduler automáticamente cada 15 días
 * @returns {Promise<Object>} Resumen de la sincronización
 */
async function syncAllUsersThatNeedUpdate() {
  console.log('\n🔄 [SyncService] SINCRONIZACIÓN GLOBAL - Buscando usuarios que necesitan actualización...\n');
  
  const globalStartTime = new Date();
  const summary = {
    totalUsers: 0,
    usersSync: 0,
    usersFailed: 0,
    startTime: globalStartTime,
    endTime: null,
    totalTime: 0,
    details: [],
  };

  try {
    // Obtener todos los usuarios
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Total de usuarios: ${usersSnapshot.size}`);

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const lastSync = userData.lastSocialEcosystemSync?.toDate?.() || null;

      // Verificar si necesita sincronización (más de 15 días)
      const needsSync = needsSyncByDays(lastSync, 15);

      if (!needsSync) {
        console.log(`⏭️  ${userId} - Aún no necesita sincronización`);
        continue;
      }

      console.log(`\n▶️  Sincronizando usuario: ${userId}`);
      summary.totalUsers++;

      try {
        const result = await syncUserNetworks(userId);
        summary.usersSync++;
        summary.details.push({
          userId,
          status: 'success',
          result,
        });
      } catch (error) {
        summary.usersFailed++;
        summary.details.push({
          userId,
          status: 'failed',
          error: error.message,
        });
      }
    }

    summary.endTime = new Date();
    summary.totalTime = summary.endTime - globalStartTime;

    console.log(`\n${'='.repeat(60)}`);
    console.log(`✅ SINCRONIZACIÓN GLOBAL COMPLETADA`);
    console.log(`   Total de usuarios procesados: ${summary.totalUsers}`);
    console.log(`   Exitosas: ${summary.usersSync}`);
    console.log(`   Fallidas: ${summary.usersFailed}`);
    console.log(`   Tiempo total: ${(summary.totalTime / 1000).toFixed(2)}s`);
    console.log(`${'='.repeat(60)}\n`);

    return summary;
  } catch (error) {
    console.error('❌ Error en sincronización global:', error.message);
    throw error;
  }
}

/**
 * Guarda el resultado de un scraping en el historial de Firestore
 * @param {string} userId - ID del usuario
 * @param {string} platform - Nombre de la plataforma
 * @param {Object} profileData - Datos del perfil scrapeado
 */
async function saveToHistory(userId, platform, profileData) {
  const safePlatform = String(platform || '').toLowerCase();
  const safeData = removeUndefinedDeep(profileData || {});

  const historyEntry = removeUndefinedDeep({
    platform: safePlatform,
    data: {
      // Campos comunes (si existen)
      id: safeData.id,
      username: safeData.username,
      full_name: safeData.full_name,
      bio: safeData.bio,
      followers: safeData.followers,
      following: safeData.following,
      verified: safeData.verified,
      profile_image_url: safeData.profile_image_url,
      url: safeData.url,
      // Extra: guarda todo el payload también para debug/histórico
      raw: safeData,
    },
    syncedAt: new Date(),
  });

  try {
    // Guardar en subcollection: users/{userId}/socialEcosystemHistory/syncs/{timestamp}
    await db
      .collection('users')
      .doc(userId)
      .collection('socialEcosystemHistory')
      .doc(`${platform}_${Date.now()}`)
      .set(historyEntry);

    console.log(`   📝 Historial guardado para ${platform}`);
  } catch (error) {
    console.warn(`   ⚠️  Error guardando historial para ${platform}:`, error.message);
    // No lanzar error - continuar con la sincronización
  }
}

/**
 * Verifica si un usuario necesita sincronización basado en días
 * @param {Date|null} lastSync - Última vez que se sincronizó
 * @param {number} intervalDays - Intervalo en días (default 15)
 * @returns {boolean}
 */
function needsSyncByDays(lastSync, intervalDays = 15) {
  if (!lastSync) {
    return true; // Nunca se ha sincronizado
  }

  const now = new Date();
  const daysSince = (now - lastSync) / (1000 * 60 * 60 * 24);

  return daysSince >= intervalDays;
}

/**
 * Obtiene el estado del servicio de sincronización
 * @returns {Promise<Object>}
 */
async function getSyncStatus() {
  try {
    const usersSnapshot = await db.collection('users').get();
    const stats = {
      totalUsers: usersSnapshot.size,
      usersSynced: 0,
      usersNeedSync: 0,
      averageLastSyncDays: 0,
    };

    let totalDaysSince = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const lastSync = userData.lastSocialEcosystemSync?.toDate?.() || null;

      if (lastSync) {
        stats.usersSynced++;
        const daysSince = (new Date() - lastSync) / (1000 * 60 * 60 * 24);
        totalDaysSince += daysSince;

        if (daysSince >= 15) {
          stats.usersNeedSync++;
        }
      }
    }

    if (stats.usersSynced > 0) {
      stats.averageLastSyncDays = (totalDaysSince / stats.usersSynced).toFixed(2);
    }

    return {
      status: 'operational',
      timestamp: new Date(),
      ...stats,
    };
  } catch (error) {
    console.error('Error obteniendo estado:', error.message);
    throw error;
  }
}

module.exports = {
  syncUserNetworks,
  syncAllUsersThatNeedUpdate,
  needsSyncByDays,
  getSyncStatus,
  saveToHistory,
};
