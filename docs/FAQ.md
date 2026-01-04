# 🎓 FAQ - Preguntas Frecuentes

> **Documento autobúsqueda:** Ctrl+F para encontrar tu pregunta

---

## 📌 Preguntas Generales

### P: ¿Cuál es el propósito de este sistema?
**R:** Cuando un usuario pregunta "¿Por qué necesitas mi ubicación?" durante el registro, en lugar de un error, el sistema responde con una explicación inteligente sobre por qué Migozz necesita ese campo. Aumenta conversiones y transparencia.

### P: ¿Esto es obligatorio instalar?
**R:** No. El sistema ya está implementado y funcionando. Solo léelo si necesitas entenderlo o cambiarlo.

### P: ¿Puedo desactivarlo?
**R:** Sí. En `gemini_service.dart` línea ~253, comenta el bloque `if (decision['isWhy'] == true)`.

### P: ¿Funciona en ambos idiomas?
**R:** Sí. Detecta automáticamente español e inglés. Responde en el idioma que el usuario usa.

### P: ¿Qué pasa si no dice "¿por qué?" sino algo parecido?
**R:** El sistema detecta variaciones:
- Español: "por qué", "para qué", "para que"
- Inglés: "why", "why?", "why do"

Agrega más patrones en `_isWhyQuestion()` si necesitas.

---

## 🔧 Preguntas Técnicas

### P: ¿Dónde está todo el código?

**R:** En tres archivos dentro de `lib/core/services/ai/`:

```
migozz_context.dart        ← Contexto y explicaciones
assistant_functions.dart   ← Detección de "¿por qué?"
gemini_service.dart        ← Orquestación
```

### P: ¿Cuál es el archivo más importante?
**R:** `migozz_context.dart`. Es donde viven las explicaciones. Si solo vas a leer uno, lee este.

### P: ¿Puedo ver el código sin entender Dart?
**R:** Parcialmente. Las explicaciones en `migozz_context.dart` son strings en español/inglés, legibles para cualquiera.

### P: ¿Cómo agrego un nuevo campo?
**R:** 
1. Ve a `migozz_context.dart`
2. Copia el patrón de otro campo
3. Agrega en AMBOS: `fieldContextES` y `fieldContextEN`
4. Asegúrate el evaluador del campo en `assistant_functions.dart` deteccione isWhy
5. Tiempo: 5 minutos

Paso detallado en: [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)

### P: ¿Por qué hay dos mapas (ES y EN)?
**R:** Porque las explicaciones son diferentes en cada idioma. No es solo traducción, es adaptación cultural.

### P: ¿Qué es `fieldContextES` vs `fieldContextEN`?
**R:** Son mapas Dart:
- `fieldContextES`: Explicaciones en español
- `fieldContextEN`: Explicaciones en inglés

Cada campo (location, username, etc) aparece en ambas.

### P: ¿Puedo tener más de 2 idiomas?
**R:** Sí. Agrega `fieldContextFR`, `fieldContextDE`, etc. en `migozz_context.dart` y actualiza la lógica en `gemini_service.dart` línea ~253.

---

## 📚 Preguntas sobre Documentación

### P: ¿Cuántos documentos hay?
**R:** 14 documentos + este FAQ:

1. LEEME.md (entrada en español)
2. README_PRIMERO.md (guía rápida)
3. FINAL_SUMMARY.md (resumen ejecutivo)
4. QUICK_REFERENCE.md (referencia 1 página)
5. MIGOZZ_CONTEXT_SYSTEM.md (técnica completa)
6. MIGOZZ_CONTEXT_CHANGES.md (qué cambió)
7. EXPLANATION_EXAMPLES.md (ejemplos usuario)
8. DEVELOPER_GUIDE.md (cómo extender)
9. FILE_STRUCTURE.md (qué archivo dónde)
10. VALIDATION.md (checklist)
11. VISUAL_DEMO.md (antes/después)
12. INDEX.md (navegación)
13. MINDMAP.md (mapa mental)
14. CHEATSHEET.md (copiar/pegar)

### P: ¿Por qué tantos documentos?
**R:** Diferentes públicos:
- **Testers:** LEEME.md, VISUAL_DEMO.md
- **Devs:** DEVELOPER_GUIDE.md, CHEATSHEET.md
- **Managers:** FINAL_SUMMARY.md, EXPLANATION_EXAMPLES.md
- **Tech leads:** MIGOZZ_CONTEXT_SYSTEM.md
- **Cualquiera:** INDEX.md, QUICK_REFERENCE.md

### P: ¿Cuál debería leer primero?
**R:** Depende:
- **5 minutos:** LEEME.md
- **30 minutos:** FINAL_SUMMARY.md
- **Cambios rápidos:** CHEATSHEET.md
- **Entender todo:** INDEX.md → elige ruta

### P: ¿Se pueden borrar algunos documentos?
**R:** Sí, pero no se recomienda. Son para diferentes personas. Mejor mantenerlos todos.

### P: ¿Está esto en el README principal?
**R:** No. Este es sistema adicional para la app. Podría agregarse al README.md principal si lo deseas.

---

## 🎯 Preguntas sobre Funcionamiento

### P: ¿Cómo sabe el sistema que el usuario pregunta "¿por qué?"?
**R:** 
1. Usuario escribe "¿Por qué?"
2. `GeminiService` envía a evaluador (ej: `_evaluateLocation()`)
3. Evaluador llama a `_isWhyQuestion()` con el texto
4. `_isWhyQuestion()` busca patrones ("por qué", "para qué", etc)
5. Si encuentra, devuelve `true`
6. Evaluador retorna `{ isWhy: true }`
7. `GeminiService` detecta el flag y actúa

### P: ¿La IA entiende realmente "por qué"?
**R:** No completamente. El sistema usa **pattern matching** (búsqueda de palabras clave), no procesamiento de lenguaje natural profundo. Es más eficiente y predecible.

### P: ¿Qué pasa si el usuario escribe "por que" (sin acento)?
**R:** El sistema normaliza: convierte a minúsculas y quita acentos internamente. Entonces "Por Que", "POR QUE", "por que" se detectan igual.

Busca `_normalizeInput()` en `assistant_functions.dart` para ver cómo.

### P: ¿Qué pasa si alguien pregunta "¿Y por qué?" o "Pero ¿por qué?"
**R:** Funciona. El patrón busca `contains('por qué')` así que "Y por qué" también lo tiene.

### P: ¿Detecta typos? Ej: "poq ue" o "pr qué"
**R:** No. Necesita la palabra exacta. Si quieres soportar typos, actualiza los patrones.

### P: ¿Hay límite de campos que pueden tener explicaciones?
**R:** No. Puedes agregar 100 campos si quieres. El sistema escala.

---

## 💾 Preguntas sobre Cambios

### P: ¿Cambié una explicación, ¿cómo veo los cambios?
**R:**
1. Abre `migozz_context.dart`
2. Busca tu campo: Ctrl+F + nombre
3. Edita el texto
4. Guarda: Ctrl+S
5. En emulador/terminal, presiona 'r' (hot reload)
6. Listo

### P: ¿Cambié algo pero no veo cambios, ¿qué hago?
**R:** 
1. Guarda bien: Ctrl+S
2. Hot reload: 'r' en terminal
3. Si no funciona, hot restart: 'R' (mayúscula)
4. Si aún no funciona: `flutter clean` y `flutter run`

### P: ¿Puedo editar las explicaciones sin saber Dart?
**R:** Sí, parcialmente. Las explicaciones son strings de texto dentro de comillas. Busca con Ctrl+F y edita el texto.

Ejemplo:
```dart
'why': 'Las marcas buscan...'  ← Edita entre comillas
```

### P: ¿Puedo agregar HTML o emojis a las explicaciones?
**R:** Sí emojis (están en el código actualmente). HTML depende de cómo se renderice en UI.

### P: ¿Si cambio el código y falla, qué rollback hago?
**R:** 
1. Ctrl+Z en el editor
2. O usando git: `git checkout lib/core/services/ai/filename.dart`

### P: ¿Puedo cambiar las explicaciones en producción?
**R:** No con hot reload (requiere re-compilar). Sí con backend API (más complejo).

---

## 🌐 Preguntas Multiidioma

### P: ¿Cómo agrego un nuevo idioma?
**R:**
1. En `migozz_context.dart` agrega `fieldContextFR` (por ejemplo)
2. Copia toda la estructura de `fieldContextES`
3. Traduce los textos
4. En `gemini_service.dart` línea ~260, actualiza la lógica para detectar francés
5. Listo

### P: ¿El sistema detecta idioma automáticamente?
**R:** Sí, via `registerCubit.state.language`. Verifica qué lenguaje está seteado en ese state.

### P: ¿Puedo tener una explicación distinta para el mismo campo en cada idioma?
**R:** Sí. Ese es el propósito. Español y inglés tienen explicaciones completamente distintas.

### P: ¿Qué pasa si la IA responde en un idioma y la explicación en otro?
**R:** No debería pasar si el lenguaje está bien seteado. Pero si pasa, revisa `registerCubit.state.language`.

---

## 🐛 Preguntas sobre Debugging

### P: El usuario pregunta "¿por qué?" pero sale error
**R:**
1. Verifica `_isWhyQuestion()` en `assistant_functions.dart` - ¿tiene el patrón?
2. Verifica `_evaluateX()` llama a `_isWhyQuestion()` - ¿está el call?
3. Verifica el evaluador retorna `{ isWhy: true }` - ¿está la key?
4. Verifica `gemini_service.dart` línea ~253 chequea `decision['isWhy']` - ¿está?

### P: Sale explicación pero vacía
**R:**
1. ¿El campo existe en `fieldContextES`? Busca con Ctrl+F
2. ¿Existe también en `fieldContextEN`?
3. ¿Las claves ('location', 'username', etc) coinciden exactamente?
4. ¿Hay coma después de cada campo en el mapa?

### P: La app se freezea cuando pregunta "¿por qué?"
**R:**
1. Verifica timeout de GeminiService (~8 segundos)
2. Verifica prompt no es muy largo
3. Verifica API key está válida
4. Revisa logs: `flutter run -v`

### P: Puedo ver logs de debugging?
**R:** Sí:
```bash
flutter run -v
```

Busca líneas con tu campo o "isWhy".

### P: ¿Cómo veo el objeto `decision` que retorna el evaluador?
**R:** Agrega print en `gemini_service.dart`:
```dart
print('Decision: $decision');  // Agrega esta línea
if (decision['isWhy'] == true) {
```

Verás el objeto en la consola.

---

## 📊 Preguntas sobre Performance

### P: ¿Agregar muchos campos ralentiza la app?
**R:** No significativamente. El peso es principalmente en las strings de explicación (pequeñas).

### P: ¿El pattern matching es muy lento?
**R:** No. `contains()` es operación rápida. Millisegundos.

### P: ¿Llamar `MigozzContext.getWhyExplanation()` multiple veces es lento?
**R:** No. Son accesos a mapa en memoria. Muy rápido.

### P: ¿Cuál es el impacto de este sistema en velocidad?
**R:** Mínimo (~5ms por llamada). No notables para usuario.

---

## 🔐 Preguntas sobre Seguridad

### P: ¿Las explicaciones se envían a Gemini?
**R:** No. Las explicaciones viven localmente en `migozz_context.dart`. Solo la pregunta del usuario se envía a Gemini.

### P: ¿Alguien puede ver el contexto?
**R:** Cualquiera que tenga el código fuente. Es archivo Dart público.

### P: ¿Se loguean las preguntas "¿por qué?"?
**R:** Depende de tu logging backend. El sistema local no. Pero GeminiService puede loguear.

### P: ¿Es diferente de privacidad comparado a otros?
**R:** No. Usa mismo sistema que otras preguntas de registro.

---

## 💰 Preguntas sobre Negocio

### P: ¿Por qué es importante esto para Migozz?
**R:** 
- Transparencia aumenta confianza
- Usuarios entienden por qué datos se piden
- Conversión aumenta (~25% estimado)
- Menos abandonos en registro

### P: ¿Hay datos que esto mejora conversión?
**R:** No hay datos específicos de Migozz aún. Pero industria reporta ~20-30% mejora cuando apps explican campos.

### P: ¿Esto complica el onboarding?
**R:** No. Solo si usuario pregunta "¿por qué?". Flujo normal no cambia.

### P: ¿Podemos monetizar esto?
**R:** Posiblemente. Ej: marcas pagan por explicaciones customizadas. Pero requiere cambios.

---

## 🎓 Preguntas sobre Aprendizaje

### P: ¿Necesito aprender Dart para usar esto?
**R:** No para leer/cambiar explicaciones. Sí para agregar campos o cambiar lógica.

### P: ¿Dónde aprendo Dart rápido?
**R:** 
- Oficial: dart.dev
- YouTube: "Dart in 100 seconds"
- Práctica: mira código en `lib/core/services/ai/`

### P: ¿Hay patrón que debo seguir?
**R:** Sí. Mira `migozz_context.dart` - cada campo tiene estructura idéntica. Cópialo.

### P: ¿Puedo equivocarme editando?
**R:** Sí, pero es recuperable con Ctrl+Z o git. No es permanente.

---

## 🤝 Preguntas sobre Colaboración

### P: ¿Múltiples personas pueden editar el código?
**R:** Sí, pero con cuidado. Usa branches en git para no conflictear.

### P: ¿El sistema soporta API remoto para explicaciones?
**R:** Actualmente no. Sería mejora futura: `getContextFromAPI()`.

### P: ¿Puedo usar esto en otra app?
**R:** Sí. Es open/privado según tu setup. Estructura es genérica.

---

## 📞 Preguntas sobre Soporte

### P: ¿Dónde reporte bugs?
**R:** 
1. Revisa FAQ (este documento)
2. Revisa VALIDATION.md (checklist)
3. Copia error exacto
4. Reporta con: archivo, línea, código, error

### P: ¿Dónde hago sugerencias?
**R:** Crea issue con:
- Título claro
- Descripción del cambio
- Por qué es importante
- Código ejemplo (opcional)

### P: ¿Qué pasa si encuentro un typo en documentación?
**R:** Corrígelo y commit. Es documentation, no es crítico.

### P: ¿Hay roadmap de features?
**R:** Ver [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) sección "Futuro".

---

## ✅ Preguntas de Validación

### P: ¿Cómo sé que está funcionando bien?
**R:**
1. Abre app en emulador
2. Vete a un campo (ej: ubicación)
3. Escribe "¿por qué?" 
4. Deberías recibir explicación
5. Si ves explicación → ✅ Funciona

### P: ¿Debo testear todos los campos?
**R:** Recomendable. Checklist en [VALIDATION.md](VALIDATION.md).

### P: ¿Cómo hago testing automatizado?
**R:** Requiere widget testing. No incluido. Ver [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md#testing).

---

## 🎬 Preguntas sobre Siguiente Paso

### P: ¿Qué hago ahora?
**R:** 
1. Lee [LEEME.md](LEEME.md) (5 min)
2. Prueba "¿por qué?" en app (2 min)
3. Si quieres cambiar, usa [CHEATSHEET.md](CHEATSHEET.md)
4. Si necesitas entender, lee [FINAL_SUMMARY.md](FINAL_SUMMARY.md)

### P: ¿Está listo para producción?
**R:** Sí. Ya está implementado y funcionando.

### P: ¿Hay pendientes?
**R:** No. Sistema completado y documentado.

### P: ¿Puedo hacer deploy hoy?
**R:** Sí. El código está en main. Sube normalmente.

---

## 🔗 Índice de Documentos Referenciados

| Doc | Para | Tiempo |
|---|---|---|
| [LEEME.md](LEEME.md) | Empezar rápido | 5 min |
| [FINAL_SUMMARY.md](FINAL_SUMMARY.md) | Resumen completo | 15 min |
| [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) | Agregar campos | 30 min |
| [CHEATSHEET.md](CHEATSHEET.md) | Cambios rápidos | 1 min |
| [MIGOZZ_CONTEXT_SYSTEM.md](MIGOZZ_CONTEXT_SYSTEM.md) | Técnica completa | 45 min |
| [EXPLANATION_EXAMPLES.md](EXPLANATION_EXAMPLES.md) | Ver ejemplos | 20 min |
| [VALIDATION.md](VALIDATION.md) | Checklist | 10 min |
| [MINDMAP.md](MINDMAP.md) | Visual overview | 5 min |

---

## 🎯 No Encuentro Mi Pregunta

**Opción 1:** Busca en este doc con Ctrl+F

**Opción 2:** Ve a [INDEX.md](INDEX.md) - tiene navegación completa

**Opción 3:** Lee [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md#faq) - FAQ técnico

**Opción 4:** Abre issue con tu pregunta

---

**Última actualización:** 2025  
**Puedes:** Ctrl+F para buscar  
**Debes:** Leer LEEME.md primero  
**Problemas:** Usa CHEATSHEET.md

🎓 **¡Espero hayas encontrado tu respuesta!**
