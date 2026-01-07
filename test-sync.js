#!/usr/bin/env node
/**
 * Script de Testing para validar el sistema de sincronización
 * 
 * Uso:
 * node test-sync.js
 * 
 * Qué hace:
 * 1. Conecta a Firestore
 * 2. Actualiza lastSocialEcosystemSync a hace 20 días (fuerza sincronización)
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

    // ======================== PASO 2: ACTUALIZAR TIMESTAMP ========================
    console.log('📋 PASO 2: Crear/Actualizar lastSocialEcosystemSync a hace 20 días...');

    const twentyDaysAgo = new Date();
    twentyDaysAgo.setDate(twentyDaysAgo.getDate() - 20);

    // Si el campo no existe, lo crea; si existe, lo actualiza
    await db.collection('users').doc(userId).set({
      lastSocialEcosystemSync: twentyDaysAgo,
      socialEcosystemAddedDates: userData.socialEcosystemAddedDates || {},
    }, { merge: true }); // merge: true = no borra otros campos

    console.log(`✅ Campo creado/actualizado a: ${twentyDaysAgo.toISOString()}\n`);

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

    console.log('✅ Usuario actualizado:');
    console.log(`   lastSocialEcosystemSync: ${updatedData.lastSocialEcosystemSync?.toDate().toISOString() || 'null'}`);
    console.log(`   Redes sociales: ${updatedData.socialEcosystem?.length || 0}`);

    if (updatedData.socialEcosystem && updatedData.socialEcosystem.length > 0) {
      updatedData.socialEcosystem.forEach((net, idx) => {
        console.log(`     [${idx}] ${net.platform}: ${net.followers || '?'} seguidores`);
      });
    }

    // Obtener historial
    console.log('\n✅ Historial de sincronización:');
    
    const historySnapshot = await db
      .collection('socialEcosystemHistory')
      .doc(userId)
      .collection('syncs')
      .orderBy('syncedAt', 'desc')
      .limit(5)
      .get();

    if (!historySnapshot.empty) {
      historySnapshot.forEach((doc) => {
        const data = doc.data();
        console.log(`   • ${data.platform.toUpperCase()}: ${data.data.followers || '?'} followers @ ${data.syncedAt.toDate().toISOString()}`);
      });
    } else {
      console.log('   (Sin historial aún)');
    }

    console.log('\n✅ TEST COMPLETADO EXITOSAMENTE!\n');
    console.log('📊 Próximos pasos:');
    console.log('   1. Revisa Firestore Console → socialEcosystemHistory');
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
