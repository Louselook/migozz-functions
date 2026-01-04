# 🔧 Guía Técnica: Extender el Sistema de Contexto

Para desarrolladores que quieran agregar más campos o mejoras al sistema.

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INPUT: "Por qué?"                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │   GeminiService       │
          │   sendMessage()       │
          └─────────┬─────────────┘
                    │
                    ▼
     ┌──────────────────────────────────┐
     │  AssistantFunctions              │
     │  evaluateUserResponse()          │
     └──────────┬───────────────────────┘
                │
                ▼
   ┌────────────────────────────────┐
   │  _evaluateLocationValue()      │
   │  detecta: isWhy = true         │
   └──────────┬─────────────────────┘
              │
              ▼
   ┌────────────────────────────────┐
   │  GeminiService sendMessage()   │
   │  verifica: decision['isWhy']   │
   └──────────┬─────────────────────┘
              │
              ▼
   ┌────────────────────────────────┐
   │  MigozzContext                 │
   │  getWhyExplanation()           │
   └──────────┬─────────────────────┘
              │
              ▼
   ┌────────────────────────────────┐
   │  IAChatScreen                  │
   │  muestra explicación           │
   │  re-pregunta                   │
   └────────────────────────────────┘
```

---

## 📝 Paso 1: Agregar Contexto

### Ubicación: `lib/core/services/ai/migozz_context.dart`

### Estructura Completa
```dart
final Map<String, Map<String, String>> fieldContextES = {
  'myNewField': {
    'purpose': 'Propósito del Campo',
    'why': 'Explicación de por qué lo necesitamos. Mínimo 1-2 oraciones.',
    'benefit': 'Beneficio directo para el usuario creador.',
    // Campos opcionales:
    'examples': 'Ejemplo 1: ... Ejemplo 2: ...',
    'security': 'Información sobre privacidad y seguridad',
    'psychology': 'Aspectos psicológicos relevantes',
    'research': 'Datos o investigación que respalda',
    'brands': 'Perspectiva de marcas/empresas',
    'key': 'Información crítica si aplica',
  }
};
```

### Ejemplo Mínimo (2 campos)
```dart
'myNewField': {
  'purpose': 'Mi Propósito',
  'why': 'Porque lo necesitamos para...',
  'benefit': 'Te permite...',
}
```

### Ejemplo Completo (Todos los campos)
```dart
'avatarUrl': {
  'purpose': 'Identidad Visual',
  'why': 'Tu foto hace tu perfil reconocible y confiable. Los creadores con fotos reciben 3x más contactos que sin foto.',
  'benefit': 'Aumenta contactos y oportunidades. Una buena foto profesional comunica que eres serio con tu trabajo.',
  'examples': 'Un perfil con foto profesional vs uno sin foto: el primero recibe 3 veces más mensajes de marcas.',
  'research': 'Estudios muestran que perfiles con foto son vistos como más confiables y profesionales.',
}
```

---

## 🔍 Paso 2: Detectar Preguntas "Why"

### Opción A: Usar función existente `_isWhyQuestion()`

En la función de evaluación correspondiente:

```dart
static Map<String, dynamic> _evaluateMyNewField(
  String normalized,
  String original,
  RegisterCubit cubit, // Si lo necesita
) {
  final isSpanish = _getIsSpanish(cubit);
  
  // PRIMERO: Detectar why
  final isWhy = _isWhyQuestion(normalized, isSpanish);
  if (isWhy) {
    return {
      "step": "regProgress.myNewField",
      "valid": false,
      "isWhy": true,
      "field": "myNewField",
    };
  }
  
  // DESPUÉS: tu lógica normal de evaluación
  // ...
  
  return {
    "step": "regProgress.myNewField",
    "valid": true,
    "userResponse": original.trim(),
  };
}
```

### Opción B: Implementación Manual

```dart
// Para campos simples sin cubit
final isWhy = 
  normalized == 'why' ||
  normalized == 'why?' ||
  normalized.contains('why ') ||
  normalized.contains('por qué') ||
  normalized.contains('para qué');
```

---

## ⚙️ Paso 3: Integración en GeminiService

### No es necesario modificar `gemini_service.dart`

El código existente en sendMessage() maneja automáticamente:

```dart
if (decision['isWhy'] == true) {
  final explanation = MigozzContext.getWhyExplanation(fieldKey, language);
  return {
    "text": explanation,
    "options": const <String>[],
    "step": 'regProgress.$currentStepKey',
    "keepTalk": true,
    "explainAndRepeat": true,
  };
}
```

---

## 🧪 Paso 4: Pruebas

### Unit Test Ejemplo

```dart
test('_isWhyQuestion detecta preguntas en español', () {
  expect(_isWhyQuestion('por qué', true), true);
  expect(_isWhyQuestion('para qué', true), true);
  expect(_isWhyQuestion('mi nombre es juan', true), false);
});

test('_isWhyQuestion detecta preguntas en inglés', () {
  expect(_isWhyQuestion('why do you need', false), true);
  expect(_isWhyQuestion('why?', false), true);
  expect(_isWhyQuestion('my name is john', false), false);
});

test('MigozzContext devuelve explicación correcta', () {
  final explanation = MigozzContext.getShortExplanation('location', 'es');
  expect(explanation.isNotEmpty, true);
  expect(explanation.contains('ubicación'), true);
});
```

### Test Manual

1. Abre la app
2. Navega al campo que agregaste
3. Pregunta: "¿Por qué?"
4. Verifica que aparezca tu explicación

---

## 📊 Campos Existentes con Contexto

Estos campos ya tienen soporte completo:

| Campo | Ubicación función | Status |
|-------|-------------------|--------|
| fullName | _evaluateFullName | ✅ isWhy detectado |
| username | _evaluateUsername | ✅ isWhy detectado |
| location | _evaluateLocation | ✅ isWhy detectado |
| sendOTP | _evaluateSendOTP | ✅ isWhy detectado |
| otpInput | _evaluateOTP | ✅ isWhy detectado |
| phone | No existe aún | ⏳ Pendiente |
| voiceNoteUrl | No existe aún | ⏳ Pendiente |
| avatarUrl | No existe aún | ⏳ Pendiente |
| socialEcosystem | No existe aún | ⏳ Pendiente |

---

## 🚀 Ejemplo Completo: Agregar Contexto para "Gender"

### Paso 1: Agregar Contexto
```dart
// En migozz_context.dart - fieldContextES
'gender': {
  'purpose': 'Información Demográfica',
  'why': 'El género nos ayuda a personalizar la experiencia y recomendar colaboraciones relevantes.',
  'benefit': 'Nos permite recomendarte marcas y creadores con intereses afines.',
  'examples': 'Marcas de moda femenina buscan influencers mujeres; marcas de fitness buscan diversidad.',
  'brands': 'Las marcas usan esta información para encontrar creadores alineados con su target audience.',
}

// En fieldContextEN
'gender': {
  'purpose': 'Demographic Information',
  'why': 'Gender helps us personalize your experience and recommend relevant collaborations.',
  'benefit': 'Allows us to suggest brands and creators aligned with your interests.',
  'examples': 'Fashion brands look for female influencers; fitness brands seek diversity.',
  'brands': 'Brands use this to find creators aligned with their target audience.',
}
```

### Paso 2: Mejorar Evaluación
```dart
static Map<String, dynamic> _evaluateGender(
  String normalized,
  String original,
) {
  // NUEVO: Detectar why
  final isWhy = _isWhyQuestion(normalized, false);
  if (isWhy) {
    return {
      "step": "regProgress.gender",
      "valid": false,
      "isWhy": true,
      "field": "gender",
    };
  }
  
  // Lógica existente...
  if (normalized == 'hombre' || normalized == 'male' || normalized == 'man') {
    return {
      "step": "regProgress.gender",
      "valid": true,
      "userResponse": "Male",
    };
  }
  
  // ... resto de opciones
}
```

### Paso 3: ¡Listo!
- GeminiService manejará automáticamente la explicación
- No necesitas cambiar nada más

---

## 🔐 Mejores Prácticas

### ✅ DO (Hacer)

1. **Siempre detectar "why" PRIMERO**
   ```dart
   if (isWhy) return { "isWhy": true, ... };
   // Después validar respuesta normal
   ```

2. **Usar lenguaje claro y accesible**
   - ❌ "Necesitamos tu ubicación para optimizar geolocalización"
   - ✅ "Tu ubicación permite que marcas de tu zona te encuentren"

3. **Proporcionar contexto de negocio**
   - Muestra cómo beneficia al creador
   - Explica perspectiva de marcas
   - Da ejemplos reales

4. **Mantener consistencia de tono**
   - Profesional pero amable
   - Educativo pero conciso
   - Español/English equivalentes

### ❌ DON'T (No hacer)

1. **No hagas explicaciones demasiado largas**
   - Max 3-4 secciones por explicación
   - Cada sección: 1-2 oraciones

2. **No mezcles idiomas**
   - Español puro en versión ES
   - English puro en versión EN

3. **No ignores casos edge**
   - "Por que" sin tilde
   - "WHY???" con múltiples signos
   - Variaciones de preguntas

4. **No cambies estructura de decision**
   - Siempre devuelve `{ "step": "...", "valid": ..., ...}`
   - Mantén consistencia con otros campos

---

## 🐛 Troubleshooting

### Problema: `_isWhyQuestion` no se encuentra
**Solución:** Asegúrate que la función está en `assistant_functions.dart` línea ~650

### Problema: Explicación no aparece
**Solución:** 
1. Verifica que fieldKey es correcto
2. Verifica que contexto existe en `fieldContextES/EN`
3. Revisa logs para "isWhy"

### Problema: Idioma incorrecto
**Solución:** Verifica que `language` se detecta correctamente desde `registerCubit.state.language`

### Problema: Flujo se rompe
**Solución:** Asegúrate que `keepTalk: true` y `explainAndRepeat: true` en la respuesta

---

## 📈 Métricas de Éxito

Estas métricas indican que el sistema funciona correctamente:

```
✅ Usuario pregunta "why"
   ↓
✅ Sistema detecta isWhy = true
   ↓
✅ Explicación aparece en 2-3 segundos
   ↓
✅ Usuario ve contexto relevante
   ↓
✅ Bot re-pregunta automáticamente
   ↓
✅ Usuario completa el campo
   ↓
✅ Registro continúa
```

---

## 📚 Referencias

- **Archivo principal:** `lib/core/services/ai/migozz_context.dart`
- **Función detection:** `_isWhyQuestion()` en `assistant_functions.dart`
- **Orquestador:** `sendMessage()` en `gemini_service.dart`
- **Documentación:** `MIGOZZ_CONTEXT_SYSTEM.md`

---

## 💡 Ideas para Mejoras

### Nivel 1: Contexto Dinámico
```dart
// En lugar de strings fijos, usa datos del usuario
final followerCount = registerCubit.state.socialEcosystem['instagram']['followers'];
// Personaliza explicación: "Con ${followerCount} seguidores..."
```

### Nivel 2: A/B Testing
```dart
// Prueba dos versiones de explicación
final version = Random().nextBool() ? explanationA : explanationB;
// Mide cuál convierte más
```

### Nivel 3: Analytics
```dart
// Rastrear qué campos generan más "why" preguntas
debugPrint('why_question: $fieldKey');
// Identifica campos confusos
```

---

## 🎯 Conclusión

El sistema está diseñado para ser:
- **Simple:** Solo agregar strings + detectar why
- **Escalable:** Aplica a cualquier campo
- **Flexible:** Fácil modificar explicaciones
- **Mantenible:** Código limpio y documentado

Para preguntas, revisa `MIGOZZ_CONTEXT_SYSTEM.md` o contacta al equipo.

---

**Versión:** 1.0  
**Para desenvolvedores:** Senior+  
**Tiempo estimado para agregar 1 campo:** 5-10 minutos
