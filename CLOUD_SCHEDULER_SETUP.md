# Cloud Scheduler Setup - Social Ecosystem Sync

Este documento explica cómo configurar **Google Cloud Scheduler** para sincronizar automáticamente los datos de redes sociales de todos los usuarios cada 15 días.

---

## 📋 Requisitos

- Proyecto de Google Cloud con Cloud Run habilitado
- Cloud Scheduler API habilitada
- Cloud Run service account con permisos suficientes
- URL de Cloud Run accesible

---

## 🔧 Configuración en Cloud Console

### Paso 1: Ir a Cloud Scheduler

1. En [Google Cloud Console](https://console.cloud.google.com)
2. Navega a **Cloud Scheduler** (búsqueda en la barra superior)
3. Si es la primera vez, click en **"Habilitar API"**

### Paso 2: Crear un Job

1. Click en **"Crear trabajo"**
2. Completa los campos:

```
Nombre:                    sync-social-ecosystem
Región:                    us-central1  (o tu región preferida)
Tipo de ejecución:         Cron
```

### Paso 3: Configurar la Frecuencia

En el campo **"Frecuencia (formato cron)"**, pon:

```
0 0 * * *
```

**Explicación:**
- `0` = minuto 0
- `0` = hora 0 (medianoche UTC)
- `*` = cualquier día del mes
- `*` = cualquier mes
- `*` = cualquier día de la semana

**Resultado:** Se ejecuta **todos los días a las 12:00 AM UTC**

> ⏰ Si prefieres otra hora, usa:
> - `0 8 * * *` = 8:00 AM UTC
> - `0 20 * * *` = 8:00 PM UTC
> - `0 0 * * 0` = Dominical a las 12:00 AM UTC

### Paso 4: Configurar el Destino HTTP

```
Tipo de destino:           HTTPS
URL:                       https://migozz-functions-[PROJECT_ID].[REGION].run.app/sync/all-users
Método HTTP:               POST
```

**Ejemplo real:**
```
https://migozz-functions-895592952324.northamerica-northeast2.run.app/sync/all-users
```

### Paso 5: Configurar Autenticación

Selecciona **"Agregar encabezado OIDC"**:

```
Token de identidad OIDC:   Seleccionar cuenta de servicio
Cuenta de servicio:        [Tu Cloud Run service account]
Audiencia:                 https://migozz-functions-895592952324.northamerica-northeast2.run.app
```

> ℹ️ Cloud Run requiere autenticación para endpoints POST

### Paso 6: Parámetros Opcionales

En "Encabezados HTTP" (opcional), agrega:

```
Content-Type:             application/json
```

En "Cuerpo de la solicitud" (opcional, déjalo vacío):

```
(dejar vacío)
```

### Paso 7: Crear el Job

Click en **"Crear"**

---

## ✅ Verificar que Funciona

### Opción 1: Ejecutar Manualmente desde Cloud Console

1. En la lista de trabajos, encuentra `sync-social-ecosystem`
2. Click en los 3 puntitos (⋮)
3. Selecciona **"Ejecutar ahora"**
4. Verás un ícono de reloj mientras se ejecuta
5. Haz click en el job para ver los logs

### Opción 2: Ver Logs en Cloud Logging

1. Ve a **Cloud Logging** (búsqueda en la barra)
2. Filtra por:
   - **Resource type:** `Cloud Run Revision`
   - **Log:** busca "SyncService"
3. Verás los logs de la sincronización

### Opción 3: Probar Localmente

Desde tu terminal:

```bash
# Ejecutar endpoint manualmente
curl -X POST \
  https://migozz-functions-895592952324.northamerica-northeast2.run.app/sync/user/{USER_ID}

# O usar el script de testing
node test-sync.js
```

---

## 📊 Monitoreo

### Ver Ejecuciones Recientes

1. En Cloud Scheduler, click en `sync-social-ecosystem`
2. Ve a la pestaña **"Ejecuciones"**
3. Verás:
   - ✅ `SUCCESS` - Sincronización completada
   - ❌ `FAILED` - Error durante la ejecución
   - ⏱️ Duración de cada ejecución

### Configurar Alertas

1. Ve a **Cloud Monitoring** → **Alertas**
2. Click en **"Crear política"**
3. Selecciona **métrica:** `cloudfunctions.googleapis.com/execution_times`
4. Establece **umbral:** 60 segundos (si tarda más, alert)
5. Agregar notificación (email, Slack, etc.)

---

## 🔍 Logs y Debugging

### Ver Logs Detallados

```bash
# En Cloud Shell o tu terminal (con gcloud CLI):
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=migozz-functions" \
  --limit 50 \
  --format json
```

### Logs Esperados

Cuando la sincronización se ejecuta, deberías ver:

```
🔄 [SyncService] SINCRONIZACIÓN GLOBAL - Buscando usuarios que necesitan actualización...
📊 Total de usuarios: 5
▶️  Sincronizando usuario: user_123
   🌐 Scrapeando facebook: juan.perez...
   ✅ facebook: 1234 followers
   📝 Historial guardado para facebook
✅ SINCRONIZACIÓN GLOBAL COMPLETADA
   Total de usuarios procesados: 5
   Exitosas: 4
   Fallidas: 0
```

---

## ⚙️ Solucionar Problemas

### Error: "Authentication required"

**Causa:** Cloud Run necesita autenticación
**Solución:**
1. Ve a Cloud Run → selecciona tu servicio
2. Ve a **Seguridad** → **Autenticación**
3. Asegúrate de que **"Requiere autenticación"** esté activado
4. En Cloud Scheduler, configura "Token OIDC" correctamente

### Error: "Service not found"

**Causa:** URL incorrecta
**Solución:**
1. Ve a Cloud Run → busca tu servicio
2. Copia la URL exacta desde "Trigger"
3. Agrega `/sync/all-users` al final
4. Actualiza en Cloud Scheduler

### Error: "Timeout (>600s)"

**Causa:** La sincronización tarda más de 10 minutos
**Solución:**
1. Aumentar el **timeout** en Cloud Scheduler (máx 1800s)
2. Limitar el número de usuarios sincronizados
3. Optimizar los scrapers (reducir timeouts de Puppeteer)

### No se ejecuta

**Causa:** Job deshabilitado o con errores persistentes
**Solución:**
1. Ve a Cloud Scheduler → selecciona el job
2. Verifica que esté **habilitado** (toggle azul)
3. En "Ejecuciones", ve si hay errores recientes
4. Prueba "Ejecutar ahora" manualmente

---

## 📈 Estadísticas y Historial

### Obtener Estado del Servicio

```bash
curl https://migozz-functions-895592952324.northamerica-northeast2.run.app/sync/status
```

**Respuesta esperada:**

```json
{
  "status": "success",
  "data": {
    "status": "operational",
    "totalUsers": 5,
    "usersSynced": 5,
    "usersNeedSync": 0,
    "averageLastSyncDays": "3.2"
  },
  "timestamp": "2026-01-07T12:00:00.000Z"
}
```

---

## 🔐 Seguridad

### Mejores Prácticas

1. **Usa OIDC Token** - No confíes en API Keys públicas
2. **Limita el acceso** - Solo Cloud Scheduler puede llamar `/sync/all-users`
3. **Monitorea logs** - Revisa regularmente qué se está ejecutando
4. **Alertas** - Configura notificaciones para errores

### Configurar Autenticación en Cloud Run

```bash
# Permitir que SOLO Cloud Scheduler acceda a /sync/all-users
gcloud run services add-iam-policy-binding migozz-functions \
  --member=serviceAccount:YOUR-CLOUD-SCHEDULER-SA@PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region=northamerica-northeast2
```

---

## 📝 Resumen

| Configuración | Valor |
|---------------|-------|
| **Nombre** | `sync-social-ecosystem` |
| **Frecuencia** | `0 0 * * *` (diariamente a las 12 AM UTC) |
| **URL** | `/sync/all-users` en Cloud Run |
| **Método** | `POST` |
| **Autenticación** | OIDC Token |
| **Timeout** | 600s (10 minutos) |

---

## 🎯 Próximos Pasos

1. ✅ Crear el job en Cloud Scheduler
2. ✅ Configurar autenticación OIDC
3. ✅ Ejecutar manualmente para verificar
4. ✅ Monitorear logs durante 24h
5. ✅ Configurar alertas
6. ✅ Validar que Firestore se actualiza correctamente

---

## 📞 Soporte

Si algo no funciona:
1. Revisa los logs en Cloud Logging
2. Ejecuta manualmente el endpoint desde tu terminal
3. Verifica que Firebase Admin SDK está inicializado
4. Asegúrate de que el `serviceAccountKey.json` está en lugar correcto
