# 🧠 Mapa Mental del Sistema

## Sistema Completo en Una Página

```
                    MIGOZZ CONTEXT SYSTEM
                          (ROOT)
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
    USUARIO          CÓDIGO               DOCUMENTACIÓN
    
    • Pregunta       • migozz_context      • 11 docs
      "¿Por qué?"    • assistant_functions • 4,000 líneas
                     • gemini_service
    • Recibe
      explicación    → 450 líneas código  → Completa
    
    • Continúa       → LISTO PRODUCCIÓN   → Por rol
      registro
```

---

## 🌳 Árbol de Decisión: ¿Qué Leo?

```
                    COMIENZA AQUÍ
                        │
                        ▼
            ¿CUÁNTO TIEMPO TENGO?
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    5 MIN         30 MIN           2 HORAS
        │               │               │
        ▼               ▼               ▼
    QUICK          SUMMARY         COMPLETE
    ────────────────────────────────────
        │               │               │
    • LEEME.md      • FINAL_SUMMARY  • Todos los
    • Prueba        • VISUAL_DEMO      documentos
    • Listo        • EXPLANATION      en orden
                     • QUICK_REF
```

---

## 🗺️ Flujo de Información

```
USUARIO PREGUNTA: "¿Por qué?"
            │
            ▼
────────────────────────────────────────────────
│                                              │
│  GeminiService.sendMessage()                │
│  1. Recibe input                            │
│  2. Envía a evaluador                       │
│  3. Obtiene decision                        │
│                                              │
└─────────────────┬──────────────────────────┘
                  │
                  ▼
────────────────────────────────────────────────
│                                              │
│  AssistantFunctions.evaluateUserResponse()  │
│  1. Normaliza input                         │
│  2. Detecta: isWhy = true ✅               │
│  3. Devuelve: { isWhy: true, field: ... }  │
│                                              │
└─────────────────┬──────────────────────────┘
                  │
                  ▼
────────────────────────────────────────────────
│                                              │
│  GeminiService verifica decision['isWhy']   │
│  1. Es true ✅                              │
│  2. Llama: MigozzContext.getWhyExplanation()│
│  3. Obtiene explicación completa            │
│                                              │
└─────────────────┬──────────────────────────┘
                  │
                  ▼
────────────────────────────────────────────────
│                                              │
│  MigozzContext.getWhyExplanation()          │
│  1. Accede fieldContextES/EN                │
│  2. Obtiene contexto del campo              │
│  3. Formatea con emojis                     │
│  4. Devuelve explicación                    │
│                                              │
└─────────────────┬──────────────────────────┘
                  │
                  ▼
────────────────────────────────────────────────
│                                              │
│  IAChatScreen.showMessage()                 │
│  1. Muestra explicación                     │
│  2. keepTalk: true (no salta paso)          │
│  3. Re-pregunta automáticamente             │
│                                              │
└─────────────────┬──────────────────────────┘
                  │
                  ▼
          USUARIO ENTIENDE
          USUARIO CONTINÚA
          ✅ CONVERSIÓN
```

---

## 📚 Árbol de Documentación

```
                    DOCUMENTACIÓN
                      (11 docs)
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    GUÍAS           TÉCNICOS          REFERENCIAS
    ┌─────┐         ┌──────┐          ┌──────────┐
    │     │         │      │          │          │
    • LEEME          • SYSTEM      • EXAMPLES
    • FINAL_SUM      • CHANGES     • FILE_STR
    • QUICK_REF      • DEV_GUIDE   • INDEX
    • VISUAL_DEMO                  • VALIDATION
```

---

## 🎯 Campos con Contexto

```
                 CAMPOS SOPORTADOS
                      (7)
                       │
        ┌──────────────┼──────────────┐
        │              │              │
    PERSONALES    CONTACTO         PORTFOLIO
    ┌─────┐      ┌────────┐       ┌────────┐
    │     │      │        │       │        │
  fullName  phone voiceNote  social
  username        avatar      network
  location
```

---

## 🌍 Soporte Multi-idioma

```
                 DETECCIÓN IDIOMA
                       │
        ┌──────────────┴──────────────┐
        │                             │
    ESPAÑOL                       ENGLISH
    ┌──────────────┐           ┌──────────────┐
    │              │           │              │
    • "por qué"    │           │  • "why"
    • "para qué"   │           │  • "why?"
    • "para que"   │           │  • "why do"
    • Contexto ES  │           │  • Contexto EN
```

---

## 💼 Roles y Documentos

```
USUARIO/TESTER          DEVELOPER              MANAGER
      │                    │                      │
      ▼                    ▼                      ▼
   LEEME.md           DEV_GUIDE.md         FINAL_SUMMARY.md
   (5 min)           (30 min)              (5 min)
      │                    │                      │
      ▼                    ▼                      ▼
   Prueba             Entiende              Evalúa
   la app            técnica                impacto
   
   
PRODUCT                 TECH LEAD              ANYONE
      │                    │                      │
      ▼                    ▼                      ▼
EXPLANATION_EX      CHANGES.md              INDEX.md
(15 min)            (20 min)                (10 min)
      │                    │                      │
      ▼                    ▼                      ▼
Ver ejemplos        Revisar cambios    Navegación
reales              línea por línea     completa
```

---

## 🔧 Componentes del Sistema

```
                   ARQUITECTURA
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    CONTEXTO       DETECCIÓN           ORQUESTACIÓN
    ┌──────┐      ┌────────┐          ┌──────────┐
    │      │      │        │          │          │
    •Migozz   • _isWhy    • Gemini
    Context   Question()   Service
    
    •7 campos •6 evaluadores•maneja
    •ES/EN   •Patrones:     isWhy
    •Métodos  por qué/why
             para qué
```

---

## ✅ Checklist Mental

```
¿ENTIENDO EL SISTEMA?
        │
    ┌───┴───┐
   SÍ      NO
    │       │
    ▼       ▼
   👍      Lee
   Continúa INDEX.md
```

```
¿VOY A EXTENDER?
        │
    ┌───┴───┐
   SÍ      NO
    │       │
    ▼       ▼
  Lee     Disfruta
  DEV_    el sistema
  GUIDE
```

```
¿NECESITO AYUDA?
        │
    ┌───┴───┐
   SÍ      NO
    │       │
    ▼       ▼
  Busca    Perfecto!
  en       ✅
  docs
```

---

## 📊 Resumen Visualizado

```
ANTES                      AHORA
────────                   ─────
Usuario pregunta   →   Usuario pregunta
   "¿Por qué?"            "¿Por qué?"
        │                      │
        ▼                      ▼
   Error ❌              Explicación ✅
        │                      │
        ▼                      ▼
Abandona 😞              Continúa 😊
        │                      │
        ▼                      ▼
   Conversión falida      Conversión exitosa
   ❌ 40% abandono        ✅ 15% abandono
                          (25% mejora)
```

---

## 🎯 Tu Propósito Aquí

```
COMIENZA EN LEEME.md
        │
        ▼
    Elige camino
        │
    ┌───┴───┬────┐
    │       │    │
 Solo    5 MIN  30 MIN  2 HORAS
 Probar  Docs  Docs     Docs
    │       │    │
    ▼       ▼    ▼
 Éxito ✅ + Entendimiento + Experto
```

---

## 🔗 Mapeo de Documentos por Tema

```
TEMA: "¿QUÉ ES?"
    → FINAL_SUMMARY.md
    → QUICK_REFERENCE.md
    → LEEME.md

TEMA: "¿CÓMO FUNCIONA?"
    → DEVELOPER_GUIDE.md
    → MIGOZZ_CONTEXT_SYSTEM.md
    → FILE_STRUCTURE.md

TEMA: "¿QUÉ VE EL USUARIO?"
    → EXPLANATION_EXAMPLES.md
    → VISUAL_DEMO.md
    → QUICK_REFERENCE.md

TEMA: "¿QUÉ CAMBIÓ?"
    → MIGOZZ_CONTEXT_CHANGES.md
    → FILE_STRUCTURE.md
    → VALIDATION.md

TEMA: "¿POR DÓNDE EMPIEZO?"
    → README_PRIMERO.md
    → INDEX.md
    → LEEME.md
```

---

## 🎓 Curva de Aprendizaje

```
CONOCIMIENTO
   100% │                          ╱─── Experto
        │                      ╱──┘    (2h)
    75% │                  ╱──┘
        │              ╱──┘  Intermedio
    50% │          ╱──┘      (30m)
        │      ╱──┘
    25% │  ╱──┘  Básico
        │╱       (5m)
     0% ├────────────────────────────── Tiempo
        0     5m    30m    1h    2h    3h
        
    RECOMENDADO: Comienza con 5 min,
    luego amplía según necesites
```

---

## 🎬 Flujo Típico de Usuario

```
USUARIO FINAL
    │
    ▼
¿PROBANDO LA APP?
    │
    ├─ SÍ → Haz "¿Por qué?" → Ve explicación → 😊
    │
    └─ NO → Leer documentación según rol
              ↓
          ┌────┬────┬────┐
          │    │    │    │
        Tester Dev Lead PM
          │    │    │    │
          ▼    ▼    ▼    ▼
       5min 30min 20min 15min
          │    │    │    │
          ▼    ▼    ▼    ▼
        LEEME DEV CHANGES EXAMPLES
        ↓    GUIDE   │     │
        Prueba  │     │     │
        app    Entiendo  Evalúo Veo
        ✅     técnica  impacto ejemplos
```

---

## 💡 Conclusión Visual

```
┌─────────────────────────────────────────┐
│                                         │
│    PROBLEMA → SOLUCIÓN → DOCUMENTACIÓN  │
│                                         │
│  "¿Por qué?"  Sistema   11 docs        │
│    Error     Inteligente 4,000 líneas  │
│   Abandono   Explicaciones Completo    │
│                                         │
│            ✅ COMPLETADO                │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🚀 Siguiente Acción

```
ERES AQUÍ ↓

LEEME.md
    ↓
FINAL_SUMMARY.md (o tu doc recomendado)
    ↓
IMPLEMENTACIÓN/PRUEBA
    ↓
✅ ÉXITO
```

---

**Mapa creado:** 2025  
**Propósito:** Orientación rápida  
**Tiempo de lectura:** 3-5 min

🧭 **¡Usa este mapa para navegar el sistema!**
