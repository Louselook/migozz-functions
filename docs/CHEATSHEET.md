# 📋 Cheat Sheet - Copiar/Pegar

> **Para:** Devs que necesitan hacer cambios AHORA (sin leer 30 minutos)

---

## 🎯 Tareas Comunes

### 1️⃣ Cambiar una Explicación de Campo

**Ubicación del código:**
```
File: lib/core/services/ai/migozz_context.dart
```

**Busca esto (Ctrl+F):**
```dart
'location': {
    'purpose': 'Ubicación Geográfica',
    'why': 'Las marcas buscan creadores en su región...',
```

**Reemplaza con tu texto:**
```dart
'location': {
    'purpose': 'Tu nuevo propósito',
    'why': 'Tu nueva explicación...',
```

**Haz CTRL+S → Flutter Hot Reload ✅**

---

### 2️⃣ Agregar un Nuevo Campo

**Paso 1: En `migozz_context.dart` (~línea 60)**

Copia esto (reemplaza `newfield` con tu nombre):
```dart
'newfield': {
  'purpose': 'Propósito del campo',
  'why': 'Explicación de por qué lo necesitamos',
  'benefit': 'Beneficio para el creador',
  'examples': 'Ejemplos (opcional)',
  'security': 'Info de seguridad (opcional)',
  'psychology': 'Principio psicológico (opcional)',
  'research': 'Datos de investigación (opcional)',
  'brands': 'Ejemplo de marca (opcional)',
},
```

**Paso 2: En AMBOS mapas**
- Copia en `fieldContextES` (español)
- Copia en `fieldContextEN` (inglés)

**Paso 3: En `assistant_functions.dart` (~línea 650)**

Busca `_isWhyQuestion()` y verifica que el patrón aplique a tu campo.
Si tu campo es especial, agrega lógica aquí.

**Paso 4: En `gemini_service.dart`**

Busca `if (decision['isWhy'] == true)` y asegúrate que tu `fieldKey` es consistente.

**Tiempo total:** ~5 minutos ✅

---

### 3️⃣ Cambiar Patrones de Detección "¿Por qué?"

**Ubicación:**
```
File: lib/core/services/ai/assistant_functions.dart
Línea: ~650
```

**Función:**
```dart
bool _isWhyQuestion(String normalized, bool isSpanish) {
  if (isSpanish) {
    return normalized.contains('por qué') ||
           normalized.contains('para qué') ||
           // AGREGA AQUÍ
           normalized.contains('tu nuevo patrón');
  }
  return normalized.contains('why') ||
         normalized.contains('why do') ||
         // AGREGA AQUÍ
         normalized.contains('your new pattern');
}
```

**Guarda → Hot Reload ✅**

---

### 4️⃣ Cambiar Idioma por Defecto

**Ubicación:**
```
File: lib/core/services/ai/gemini_service.dart
Línea: ~253 (busca isWhy == true)
```

**Busca:**
```dart
final explanation = MigozzContext.getWhyExplanation(
  fieldKey, 
  isSpanish ? 'es' : 'en'  // ← AQUÍ
);
```

**Cambia a tu idioma:**
```dart
final explanation = MigozzContext.getWhyExplanation(
  fieldKey, 
  'es'  // Siempre español
);
```

---

### 5️⃣ Desactivar Sistema "¿Por qué?" Temporalmente

**En `gemini_service.dart` línea ~253:**

**De esto:**
```dart
if (decision['isWhy'] == true) {
  final explanation = MigozzContext.getWhyExplanation(fieldKey, isSpanish ? 'es' : 'en');
  return { "text": explanation, ... };
}
```

**A esto (comentado):**
```dart
// if (decision['isWhy'] == true) {
//   final explanation = MigozzContext.getWhyExplanation(fieldKey, isSpanish ? 'es' : 'en');
//   return { "text": explanation, ... };
// }
```

**Guarda → El sistema ignora "¿Por qué?" ✅**

---

### 6️⃣ Ver Exactamente Qué Ve el Usuario

**Ve al documento:**
```
File: EXPLANATION_EXAMPLES.md
```

**Busca tu campo:**
```markdown
## 📍 UBICACIÓN

### Usuario pregunta: "¿Por qué necesitan saber mi ubicación?"

### Respuesta del Sistema:

[VES EXACTAMENTE LO QUE EL USUARIO RECIBE]
```

---

### 7️⃣ Entender el Flujo en 30 Segundos

```
Usuario: "¿Por qué?"
    ↓ (va a evaluador específico del campo)
_evaluateX() → _isWhyQuestion() detects true
    ↓
returns { "isWhy": true }
    ↓ (va a GeminiService)
checks decision['isWhy']
    ↓
calls MigozzContext.getWhyExplanation()
    ↓
returns explicación formateada
    ↓
IAChatScreen muestra mensaje
Usuario ve contexto ✅
```

---

## 🔍 Búsquedas Rápidas

**Para encontrar...**

| Lo que busco | Busco en VS Code | Archivo |
|---|---|---|
| Explicación ubicación | `'location': {` | migozz_context.dart |
| Detección "¿por qué?" | `_isWhyQuestion` | assistant_functions.dart |
| Manejo de isWhy | `decision['isWhy']` | gemini_service.dart |
| Todas las explicaciones | `fieldContextES` | migozz_context.dart |
| Patrón inglés | `contains('why')` | assistant_functions.dart |
| Dónde se muestra | `getWhyExplanation` | gemini_service.dart |

---

## 🛠️ Debugging Rápido

### ❌ "El campo no detecta ¿por qué?"

1. Busca `_isWhyQuestion` en `assistant_functions.dart`
2. Asegúrate que el patrón español/inglés está ahí
3. Verifica que tu `_evaluateX()` LLAMA a esta función PRIMERO

### ❌ "La explicación está vacía"

1. Busca en `migozz_context.dart` tu campo
2. Verifica que existe en AMBOS: `fieldContextES` Y `fieldContextEN`
3. Asegúrate que la clave ('location', 'fullName', etc) es EXACTA

### ❌ "Sigue preguntando después de explicación"

1. Verifica `keepTalk: true` en `gemini_service.dart` línea ~270
2. Debe estar en el return del isWhy handler

### ❌ "No está en el idioma correcto"

1. Busca `isSpanish ? 'es' : 'en'` en `gemini_service.dart`
2. Verifica que `isSpanish` se calcula correctamente arriba
3. Mira que el idioma sea consistente con `registerCubit.state.language`

---

## 📂 Archivos Que REALMENTE Importan

```
CAMBIOS DIARIOS? →
  lib/core/services/ai/migozz_context.dart
  
ENTENDER FLUJO? →
  lib/core/services/ai/gemini_service.dart
  
AGREGAR CAMPO? →
  lib/core/services/ai/assistant_functions.dart
  
VER EJEMPLOS? →
  EXPLANATION_EXAMPLES.md
```

---

## ⚡ Una Línea de Cambios Comunes

```bash
# CAMBIO: Editar explicación de ubicación
# ARCHIVO: migozz_context.dart
# LÍNEA: ~80
# BUSCA: 'location': { 'why': 'Las marcas buscan...'
# REEMPLAZA: 'location': { 'why': 'TU NUEVO TEXTO'

# CAMBIO: Agregar nuevo patrón "¿por qué?"
# ARCHIVO: assistant_functions.dart
# LÍNEA: ~656
# AÑADE: normalized.contains('tu patrón')

# CAMBIO: Desactivar "¿por qué?" temporalmente
# ARCHIVO: gemini_service.dart
# LÍNEA: ~253
# COMENTA: if (decision['isWhy'] == true) {
```

---

## 📱 Para Pruebas en Device/Emulador

```bash
# 1. Guarda cambios (Ctrl+S)
# 2. En emulador/device, presiona 'r' en terminal:
r   # Hot reload

# 3. Ve a registration y pregunta:
"¿Por qué?" (en el campo que cambiaste)

# 4. Deberías ver tu explicación nueva ✅
```

---

## ✅ Checklist Antes de Commit

```
□ Cambié ambas versiones (ES y EN) si es bilingüe
□ Ejecuté hot reload
□ Probé en emulador/device
□ No hay errores de compilación (flutter analyze)
□ El flujo completo funciona (pregunta → respuesta)
□ Guardé los cambios
```

---

## 🎯 Si Algo No Funciona

**Paso 1:** Ejecuta en terminal:
```bash
flutter clean
flutter pub get
flutter run
```

**Paso 2:** Abre VS Code y busca tu campo con Ctrl+F

**Paso 3:** Si ves rojo (error), probablemente:
- Falta una coma
- Paréntesis desbalanceado
- Referencia a campo que no existe

**Paso 4:** Mira el mensaje de error rojo abajo de VS Code

**Paso 5:** Vuelve a estos docs y busca la sección del problema

---

## 📞 Resumen de Archivos Modificables

| Archivo | Qué puedo cambiar | Frecuencia |
|---|---|---|
| `migozz_context.dart` | Explicaciones | Diaria |
| `assistant_functions.dart` | Patrones de detección | Semanal |
| `gemini_service.dart` | Lógica de flujo | Mensual |

---

## 🚀 TL;DR - La Forma Más Rápida

```
QUIERO CAMBIAR UNA EXPLICACIÓN:
  1. Abre: lib/core/services/ai/migozz_context.dart
  2. Ctrl+F: 'nombredelcampo'
  3. Edita el texto en 'why'
  4. Ctrl+S
  5. Presiona 'r' en terminal
  6. ✅ Listo

TIEMPO: 1 minuto
```

---

**Última actualización:** 2025  
**Para:** Devs en apuro  
**Disclamer:** Estos son fragmentos. Ve archivos completos para contexto total.
