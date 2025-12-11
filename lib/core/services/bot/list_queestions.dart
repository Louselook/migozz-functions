// list_questions.dart
// Catálogo completo de preguntas del flujo de registro

/// Preguntas en ESPAÑOL
final Map<String, Map<String, dynamic>> questionsEs = {
  // "language": {
  //   "text": "👋 ¡Hola! Soy Migozz. ¿En qué idioma prefieres continuar?",
  //   "options": ["Español", "English"],
  //   "step": "regProgress.language",
  //   "keepTalk": false,
  //   "keyboardType": "text",
  // },

  "fullName": {
    "text": "¡Genial! Continuemos en Español. ¿Cuál es tu nombre completo?",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
    "keyboardType": "text",
  },

  "username": {
    "text":
        "¡Encantado de conocerte, {fullName}! Ahora, vamos a crear un nombre de usuario único para tu perfil.",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
    "keyboardType": "text",
  },

  // "gender": {
  //   "text": "¡Excelente apodo! ¿Cuál es tu género?",
  //   "options": ["Hombre", "Mujer"],
  //   "step": "regProgress.gender",
  //   "keepTalk": false,
  //   "keyboardType": "text",
  // },

  "socialEcosystem": {
    "text": "¡Agreguemos tus plataformas sociales!",
    "options": [],
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
    "action": 0,
  },

  "location": {
    "text":
        "¡Perfecto! Ahora, déjame confirmar tu ubicación. Detecté que estás en {location}. ¿Es correcto?",
    "options": ["Sí", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "sendOTP": {
    "text": "¡Genial! Tu correo electrónico es {email}. ¿Es correcto?",
    "options": ["Sí", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailVerification": {
    "text": "¡Perfecto, te acabo de enviar un código a tu correo. 📩",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": true,
    "keyboardType": "text",
  },

  "otpInput": {
    "text":
        "Por favor ingresa el código de verificación que recibiste por correo.",
    "options": ["Reenviar código", "Cambiar correo"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "emailSuccess": {
    "text": "¡Felicidades! ¡Tu correo fue validado! 🎉",
    "options": [],
    "step": "regProgress.emailSuccess", // ✅ Cambiar a su propio step
    "keepTalk": false,
    "autoAdvance": true,
  },

  "avatarUrl": {
    "text":
        "Personalicemos tu perfil. Puedo sugerirte una foto de tus redes sociales conectadas o puedes subir una nueva. ¿Cuál prefieres? 📸",
    "options": [],
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
    "showProfilePictures": true,
  },

  "phone": {
    "text": "¡Perfecto! Ahora, ¿cuál es tu número de teléfono? 📞",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "voiceNoteUrl": {
    "text":
        "¡Genial! Ahora añadamos un toque personal. Por favor, graba una nota de voz corta (1-10 segundos) presentándote 🎤",
    "options": [],
    "step": "regProgress.voiceNoteUrl",
    "keepTalk": false,
  },

  "category": {
    "text": "Elige tus categorías para personalizar tu contenido.",
    "step": "regProgress.category",
    "keepTalk": false,
    "action": 1,
  },
};

/// Preguntas en INGLÉS
final Map<String, Map<String, dynamic>> questionsEn = {
  // "language": {
  //   "text": "👋 Hello! I'm Migozz. What language do you prefer?",
  //   "options": ["English", "Español"],
  //   "step": "regProgress.language",
  //   "keepTalk": false,
  //   "keyboardType": "text",
  // },

  "fullName": {
    "text": "Great! Let's continue in English. What is your full name?",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
    "keyboardType": "text",
  },

  "username": {
    "text":
        "Nice to meet you {fullName}! Now, let's create a unique username for your profile.",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
    "keyboardType": "text",
  },

  // "gender": {
  //   "text": "Great nickname! What is your gender?",
  //   "options": ["Male", "Female"],
  //   "step": "regProgress.gender",
  //   "keepTalk": false,
  //   "keyboardType": "text",
  // },

  "socialEcosystem": {
    "text": "Let's add your social platforms!",
    "options": [],
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
    "action": 0,
  },

  "location": {
    "text":
        "Perfect! Now, let me confirm your location. I detected you're in {location}. Is this correct?",
    "options": ["Yes", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "sendOTP": {
    "text": "Great! Your email is {email}. Is this correct?",
    "options": ["Yes", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailVerification": {
    "text": "Perfect, I just sent you a code to your email. 📩",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": true,
    "keyboardType": "text",
  },

  "otpInput": {
    "text": "Please enter the verification code you received by email.",
    "options": ["Resend code", "Change email"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "emailSuccess": {
    "text": "Congratulations! Your profile is now activated! 🎉",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": true,
  },

  "avatarUrl": {
    "text":
        "Let's personalize your profile. I can suggest a photo from your connected social media or you can upload a new one. Which do you prefer? 📸",
    "options": [],
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
    "showProfilePictures": true,
  },

  "phone": {
    "text": "Perfect! Now, what's your phone number? 📞",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "voiceNoteUrl": {
    "text":
        "Great! Now let's add a personal touch. Please record a short voice note (1-10 seconds) introducing yourself! 🎤",
    "options": [],
    "step": "regProgress.voiceNoteUrl",
    "keepTalk": false,
  },

  "category": {
    "text": "Choose your categories to personalize your content.",
    "step": "regProgress.category",
    "keepTalk": false,
    "action": 1,
  },
};

/// MENSAJES DE ERROR (respuestas inválidas)
final Map<String, Map<String, dynamic>> errorMessagesEs = {
  // "language": {
  //   "text": "Por favor, elige un idioma válido de las opciones.",
  //   "options": ["Español", "English"],
  //   "step": "regProgress.language",
  //   "keepTalk": false,
  // },

  "fullName": {
    "text": "Por favor ingresa tu nombre completo (nombre y apellido).",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
  },

  "username": {
    "text":
        "El nombre de usuario debe tener al menos 3 caracteres y no puede contener espacios.",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
  },

  // "gender": {
  //   "text": "Por favor elige una opción válida.",
  //   "options": ["Hombre", "Mujer", "Otro"],
  //   "step": "regProgress.gender",
  //   "keepTalk": false,
  // },

  "location": {
    "text": "Por favor responde 'Sí' o 'No'.",
    "options": ["Sí", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "sendOTP": {
    "text": "Por favor responde 'Sí' o 'No'.",
    "options": ["Sí", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailVerification": {
    "text": "Por favor ingresa el código de 6 dígitos correctamente.",
    "options": ["Reenviar código", "Cambiar correo"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },

  "phone": {
    "text": "Por favor ingresa un número de teléfono válido.",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
  },

  "avatarUrl": {
    "text":
        "Por favor selecciona una foto de las opciones, súbela desde tu galería o tómala con la cámara. 📸",
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
    "showProfilePictures": true, // ✅ Volver a mostrar las fotos
  },
};

final Map<String, Map<String, dynamic>> errorMessagesEn = {
  // "language": {
  //   "text": "Please choose a valid language from the options.",
  //   "options": ["English", "Español"],
  //   "step": "regProgress.language",
  //   "keepTalk": false,
  // },

  "fullName": {
    "text": "Please enter your full name (first and last name).",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
  },

  "username": {
    "text": "Username must be at least 3 characters and cannot contain spaces.",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
  },

  // "gender": {
  //   "text": "Please choose a valid option.",
  //   "options": ["Male", "Female"],
  //   "step": "regProgress.gender",
  //   "keepTalk": false,
  // },

  "location": {
    "text": "Please answer 'Yes' or 'No'.",
    "options": ["Yes", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "sendOTP": {
    "text": "Please answer 'Yes' or 'No'.",
    "options": ["Yes", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailVerification": {
    "text": "Please enter the 6-digit code correctly.",
    "options": ["Resend code", "Change email"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },

  "phone": {
    "text": "Please enter a valid phone number.",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
  },
};

/// MENSAJES CONTEXTUALES (para keepTalk=true)
final Map<String, Map<String, dynamic>> contextMessagesEs = {
  "addSocialNetwork": {
    "text": "No te preocupes, agreguémosla enseguida",
    "step": "regProgress.socialEcosystem",
    "keepTalk": true,
  },

  "socialNetworkAdded": {
    "text": "¡Genial! Veo que conectaste {socialEcosystem} 📱",
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
  },

  "changeEmail": {
    "text": "De acuerdo, escribe tu correo electrónico nuevamente.",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },
};

final Map<String, Map<String, dynamic>> contextMessagesEn = {
  "addSocialNetwork": {
    "text": "Don't worry, let's add it right away",
    "step": "regProgress.socialEcosystem",
    "keepTalk": true,
  },

  "socialNetworkAdded": {
    "text": "Great! I see you connected {socialEcosystem} 📱",
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
  },

  "changeEmail": {
    "text": "Alright, please enter your email address again.",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },
};

/// Helper: Obtener pregunta según idioma
Map<String, dynamic>? getQuestion(String stepKey, bool isSpanish) {
  final questions = isSpanish ? questionsEs : questionsEn;
  return questions[stepKey] != null
      ? Map<String, dynamic>.from(questions[stepKey]!)
      : null;
}

/// Helper: Obtener mensaje de error según idioma
Map<String, dynamic>? getErrorMessage(String stepKey, bool isSpanish) {
  final errors = isSpanish ? errorMessagesEs : errorMessagesEn;
  return errors[stepKey] != null
      ? Map<String, dynamic>.from(errors[stepKey]!)
      : null;
}

/// Helper: Obtener mensaje contextual según idioma
Map<String, dynamic>? getContextMessage(String contextKey, bool isSpanish) {
  final contexts = isSpanish ? contextMessagesEs : contextMessagesEn;
  return contexts[contextKey] != null
      ? Map<String, dynamic>.from(contexts[contextKey]!)
      : null;
}

/// Helper: Reemplazar valores dinámicos en el texto
String replaceDynamicValues(String text, Map<String, dynamic> values) {
  String result = text;

  values.forEach((key, value) {
    result = result.replaceAll('{$key}', value?.toString() ?? '');
  });

  return result;
}
