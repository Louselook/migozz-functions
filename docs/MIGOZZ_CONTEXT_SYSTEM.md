# 🎯 Sistema de Contexto Inteligente de Migozz

## ¿Qué es?

Un sistema integral que permite a la IA de Migozz **entender y explicar el propósito** de cada campo de registro basado en la **misión y valores de la plataforma**.

---

## 🏗️ Arquitectura del Sistema

### 1. **MigozzContext** (`lib/core/services/ai/migozz_context.dart`)
Clase estática que centraliza toda la información sobre:
- **Descripción de la plataforma** (español e inglés)
- **Contexto de cada campo** con:
  - `purpose`: Propósito del campo
  - `why`: Explicación de por qué se necesita
  - `benefit`: Beneficio para el creador
  - `examples`: Ejemplos reales
  - `security`: Información de seguridad
  - `psychology`: Aspectos psicológicos
  - `research`: Información basada en investigación
  - `brands`: Perspectiva de las marcas/empresas

### 2. **AssistantFunctions** (`lib/core/services/ai/assistant_functions.dart`)
Mejorada con:
- **`_isWhyQuestion()`**: Detecta si el usuario pregunta "why/por qué/para qué"
- **`_evaluateLocation()`**: Ahora detecta preguntas de contexto y devuelve `isWhy: true`
- **`_evaluatePhone()`, `_evaluateVoiceNote()`, etc.**: Todas pueden detectar preguntas "why"

### 3. **GeminiService** (`lib/core/services/ai/gemini_service.dart`)
Orquestador que:
- Verifica si `decision['isWhy'] == true`
- Llama a `MigozzContext.getWhyExplanation()` para obtener la explicación contextual
- Devuelve la explicación sin romper el flujo conversacional
- Re-pregunta automáticamente después de explicar

---

## 💬 Flujo de Conversación Mejorado

### Antes (Sin Contexto)
```
Bot: ¿Es correcta tu ubicación? (Sí/No/Ubicación incorrecta)
User: ¿Por qué necesitan mi ubicación?
Bot: Por favor, selecciona una opción válida: Sí, No, o Ubicación incorrecta. ❌
```

### Ahora (Con Contexto)
```
Bot: ¿Es correcta tu ubicación? (Sí/No/Ubicación incorrecta)
User: ¿Por qué necesitan mi ubicación?
Bot: 
💡 Contexto sobre "Ubicación Geográfica":

¿Por qué?: Las marcas y empresas buscan creadores en su región. 
Tu ubicación permite que te descubran personas interesadas en tus servicios que estén cerca de ti.

✅ Beneficio: Aumenta oportunidades locales. Muchos negocios prefieren trabajar 
con creadores de su zona porque facilita colaboraciones presenciales...

Bot: Ahora sí, ¿es correcta tu ubicación? (Sí/No/Ubicación incorrecta) ✅
```

---

## 🔑 Campos con Contexto Disponible

### Español (ES)
- **fullName**: Identidad personal del creador
- **username**: Identidad digital y buscabilidad
- **location**: Oportunidades locales de marcas
- **phone**: Contacto directo sin perder oportunidades
- **voiceNoteUrl**: Autenticidad y humanización del perfil
- **avatarUrl**: Confiabilidad y profesionalismo
- **socialEcosystem**: Portafolio profesional y prueba de alcance

### English (EN)
Mismo sistema, mensajes traducidos profesionalmente

---

## 📊 Campos del Contexto por Campo

Cada campo tiene:

```dart
'location': {
  'purpose': 'Ubicación Geográfica',
  'why': 'Las marcas y empresas buscan creadores en su región...',
  'benefit': 'Aumenta oportunidades locales...',
  'examples': 'Una agencia en Ciudad de México buscará influencers CDMX...',
  'security': (opcional) 'No compartimos tu número públicamente...',
  'psychology': (opcional) 'La voz humaniza el perfil...',
  'research': (opcional) 'Estudios muestran que perfiles con foto...',
  'brands': (opcional) 'Las marcas SIEMPRE verifican tus redes...',
  'key': (opcional) 'IMPORTANTE: Este es el dato MÁS importante...'
}
```

---

## 🔄 Proceso Técnico Paso a Paso

### 1️⃣ Usuario Pregunta "Why"
```dart
// En chat_input_widget.dart
User: "¿Por qué necesitan mi ubicación?"
```

### 2️⃣ GeminiService Recibe el Mensaje
```dart
// En gemini_service.dart → sendMessage()
final decision = AssistantFunctions.evaluateUserResponse(
  "¿Por qué necesitan mi ubicación?",
  'location',
  registerCubit,
);
```

### 3️⃣ AssistantFunctions Detecta el "Why"
```dart
// En assistant_functions.dart → _evaluateLocation()
final isWhy = _isWhyQuestion(normalized, isSpanish);
if (isWhy) {
  return {
    "step": "regProgress.location",
    "valid": false,
    "isWhy": true,
    "field": "location",
  };
}
```

### 4️⃣ GeminiService Maneja la Explicación
```dart
// En gemini_service.dart → sendMessage()
if (decision['isWhy'] == true) {
  final explanation = MigozzContext.getWhyExplanation('location', 'es');
  
  return {
    "text": explanation,
    "options": [],
    "step": 'regProgress.location',
    "keepTalk": true,
    "explainAndRepeat": true,
  };
}
```

### 5️⃣ IAChatScreen Re-pregunta
```dart
// En ia_chat_screen.dart
if (decision['explainAndRepeat'] == true) {
  // El bot vuelve a preguntar automáticamente después de explicar
  // keepTalk: true mantiene la conversación en el mismo paso
}
```

---

## 🎨 Tipos de Explicación

### Explicación Corta (`getShortExplanation`)
Para respuestas rápidas:
```
Tu nombre completo es la base de tu identidad profesional en Migozz. 
Es lo que otros creadores y potenciales clientes verán primero.
✅ Permite que la gente te conozca por tu nombre real y construya confianza contigo.
```

### Explicación Completa (`getWhyExplanation`)
Para contexto profundo:
```
💡 Contexto sobre "Ubicación Geográfica":

¿Por qué?: [explicación detallada]
✅ Beneficio: [beneficios específicos]
📍 Ejemplos: [casos de uso reales]
🏢 Para Marcas: [perspectiva del lado de los negocios]
🔑 IMPORTANTE: [dato crítico si aplica]
```

---

## 🌍 Soporte Multi-idioma

El sistema detecta idioma automáticamente:

```dart
// En MigozzContext
static String getWhyExplanation(String fieldKey, String language) {
  final isSpanish = language.toLowerCase().contains('español') || language == 'es';
  final contextMap = isSpanish ? fieldContextES : fieldContextEN;
  // ...
}
```

**Idiomas soportados:**
- ✅ Español (ES, español, es-ES, etc.)
- ✅ English (EN, english, en-US, etc.)

---

## 🚀 Cómo Expandir el Sistema

### Agregar un Nuevo Campo

1. **En `migozz_context.dart`**, agrega al mapa `fieldContextES` y `fieldContextEN`:

```dart
'newField': {
  'purpose': 'Propósito del Campo',
  'why': 'Explicación de por qué...',
  'benefit': 'Beneficio para el creador...',
  'examples': '(opcional) Ejemplos...',
  'security': '(opcional) Info de seguridad...',
  'psychology': '(opcional) Aspectos psicológicos...',
  'research': '(opcional) Info de investigación...',
  'brands': '(opcional) Perspectiva de marcas...',
  'key': '(opcional) Dato crítico...'
}
```

2. **En `assistant_functions.dart`**, en la función `_evaluateNewField()`, detecta `isWhy`:

```dart
static Map<String, dynamic> _evaluateNewField(
  String normalized,
  String original,
  RegisterCubit cubit,
) {
  final isSpanish = _getIsSpanish(cubit);
  
  // Detectar why
  final isWhy = _isWhyQuestion(normalized, isSpanish);
  if (isWhy) {
    return {
      "step": "regProgress.newField",
      "valid": false,
      "isWhy": true,
      "field": "newField",
    };
  }
  
  // ... resto de la lógica
}
```

3. **¡Listo!** GeminiService manejará automáticamente la explicación.

---

## 🧪 Pruebas

### Caso de Prueba 1: Pregunta Básica
```
User: "¿Por qué necesitan mi nombre completo?"
Expected: Explicación sobre identidad personal
Status: ✅ Funcionando
```

### Caso de Prueba 2: Idioma Diferente
```
User: "Why do you need my phone number?"
Expected: Explicación en inglés
Status: ✅ Funcionando
```

### Caso de Prueba 3: Explicación y Re-pregunta
```
User: "Para qué es la ubicación?"
Bot: [Explicación contextual completa]
Bot: "¿Es correcta tu ubicación?"
Status: ✅ Funcionando
```

---

## 📁 Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `migozz_context.dart` | ✨ NUEVO - Contexto centralizado |
| `assistant_functions.dart` | Added `_isWhyQuestion()`, updated `_evaluateLocation()` |
| `gemini_service.dart` | Added import, new `isWhy` handling, updated `_whyExplanation()` |

---

## 💡 Beneficios del Sistema

| Beneficio | Descripción |
|-----------|-----------|
| **Transparencia** | Usuarios entienden por qué se pide cada dato |
| **Confianza** | Explicaciones contextuales aumentan credibilidad |
| **UX Mejorado** | No hay frustración con errores, sino explicaciones útiles |
| **Educación** | Usuarios aprenden sobre Migozz mientras se registran |
| **Conversacional** | IA responde como una persona real que entiende el negocio |
| **Escalable** | Fácil agregar nuevos campos y explicaciones |
| **Multi-idioma** | Funciona en español e inglés sin fricción |

---

## 🎯 Próximas Mejoras

- [ ] Agregar explicaciones dinámicas basadas en datos del usuario
- [ ] Sistema de "preguntas frecuentes" contextual
- [ ] Analytics de qué campos generan más preguntas
- [ ] Feedback del usuario sobre claridad de explicaciones
- [ ] Explicaciones visuales (emojis, iconos) per campo

---

## 📞 Contacto / Soporte

Si necesitas agregar contexto a un nuevo campo o modificar explicaciones existentes, asegúrate de:

1. ✅ Actualizar `MigozzContext` con el contexto correcto
2. ✅ Agregar detección de `isWhy` en la función de evaluación
3. ✅ Probar en ambos idiomas
4. ✅ Verificar que flujo se mantiene coherente

---

**Sistema creado: 2025**  
**Versión: 1.0**  
**Status: ✅ Activo y Funcionando**
