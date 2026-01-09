#!/usr/bin/env node
/**
 * Script de Testing para validar el sistema de sincronización
 * 
 * Uso:
 * node test-sync.js
 * 
 * Qué hace:
 * 1. Conecta a Firestore
 * 2. Fuerza sincronización por plataforma (addedAt/lastSuccessAt)
 * 3. Ejecuta la sincronización manualmente
 * 4. Muestra resultados
 */

const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const axios = require('axios');

// ======================== CONFIG ========================
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(__dirname, 'serviceAccountKey.json');

const USER_EMAIL = 'juanes.arenilla@gmail.com'; // Tu usuario
const API_BASE = 'https://migozz-functions-895592952324.northamerica-northeast2.run.app';

console.log('🧪 INICIANDO TEST DE SINCRONIZACIÓN\n');

// ======================== INICIALIZAR FIREBASE ========================
let db;
try {
  const serviceAccount = require(SERVICE_ACCOUNT_PATH);
  initializeApp({
    credential: cert(serviceAccount),
  });
  db = getFirestore();
  console.log('✅ Firebase conectado\n');
} catch (error) {
  console.error('❌ Error conectando Firebase:', error.message);
  process.exit(1);
}

// ======================== MAIN ========================
async function runTest() {
  try {
    console.log('📋 PASO 1: Encontrar usuario por email...');
    
    // Buscar usuario por email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', USER_EMAIL)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.error(`❌ No se encontró usuario con email: ${USER_EMAIL}`);
      process.exit(1);
    }

    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();

    console.log(`✅ Usuario encontrado: ${userId}`);
    console.log(`   Email: ${userData.email}`);
    console.log(`   Nombre: ${userData.displayName}`);
    console.log(`   Redes: ${userData.socialEcosystem?.length || 0}\n`);

    // ======================== PASO 2: FORZAR VENCIMIENTO POR PLATAFORMA ========================
    console.log('📋 PASO 2: Forzando vencimiento por plataforma (hace 20 días)...');

    const twentyDaysAgo = new Date();
    twentyDaysAgo.setDate(twentyDaysAgo.getDate() - 20);

    // Extraer plataformas desde socialEcosystem (soporta formato A y B)
    const platforms = new Set();
    const social = Array.isArray(userData.socialEcosystem) ? userData.socialEcosystem : [];
    for (const entry of social) {
      if (!entry || typeof entry !== 'object') continue;
      if (entry.platform) {
        platforms.add(String(entry.platform).toLowerCase());
        continue;
      }
      for (const k of Object.keys(entry)) {
        platforms.add(String(k).toLowerCase());
      }
    }

    const syncMeta = {};
    for (const p of platforms) {
      syncMeta[p] = {
        addedAt: twentyDaysAgo,
        lastSuccessAt: twentyDaysAgo,
      };
    }

    await db.collection('users').doc(userId).set({
      socialEcosystemSyncMeta: syncMeta,
    }, { merge: true }); // merge: true = no borra otros campos

    console.log(`✅ socialEcosystemSyncMeta actualizado a: ${twentyDaysAgo.toISOString()}\n`);

    // ======================== PASO 3: EJECUTAR SINCRONIZACIÓN ========================
    console.log('📋 PASO 3: Ejecutando sincronización...');
    console.log(`   POST ${API_BASE}/sync/user/${userId}\n`);

    const response = await axios.post(`${API_BASE}/sync/user/${userId}`);
    const result = response.data;

    console.log('✅ Sincronización completada\n');
    console.log('Resultado:');
    console.log(JSON.stringify(result, null, 2));

    // ======================== PASO 4: VERIFICAR RESULTADOS ========================
    console.log('\n📋 PASO 4: Verificando resultados en Firestore...\n');

    // Obtener usuario actualizado
    const updatedUserDoc = await db.collection('users').doc(userId).get();
    const updatedData = updatedUserDoc.data();

    const lastSyncVal = updatedData.lastSocialEcosystemSync;
    const lastSyncDate =
      lastSyncVal?.toDate?.() || (lastSyncVal instanceof Date ? lastSyncVal : null);

    console.log('✅ Usuario actualizado:');
    console.log(`   lastSocialEcosystemSync: ${lastSyncDate?.toISOString?.() || 'null'}`);
    console.log(`   Redes sociales: ${updatedData.socialEcosystem?.length || 0}`);

    if (updatedData.socialEcosystem && updatedData.socialEcosystem.length > 0) {
      updatedData.socialEcosystem.forEach((net, idx) => {
        if (net.platform) {
          console.log(`     [${idx}] ${net.platform}: ${net.followers || '?'} seguidores`);
        } else {
          const key = Object.keys(net || {})[0] || 'unknown';
          const payload = (net || {})[key] || {};
          console.log(`     [${idx}] ${key}: ${payload.followers || '?'} seguidores`);
        }
      });
    }

    // Obtener historial
    console.log('\n✅ Historial de sincronización:');

    // Nuevo historial: users/{userId}/socialEcosystemHistory/{platform}/syncs/{timestamp}
    const platformsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('socialEcosystemHistory')
      .get();

    if (platformsSnapshot.empty) {
      console.log('   (Sin historial aún)');
    } else {
      const firstPlatform = platformsSnapshot.docs[0].id;
      const historySnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('socialEcosystemHistory')
        .doc(firstPlatform)
        .collection('syncs')
        .orderBy('syncedAt', 'desc')
        .limit(5)
        .get();

      historySnapshot.forEach((doc) => {
        const data = doc.data();
        const ts = data.syncedAt?.toDate?.() || (data.syncedAt instanceof Date ? data.syncedAt : data.syncedAt);
        const followerGuess =
          data.after?.followers ??
          data.after?.followersCount ??
          data.after?.raw?.followers ??
          data.after?.data?.followers;
        console.log(
          `   • ${String(data.platform || firstPlatform).toUpperCase()}: ${followerGuess || '?'} followers @ ${ts?.toISOString?.() || ts}`,
        );
      });
    }

    console.log('\n✅ TEST COMPLETADO EXITOSAMENTE!\n');
    console.log('📊 Próximos pasos:');
    console.log('   1. Revisa Firestore Console → users/{uid}/socialEcosystemHistory/{platform}/syncs');
    console.log('   2. Verifica que se crearon nuevos documentos');
    console.log('   3. Compara con los datos anteriores de Instagram');
    console.log('   4. ¡Listo! El sistema funciona correctamente\n');

  } catch (error) {
    console.error('❌ ERROR:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

runTest();
