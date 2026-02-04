---
description: Guía completa para desplegar la aplicación Flutter en todas las plataformas
---

# Guía de Despliegue - MigozzApp Flutter

Esta guía te ayudará a desplegar tu aplicación Flutter en diferentes plataformas.

## Pre-requisitos Generales

Antes de desplegar, asegúrate de:

1. **Verificar la versión actual**

   ```bash
   # La versión actual en pubspec.yaml es: 1.2.8+2
   # Formato: version: [major].[minor].[patch]+[build_number]
   ```

2. **Actualizar la versión** (si es necesario)
   - Edita `pubspec.yaml` y actualiza la línea `version:`
   - Ejemplo: `1.2.9+3` (incrementa el número de versión y build)

3. **Limpiar el proyecto**

   ```bash
   flutter clean
   flutter pub get
   ```

4. **Verificar que no hay errores**

   ```bash
   flutter analyze
   ```

5. **Configurar variables de entorno**
   - Asegúrate de que el archivo `.env` esté configurado correctamente
   - NO incluyas el `.env` en el control de versiones

---

## 📱 DESPLIEGUE ANDROID

### Opción 1: APK (Para distribución directa)

1. **Construir APK de producción**

   ```bash
   flutter build apk --release
   ```

2. **Construir APK dividido por ABI (recomendado - archivos más pequeños)**

   ```bash
   flutter build apk --split-per-abi --release
   ```

3. **Ubicación de los archivos generados**
   - APK universal: `build/app/outputs/flutter-apk/app-release.apk`
   - APKs divididos: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`, etc.

### Opción 2: App Bundle (Para Google Play Store)

1. **Configurar firma de la aplicación**

   a. Crear un keystore (solo la primera vez):

   ```bash
   keytool -genkey -v -keystore d:/Freelance/MigozzApp/android/app/migozz-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias migozz
   ```

   b. Crear archivo `android/key.properties`:

   ```properties
   storePassword=TU_PASSWORD_AQUI
   keyPassword=TU_PASSWORD_AQUI
   keyAlias=migozz
   storeFile=migozz-keystore.jks
   ```

   c. Asegúrate de que `android/app/build.gradle` esté configurado para usar el keystore:

   ```gradle
   // Verifica que tenga la configuración de signingConfigs
   ```

2. **Construir App Bundle**

   ```bash
   flutter build appbundle --release
   ```

3. **Ubicación del archivo generado**
   - `build/app/outputs/bundle/release/app-release.aab`

4. **Subir a Google Play Console**
   - Ve a https://play.google.com/console
   - Selecciona tu aplicación
   - Ve a "Producción" > "Crear nueva versión"
   - Sube el archivo `.aab`
   - Completa la información de la versión
   - Envía para revisión

---

## 🍎 DESPLIEGUE iOS

**Nota:** Necesitas una Mac con Xcode instalado y una cuenta de Apple Developer.

### Preparación

1. **Abrir el proyecto en Xcode**

   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configurar firma y capacidades**
   - En Xcode, selecciona el proyecto "Runner"
   - Ve a "Signing & Capabilities"
   - Selecciona tu equipo de desarrollo
   - Verifica el Bundle Identifier

3. **Configurar versión**
   - En Xcode, verifica que la versión coincida con `pubspec.yaml`
   - Version: 1.2.8
   - Build: 2

### Construcción

1. **Construir para iOS**

   ```bash
   flutter build ios --release
   ```

2. **Crear archivo IPA (para distribución)**

   a. En Xcode:
   - Product > Archive
   - Espera a que se complete el archivo
   - Cuando termine, se abrirá el Organizer

   b. En el Organizer:
   - Selecciona el archivo más reciente
   - Click en "Distribute App"
   - Selecciona el método de distribución:
     - **App Store Connect**: Para publicar en App Store
     - **Ad Hoc**: Para distribución limitada
     - **Enterprise**: Para distribución empresarial
     - **Development**: Para pruebas internas

3. **Subir a App Store Connect**
   - Sigue el asistente de Xcode para subir a App Store Connect
   - O usa Application Loader / Transporter

4. **Completar en App Store Connect**
   - Ve a https://appstoreconnect.apple.com
   - Selecciona tu aplicación
   - Completa la información de la versión
   - Agrega capturas de pantalla
   - Envía para revisión

---

## 🌐 DESPLIEGUE WEB

### Construcción

1. **Construir para web**

   ```bash
   flutter build web --release
   ```

2. **Optimizar para producción (opcional)**

   ```bash
   flutter build web --release --web-renderer canvaskit
   # O para mejor compatibilidad:
   flutter build web --release --web-renderer html
   # O para auto-detectar:
   flutter build web --release --web-renderer auto
   ```

3. **Ubicación de los archivos generados**
   - `build/web/`

### Opciones de Hosting

#### Opción 1: Firebase Hosting (Recomendado - ya usas Firebase)

1. **Instalar Firebase CLI** (si no lo tienes)

   ```bash
   npm install -g firebase-tools
   ```

2. **Iniciar sesión en Firebase**

   ```bash
   firebase login
   ```

3. **Inicializar Firebase Hosting** (solo la primera vez)

   ```bash
   firebase init hosting
   ```

   - Selecciona tu proyecto Firebase
   - Public directory: `build/web`
   - Configure as single-page app: `Yes`
   - Set up automatic builds: `No`

4. **Desplegar**

   ```bash
   firebase deploy --only hosting
   ```

5. **Ver tu sitio**
   - URL: `https://TU_PROYECTO.web.app`

#### Opción 2: GitHub Pages

1. **Construir con base href**

   ```bash
   flutter build web --release --base-href "/MigozzApp/"
   ```

2. **Subir a GitHub**
   - Crea un branch `gh-pages`
   - Copia el contenido de `build/web/` al branch
   - Habilita GitHub Pages en la configuración del repositorio

#### Opción 3: Netlify

1. **Crear archivo `netlify.toml` en la raíz del proyecto**

   ```toml
   [build]
     publish = "build/web"
     command = "flutter build web --release"

   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

2. **Conectar repositorio en Netlify**
   - Ve a https://app.netlify.com
   - "New site from Git"
   - Conecta tu repositorio
   - Netlify detectará automáticamente la configuración

#### Opción 4: Vercel

1. **Instalar Vercel CLI**

   ```bash
   npm install -g vercel
   ```

2. **Desplegar**
   ```bash
   vercel --prod
   ```

---

## 🔧 Configuraciones Adicionales

### Configurar CORS para Firebase (si es necesario)

Si tu app web necesita acceder a Firebase Storage, configura CORS:

1. **Crear archivo `cors.json`**

   ```json
   [
     {
       "origin": ["*"],
       "method": ["GET"],
       "maxAgeSeconds": 3600
     }
   ]
   ```

2. **Aplicar configuración**
   ```bash
   gsutil cors set cors.json gs://TU_BUCKET.appspot.com
   ```

### Configurar Firebase para Web

Asegúrate de que `web/index.html` tenga la configuración correcta de Firebase.

---

## 📋 Checklist Pre-Despliegue

- [ ] Actualizar versión en `pubspec.yaml`
- [ ] Probar en modo release localmente
- [ ] Verificar que `.env` esté configurado correctamente
- [ ] Actualizar changelog/notas de versión
- [ ] Probar funcionalidades críticas
- [ ] Verificar permisos (cámara, ubicación, etc.)
- [ ] Revisar configuración de Firebase
- [ ] Verificar iconos y splash screen
- [ ] Probar en diferentes dispositivos/navegadores
- [ ] Verificar deep links y dynamic links
- [ ] Revisar configuración de notificaciones push

---

## 🚀 Comandos Rápidos

### Desarrollo

```bash
# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release

# Ejecutar en web
flutter run -d chrome

# Ejecutar en dispositivo específico
flutter run -d <device_id>
```

### Testing

```bash
# Listar dispositivos
flutter devices

# Ejecutar tests
flutter test

# Analizar código
flutter analyze
```

### Construcción

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 📱 Distribución Beta

### Android - Google Play Internal Testing

1. En Google Play Console, ve a "Testing" > "Internal testing"
2. Crea una nueva versión
3. Sube el `.aab`
4. Agrega testers por email

### iOS - TestFlight

1. Sube el build a App Store Connect
2. Ve a "TestFlight"
3. Agrega testers internos o externos
4. Los testers recibirán un email para descargar la app

### Web - Preview Channels (Firebase)

```bash
# Crear un preview channel
firebase hosting:channel:deploy NOMBRE_CANAL

# Ver preview
# URL: https://TU_PROYECTO--NOMBRE_CANAL.web.app
```

---

## 🔍 Solución de Problemas Comunes

### Error: "Gradle build failed"

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "CocoaPods not installed" (iOS)

```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

### Error: "Firebase configuration not found"

- Verifica que `google-services.json` (Android) esté en `android/app/`
- Verifica que `GoogleService-Info.plist` (iOS) esté en `ios/Runner/`
- Verifica que la configuración web esté en `web/index.html`

### App muy grande

```bash
# Analizar tamaño del app
flutter build apk --analyze-size
flutter build appbundle --analyze-size

# Reducir tamaño
flutter build apk --split-per-abi --release
```

---

## 📚 Recursos Adicionales

- [Documentación oficial de Flutter - Deployment](https://docs.flutter.dev/deployment)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Firebase Console](https://console.firebase.google.com)
