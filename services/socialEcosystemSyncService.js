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
const axios = require('axios');
const { saveProfileImageForProfile } = require('../utils/imageSaver');

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

const DEFAULT_SYNC_INTERVAL_DAYS = 15;

function toDateOrNull(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value?.toDate === 'function') {
    try {
      return value.toDate();
    } catch (_) {
      return null;
    }
  }
  if (typeof value === 'number') return new Date(value);
  if (typeof value === 'string') {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

function daysBetween(now, past) {
  if (!past) return Infinity;
  return (now.getTime() - past.getTime()) / (1000 * 60 * 60 * 24);
}

function getSyncIntervalDays() {
  const raw = process.env.SYNC_INTERVAL_DAYS;
  const n = raw ? Number(raw) : NaN;
  if (Number.isFinite(n) && n > 0) return Math.floor(n);
  return DEFAULT_SYNC_INTERVAL_DAYS;
}

function getMigosMsBaseUrl() {
  return (
    process.env.MIGOS_MS_BASE_URL ||
    process.env.MIGOZZ_MS_BASE_URL ||
    process.env.API_MIGOZZ ||
    process.env.MIGOS_MS_URL ||
    null
  );
}

async function fetchProfileViaHttp({ baseUrl, platform, usernameOrLink }) {
  const safeBase = String(baseUrl || '').replace(/\/+$/, '');
  if (!safeBase) throw new Error('Base URL no configurada para HTTP scraper');

  const endpoint = `/${platform}/profile`;
  const url = `${safeBase}${endpoint}`;

  const response = await axios.get(url, {
    params: {
      username_or_link: usernameOrLink,
    },
    timeout: 60_000,
    validateStatus: (s) => s >= 200 && s < 500,
  });

  if (response.status >= 200 && response.status < 300) {
    return response.data;
  }
  const msg =
    typeof response.data === 'string'
      ? response.data
      : response.data?.error || JSON.stringify(response.data);
  throw new Error(`HTTP ${platform} error (${response.status}): ${msg}`);
}

function isPlainObject(value) {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

function removeUndefinedDeep(value) {
  // Preserve timestamps / dates.
  if (value instanceof Date) {
    return value;
  }
  // Firestore Timestamp (admin SDK) often has toDate()/toMillis().
  if (value && typeof value.toDate === 'function' && typeof value.toMillis === 'function') {
    try {
      return value.toDate();
    } catch (_) {
      return value;
    }
  }

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

function isNonEmptyString(v) {
  return typeof v === 'string' && v.trim().length > 0;
}

function isPlainNumber(v) {
  return typeof v === 'number' && Number.isFinite(v);
}

function mergePreferNonEmpty(existing, incoming) {
  // Prefer incoming when it looks valid; keep existing when incoming is empty-ish.
  if (incoming === undefined || incoming === null) return existing;

  if (typeof incoming === 'string') {
    if (incoming.trim() === '' && isNonEmptyString(existing)) return existing;
    return incoming;
  }

  if (isPlainNumber(incoming)) {
    // Avoid overwriting a good value with 0 when scrapers fail.
    if (incoming === 0 && isPlainNumber(existing) && existing > 0) return existing;
    return incoming;
  }

  if (typeof incoming === 'boolean') return incoming;

  if (Array.isArray(incoming)) {
    return incoming.length === 0 && Array.isArray(existing) && existing.length > 0
      ? existing
      : incoming;
  }

  if (isPlainObject(incoming)) {
    const out = isPlainObject(existing) ? { ...existing } : {};
    for (const [k, v] of Object.entries(incoming)) {
      out[k] = mergePreferNonEmpty(out[k], v);
    }
    return out;
  }

  return incoming;
}

function getPlatformDataFromSocialEcosystem(socialEcosystem, platform) {
  if (!Array.isArray(socialEcosystem)) return null;
  const item = socialEcosystem.find(
    (e) => isPlainObject(e) && Object.prototype.hasOwnProperty.call(e, platform),
  );
  if (!item) return null;
  return isPlainObject(item[platform]) ? item[platform] : item[platform];
}

function ensureUserSyncMeta(userData) {
  const meta = isPlainObject(userData?.socialEcosystemSyncMeta)
    ? userData.socialEcosystemSyncMeta
    : {};
  return { ...meta };
}

function getAddedAtForPlatform(userData, platform) {
  const meta = userData?.socialEcosystemSyncMeta;
  const fromMeta = isPlainObject(meta) && isPlainObject(meta[platform]) ? meta[platform].addedAt : null;
  const fromAddedDates =
    isPlainObject(userData?.socialEcosystemAddedDates) ? userData.socialEcosystemAddedDates[platform] : null;
  return toDateOrNull(fromMeta) || toDateOrNull(fromAddedDates);
}

function getLastSuccessAtForPlatform(userData, platform) {
  const meta = userData?.socialEcosystemSyncMeta;
  const v = isPlainObject(meta) && isPlainObject(meta[platform]) ? meta[platform].lastSuccessAt : null;
  return toDateOrNull(v);
}

function isPlatformDueForSync(userData, platform, intervalDays) {
  const now = new Date();
  const addedAt = getAddedAtForPlatform(userData, platform);
  const lastSuccessAt = getLastSuccessAtForPlatform(userData, platform);
  const anchor = lastSuccessAt || addedAt;
  if (!anchor) {
    // If we don't know when it was added, we avoid syncing immediately to prevent mass overwrites.
    return { due: false, reason: 'missing_added_at' };
  }
  const days = daysBetween(now, anchor);
  return { due: days >= intervalDays, reason: `days_since_${lastSuccessAt ? 'last_success' : 'added'}:${days.toFixed(2)}` };
}

function isProfileDataMeaningful(profileData) {
  if (!isPlainObject(profileData)) return false;

  // A minimal sanity check to avoid overwriting good data with scraper failures.
  const hasText = isNonEmptyString(profileData.full_name) || isNonEmptyString(profileData.bio);
  const hasCounts =
    (isPlainNumber(profileData.followers) && profileData.followers > 0) ||
    (isPlainNumber(profileData.following) && profileData.following > 0) ||
    (isPlainNumber(profileData.mediaCount) && profileData.mediaCount > 0) ||
    (isPlainNumber(profileData.posts) && profileData.posts > 0);
  const hasImage = isNonEmptyString(profileData.profile_image_url);
  return hasText || hasCounts || hasImage;
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
async function syncUserNetworks(userId, options = {}) {
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

    const intervalDays = Number.isFinite(options.intervalDays) && options.intervalDays > 0
      ? Math.floor(options.intervalDays)
      : getSyncIntervalDays();
    const syncMeta = ensureUserSyncMeta(userData);
    const now = new Date();

    console.log(`✅ Usuario encontrado: ${userData.displayName}`);
    console.log(`📊 Redes a sincronizar: ${socialEcosystem.length}`);

    if (socialEcosystem.length === 0) {
      console.log('⚠️ El usuario no tiene redes sociales agregadas');
      results.skipped = ['Sin redes sociales'];
      return results;
    }

    // 2. Normalizar lista de redes a sincronizar (soporta estructura actual del front)
    const networksToSyncAllRaw = [];
    for (const entry of socialEcosystem) {
      networksToSyncAllRaw.push(...normalizeSocialEcosystemEntry(entry));
    }

    // Deduplicar por plataforma (una sola sync por red por usuario)
    const uniqueByPlatform = new Map();
    for (const item of networksToSyncAllRaw) {
      if (!item?.platform) continue;
      if (!uniqueByPlatform.has(item.platform)) {
        uniqueByPlatform.set(item.platform, item);
      }
    }
    const networksToSyncAll = Array.from(uniqueByPlatform.values());

    // Filtrado opcional (para job programado)
    const filterPlatforms = Array.isArray(options.platforms)
      ? options.platforms.map((p) => String(p || '').toLowerCase()).filter(Boolean)
      : null;

    const networksToSync = filterPlatforms
      ? networksToSyncAll.filter(({ platform }) => filterPlatforms.includes(platform))
      : networksToSyncAll;

    if (networksToSync.length === 0) {
      console.log('⚠️ No se pudieron interpretar redes sociales (estructura inesperada)');
      results.skipped = ['Estructura socialEcosystem inválida'];
      return results;
    }

    // Copia que vamos a ir actualizando con los datos scrapeados
    let updatedSocialEcosystem = socialEcosystem;

    // 2.1 Asegurar addedAt por plataforma si no existe (no fuerza sync)
    let metaNeedsWrite = false;
    for (const { platform } of networksToSyncAll) {
      if (!isPlainObject(syncMeta[platform])) syncMeta[platform] = {};
      const existingAddedAt = getAddedAtForPlatform(userData, platform);
      if (!existingAddedAt) {
        syncMeta[platform].addedAt = now;
        metaNeedsWrite = true;
      }
    }

    // 3. Iterar sobre cada red social
    // Por defecto (endpoint manual): sincroniza todas.
    // Para job programado: se pasa options.platforms con las plataformas vencidas.
    for (const { platform, username } of networksToSync) {
      console.log(`\n   🌐 Scrapeando ${platform}: ${username}...`);

      try {
        const previousPlatformData = getPlatformDataFromSocialEcosystem(updatedSocialEcosystem, platform);

        // Resolver scraper: Instagram/LinkedIn via migos-ms si está configurado.
        const migosMsBase = getMigosMsBaseUrl();
        let profileDataRaw;
        if ((platform === 'instagram' || platform === 'linkedin') && migosMsBase) {
          profileDataRaw = await fetchProfileViaHttp({
            baseUrl: migosMsBase,
            platform,
            usernameOrLink: username,
          });
        } else {
          const scraper = SCRAPERS[platform];
          if (!scraper) {
            throw new Error(`Scraper no disponible para ${platform}`);
          }
          profileDataRaw = await scraper(username);
        }

        const profileDataClean = removeUndefinedDeep(profileDataRaw || {});

        // Intentar persistir imagen (opcional)
        let profileData = profileDataClean;
        try {
          if (isNonEmptyString(profileDataClean.profile_image_url)) {
            const saved = await saveProfileImageForProfile({
              platform,
              username,
              imageUrl: profileDataClean.profile_image_url,
            });
            if (saved) {
              profileData = {
                ...profileDataClean,
                profile_image_saved: true,
                profile_image_storage_path: saved.path,
                profile_image_saved_at: new Date(),
                // prefer stable URL if available
                profile_image_url: saved.publicUrl || profileDataClean.profile_image_url,
              };
            }
          }
        } catch (e) {
          console.warn(`   ⚠️  Error guardando imagen (${platform}):`, e.message);
        }

        // Validar data para evitar sobrescrituras con vacíos
        const meaningful = isProfileDataMeaningful(profileData);

        // Guardar historial (antes/después)
        await saveToHistory(userId, platform, {
          status: meaningful ? 'success' : 'empty_payload',
          before: previousPlatformData || null,
          after: profileData,
          username,
          intervalDays,
        });

        if (!meaningful) {
          throw new Error('Scraper devolvió payload vacío/inválido; no se actualiza Firestore');
        }

        // Merge seguro: no reemplazar valores buenos por vacíos
        const merged = mergePreferNonEmpty(previousPlatformData || {}, profileData);

        // Actualizar el socialEcosystem del usuario con la data fresca
        updatedSocialEcosystem = upsertPlatformInSocialEcosystem(
          updatedSocialEcosystem,
          platform,
          merged,
        );

        // Actualizar meta por plataforma
        if (!isPlainObject(syncMeta[platform])) syncMeta[platform] = {};
        syncMeta[platform].lastAttemptAt = now;
        syncMeta[platform].lastSuccessAt = now;
        syncMeta[platform].lastError = null;
        syncMeta[platform].lastErrorAt = null;
        metaNeedsWrite = true;

        results.successful.push({
          platform,
          username,
          followers: merged.followers ?? null,
          timestamp: new Date(),
        });

        const followersText = merged.followers ?? 'N/A';
        console.log(`   ✅ ${platform}: ${followersText} followers`);
      } catch (error) {
        console.error(`   ❌ ${platform} Error:`, error.message);

        // Historial de error
        try {
          const previousPlatformData = getPlatformDataFromSocialEcosystem(updatedSocialEcosystem, platform);
          await saveToHistory(userId, platform, {
            status: 'failed',
            error: error.message,
            before: previousPlatformData || null,
            after: null,
            username,
            intervalDays,
          });
        } catch (_) {}

        if (!isPlainObject(syncMeta[platform])) syncMeta[platform] = {};
        syncMeta[platform].lastAttemptAt = now;
        syncMeta[platform].lastError = error.message;
        syncMeta[platform].lastErrorAt = now;
        metaNeedsWrite = true;

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

    const userUpdatePayload = removeUndefinedDeep({
      socialEcosystem: updatedSocialEcosystem,
      // Mantener este campo como "última sync exitosa" (al menos una plataforma)
      lastSocialEcosystemSync: results.successful.length > 0 ? syncEndTime : undefined,
      socialEcosystemSyncStatus: {
        ...existingStatus,
        successful: results.successful.length,
        failed: results.failed.length,
        lastSyncTime: syncEndTime,
        updatedAt: syncEndTime,
      },
      socialEcosystemSyncMeta: metaNeedsWrite ? syncMeta : undefined,
    });

    await db.collection('users').doc(userId).update(userUpdatePayload);

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
    usersSkipped: 0,
    startTime: globalStartTime,
    endTime: null,
    totalTime: 0,
    details: [],
  };

  try {
    // Obtener todos los usuarios
    const usersSnapshot = await db.collection('users').get();
    summary.totalUsers = usersSnapshot.size;
    console.log(`📊 Total de usuarios: ${usersSnapshot.size}`);

    const intervalDays = getSyncIntervalDays();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const socialEcosystem = userData.socialEcosystem || [];

      // Determinar plataformas vencidas POR RED
      const normalized = [];
      for (const entry of Array.isArray(socialEcosystem) ? socialEcosystem : []) {
        normalized.push(...normalizeSocialEcosystemEntry(entry));
      }

      if (normalized.length === 0) {
        summary.usersSkipped++;
        continue;
      }

      // Seed meta.addedAt si falta, para que el conteo empiece (sin sincronizar hoy)
      const existingMeta = ensureUserSyncMeta(userData);
      let metaNeedsWrite = false;
      const now = new Date();
      for (const { platform } of normalized) {
        const hasAdded = !!getAddedAtForPlatform(userData, platform);
        if (!hasAdded) {
          if (!isPlainObject(existingMeta[platform])) existingMeta[platform] = {};
          existingMeta[platform].addedAt = now;
          metaNeedsWrite = true;
        }
      }
      if (metaNeedsWrite) {
        try {
          await db.collection('users').doc(userId).update({
            socialEcosystemSyncMeta: removeUndefinedDeep(existingMeta),
          });
        } catch (e) {
          console.warn(`⚠️  No se pudo guardar socialEcosystemSyncMeta para ${userId}:`, e.message);
        }
      }

      const dueSet = new Set();
      for (const { platform } of normalized) {
        const { due } = isPlatformDueForSync(userData, platform, intervalDays);
        if (due) dueSet.add(platform);
      }

      const duePlatforms = Array.from(dueSet.values());

      if (duePlatforms.length === 0) {
        summary.usersSkipped++;
        continue;
      }

      console.log(`\n▶️  Sincronizando usuario: ${userId} (plataformas: ${duePlatforms.join(', ')})`);

      try {
        const result = await syncUserNetworks(userId, {
          platforms: duePlatforms,
          intervalDays,
        });
        summary.usersSync++;
        summary.details.push({
          userId,
          status: 'success',
          duePlatforms,
          result,
        });
      } catch (error) {
        summary.usersFailed++;
        summary.details.push({
          userId,
          status: 'failed',
          duePlatforms,
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
    syncedAt: new Date(),
    ...safeData,
  });

  try {
    // Guardar en subcollection: users/{userId}/socialEcosystemHistory/{platform}/syncs/{timestamp}
    // Nota: Firestore NO crea el documento padre automáticamente.
    // Creamos un doc "índice" por plataforma para que el historial sea visible/listable.
    const platformDocRef = db
      .collection('users')
      .doc(userId)
      .collection('socialEcosystemHistory')
      .doc(safePlatform);

    await platformDocRef.set(
      removeUndefinedDeep({
        platform: safePlatform,
        updatedAt: new Date(),
        lastSyncedAt: historyEntry.syncedAt,
        lastStatus: historyEntry.status || 'unknown',
      }),
      { merge: true },
    );

    await platformDocRef
      .collection('syncs')
      .doc(String(Date.now()))
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
      intervalDays: getSyncIntervalDays(),
    };

    let totalDaysSince = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const lastSync = userData.lastSocialEcosystemSync?.toDate?.() || null;

      if (lastSync) {
        stats.usersSynced++;
        const daysSince = (new Date() - lastSync) / (1000 * 60 * 60 * 24);
        totalDaysSince += daysSince;
      }

      // usersNeedSync: al menos una plataforma vencida
      const socialEcosystem = userData.socialEcosystem || [];
      const normalized = [];
      for (const entry of Array.isArray(socialEcosystem) ? socialEcosystem : []) {
        normalized.push(...normalizeSocialEcosystemEntry(entry));
      }
      const intervalDays = stats.intervalDays;
      const hasDue = normalized.some(({ platform }) => isPlatformDueForSync(userData, platform, intervalDays).due);
      if (hasDue) stats.usersNeedSync++;
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
