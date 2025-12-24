# Implementación: Cambio de Correo en Flujo de Registro OTP

## Descripción del Problema
Cuando el usuario estaba registrando una nueva cuenta y llegaba a la pregunta de confirmación de correo (`sendOTP`), si presionaba "No", el sistema solo repetía la misma pregunta sin permitir cambiar el correo. 

## Solución Implementada

La funcionalidad ahora funciona así:

1. **Usuario dice "Sí"** → Se envía OTP al correo actual
2. **Usuario dice "No"** → Se le pide un nuevo correo electrónico
3. **Usuario ingresa nuevo correo** → Se vuelve a pedir confirmación con el nuevo correo
4. **Usuario confirma nuevo correo** → Se envía OTP al nuevo correo

## Archivos Modificados

### 1. **list_queestions.dart**
- ✅ Agregada nueva pregunta `"emailChange"` en **español**:
  ```dart
  "emailChange": {
    "text": "Por favor, ingresa tu nuevo correo electrónico:",
    "options": [],
    "step": "regProgress.emailChange",
    "keepTalk": false,
    "keyboardType": "email",
  },
  ```

- ✅ Agregada nueva pregunta `"emailChange"` en **inglés**:
  ```dart
  "emailChange": {
    "text": "Please enter your new email address:",
    "options": [],
    "step": "regProgress.emailChange",
    "keepTalk": false,
    "keyboardType": "email",
  },
  ```

### 2. **assistant_functions.dart**
- ✅ Agregado caso `'emailChange'` en método `evaluateUserResponse()`:
  ```dart
  case 'emailChange': // NUEVO: Cambiar email
    return _evaluateEmailChange(normalized, userInput);
  ```

- ✅ Creada función `_evaluateEmailChange()` que:
  - Valida formato de email con regex
  - Retorna `valid: true` si es correo válido
  - Retorna `valid: false` si es inválido

### 3. **chat_validation_min.dart**
- ✅ Actualizado case `RegisterStatusProgress.sendOTP`:
  - Si `isValid == true`: Envía OTP normalmente
  - Si `isValid == false`: Retorna `"changeEmail": true` para mostrar pantalla de ingreso

- ✅ Agregado nuevo case `RegisterStatusProgress.emailChange`:
  - Si `isValid == true`: Guarda nuevo email con `registerCubit.setEmail()`
  - Retorna `"emailChanged": true` para volver a confirmar
  - Si `isValid == false`: Retorna error "correo inválido"

- ✅ Actualizado `_parseStep()` para incluir mapping de `emailchange`:
  ```dart
  if (raw.contains('emailchange')) return RegisterStatusProgress.emailChange;
  ```

### 4. **gemini_service.dart**
- ✅ Agregada lógica especial en `sendMessage()` después de `processBotResponse()`:
  
  **Cuando `changeEmail == true`:**
  ```dart
  if (processResult != null && processResult['changeEmail'] == true) {
    return {
      "text": "Por favor, ingresa tu nuevo correo electrónico:",
      "step": "regProgress.emailChange",
      "keyboardType": "email",
    };
  }
  ```

  **Cuando `emailChanged == true`:**
  ```dart
  if (processResult != null && processResult['emailChanged'] == true) {
    // Retroceder a sendOTP para confirmar nuevo email
    final emailQuestion = AssistantFunctions.getCurrentQuestion(
      questionFlow,
      questionFlow.indexOf('sendOTP'),
      registerCubit,
    );
    return await _prepareQuestion(emailQuestion, registerCubit);
  }
  ```

### 5. **register_state.dart**
- ✅ Agregado `emailChange` al enum `RegisterStatusProgress`:
  ```dart
  enum RegisterStatusProgress {
    emty,
    language,
    fullName,
    username,
    gender,
    socialEcosystem,
    location,
    sendOTP,
    emailChange,  // ← NUEVO
    emailVerification,
    ...
  }
  ```

## Flujo de Ejecución

```
1. Usuario está en "sendOTP"
   ├─ Pregunta: "Tu correo es {email}. ¿Es correcto?"
   ├─ Opción A: Usuario dice "Sí"
   │  └─ → Envía OTP → Sigue a "emailVerification"
   │
   └─ Opción B: Usuario dice "No"
      └─ → evaluateUserResponse retorna valid: false
         └─ → processBotResponse retorna changeEmail: true
            └─ → gemini_service muestra "emailChange"
               └─ → Usuario ingresa nuevo email
                  └─ → _evaluateEmailChange valida email
                     └─ → processBotResponse guarda email con setEmail()
                        └─ → Retorna emailChanged: true
                           └─ → Vuelve a mostrar "sendOTP" con nuevo email
                              └─ → Usuario confirma o rechaza de nuevo
```

## Pruebas Recomendadas

1. ✅ **Flujo Normal**: Usuario dice Sí en sendOTP
   - Esperado: Se envía OTP y avanza a emailVerification

2. ✅ **Cambio de Email**: Usuario dice No, ingresa nuevo email válido
   - Esperado: Se guarda nuevo email y vuelve a pedir confirmación

3. ✅ **Email Inválido**: Usuario ingresa formato inválido en emailChange
   - Esperado: Muestra error y pide ingresar de nuevo

4. ✅ **Ciclo Completo**: Usuario dice No, cambia email, dice Sí
   - Esperado: Se envía OTP al nuevo email

## Variables Utilizadas

- `changeEmail: true` - Bandera para indicar cambio de email
- `emailChanged: true` - Bandera para indicar que email fue actualizado
- `currentOTP` - Se mantiene para que pueda ser enviado al nuevo email

## Notas Importantes

- ✅ La validación de email usa regex: `r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'`
- ✅ El flujo mantiene soporta español e inglés automáticamente
- ✅ El nuevo paso `emailChange` NO está en el flujo principal, se inserta dinámicamente
- ✅ Se mantiene la coherencia con el `RegisterCubit` existente
