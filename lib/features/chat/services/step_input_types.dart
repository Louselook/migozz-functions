/// Definición de tipos de entrada esperados por cada paso del registro
/// IA-01: Input Gate por step
library;

enum InputStepType {
  text, // Texto plano (nombre, usuario, correo, etc.)
  audio, // Grabación de audio (voiceNoteUrl)
  image, // Foto (avatarUrl)
  location, // Confirmación de ubicación (sí/no/incorrecta)
  choice, // Selección de opciones predefinidas (género, etc.)
  phone, // Número de teléfono
  code, // Código de verificación (OTP)
  any, // Cualquier tipo (pasos especiales)
}

/// Mapeo de steps a tipos de entrada esperados
final Map<String, InputStepType> stepInputTypeMap = {
  // Flujo completo (no autenticados)
  'fullName': InputStepType.text,
  'username': InputStepType.text,
  'gender': InputStepType.choice,
  'location': InputStepType.location,
  'sendOTP': InputStepType.choice,
  'emailChange': InputStepType.text,
  'emailVerification': InputStepType.text,
  'otpInput': InputStepType.code,
  'emailSuccess': InputStepType.text,
  'phone': InputStepType.phone,
  'voiceNoteUrl': InputStepType.audio,
  'avatarUrl': InputStepType.image,
  'socialEcosystem': InputStepType.choice,

  // Pasos especiales
  'done': InputStepType.any,
  'finished': InputStepType.any,
};

/// Obtener el tipo de entrada esperado para un step
InputStepType getInputTypeForStep(String step) {
  return stepInputTypeMap[step] ?? InputStepType.any;
}

/// Determinar si un tipo de input es válido para un step
bool isValidInputTypeForStep(String step, InputStepType inputType) {
  final expectedType = getInputTypeForStep(step);

  // Si el step acepta cualquier tipo
  if (expectedType == InputStepType.any) {
    return true;
  }

  // Permitir texto en el step de ubicación para ingreso manual (país/estado/ciudad)
  if (expectedType == InputStepType.location &&
      inputType == InputStepType.text) {
    return true;
  }

  // Si el tipo coincide exactamente
  if (inputType == expectedType) {
    return true;
  }

  // Casos especiales: algunos inputs de texto son válidos en otros contextos
  if (inputType == InputStepType.text &&
      (expectedType == InputStepType.choice ||
          expectedType == InputStepType.code ||
          expectedType == InputStepType.phone)) {
    return true; // Permitir texto para opciones, códigos y teléfonos
  }

  return false;
}

/// Descripción amigable del tipo de entrada esperado
String getInputTypeDescription(InputStepType type, bool isSpanish) {
  switch (type) {
    case InputStepType.text:
      return isSpanish ? 'texto' : 'text';
    case InputStepType.audio:
      return isSpanish ? 'nota de voz' : 'audio note';
    case InputStepType.image:
      return isSpanish ? 'foto' : 'photo';
    case InputStepType.location:
      return isSpanish ? 'confirmación de ubicación' : 'location confirmation';
    case InputStepType.choice:
      return isSpanish
          ? 'una opción de las sugeridas'
          : 'one of the suggested options';
    case InputStepType.phone:
      return isSpanish ? 'número de teléfono' : 'phone number';
    case InputStepType.code:
      return isSpanish ? 'código de verificación' : 'verification code';
    case InputStepType.any:
      return isSpanish ? 'cualquier tipo' : 'any type';
  }
}
