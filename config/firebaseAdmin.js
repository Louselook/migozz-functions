/**
 * Firebase Admin SDK Initialization
 * 
 * Inicializa Firebase Admin para:
 * - Acceder a Firestore
 * - Autenticar con service account
 * - Realizar operaciones del lado del servidor
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Ruta al archivo de credenciales
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
  path.join(__dirname, '..', 'serviceAccountKey.json');

// Verificar si el archivo existe
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.warn(`⚠️  Firebase credential file not found at: ${SERVICE_ACCOUNT_PATH}`);
  console.warn(`Set GOOGLE_APPLICATION_CREDENTIALS env variable or place serviceAccountKey.json in project root`);
}

// Inicializar solo si no está ya inicializado
if (!admin.apps.length) {
  try {
    if (fs.existsSync(SERVICE_ACCOUNT_PATH)) {
      const serviceAccount = require(SERVICE_ACCOUNT_PATH);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id,
      });
      console.log('✅ Firebase Admin SDK initialized with service account');
    } else {
      // En Cloud Run, usar Application Default Credentials
      admin.initializeApp({
        projectId: process.env.GOOGLE_CLOUD_PROJECT || 'migozz-e2a21',
      });
      console.log('✅ Firebase Admin SDK initialized with Application Default Credentials');
    }
  } catch (error) {
    console.error('❌ Error initializing Firebase Admin SDK:', error.message);
    throw error;
  }
}

// Exportar Firestore
const db = admin.firestore();

// Evita errores al escribir campos undefined (muy común en scrapers)
// Aun así, el servicio también sanitiza los objetos antes de guardar.
db.settings({ ignoreUndefinedProperties: true });

module.exports = {
  admin,
  db,
};
