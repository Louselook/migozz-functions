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
    "text":
        "Bienvenido a Migozz. Estás a punto de crear tu nuevo ecosistema social digital. Por favor, ¿cuál es tu nombre y apellido?",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
    "keyboardType": "text",
  },

  "username": {
    "text": "Perfecto {fullName}. Elige tu apodo:",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
    "keyboardType": "text",
    "generateSuggestions": true,
  },

  "emailReask": {
    "text": "Tu correo actual es: {email}. ¿Deseas cambiarlo?",
    "options": ["No, está bien", "Sí, cambiar"],
    "step": "regProgress.emailReask",
    "keepTalk": false,
  },

  "gender": {
    "text": "¿Cuál es tu género?",
    "options": ["Hombre", "Mujer", "Prefiero no decir"],
    "step": "regProgress.gender",
    "keepTalk": false,
    "keyboardType": "text",
  },
  "socialEcosystem": {
    "text": "¡Casi terminamos! Vincula tus redes sociales 📱",
    "options": [],
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
    "action": 0,
  },

  "location": {
    "text": "¿Te gustaría agregar tu ubicación?",
    "options": ["Yes", "Rather not say"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "email": {
    "text": "Ingresa tu correo electrónico:",
    "options": [],
    "step": "regProgress.email",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "sendOTP": {
    "text": "Tu correo: {email}. ¿Es correcto?",
    "options": ["Sí", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailChange": {
    "text": "Por favor, ingresa tu nuevo correo electrónico:",
    "options": [],
    "step": "regProgress.emailChange",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "emailVerification": {
    "text": "📩 Se ha enviado un código de 6 dígitos a {email}.",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": true,
    "keyboardType": "text",
  },

  "otpInput": {
    "text": "Ingresa el código de 6 dígitos:",
    "options": ["Reenviar código", "Cambiar correo"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "emailSuccess": {
    "text": "✅ Correo verificado.",
    "options": [],
    "step": "regProgress.emailSuccess",
    "keepTalk": false,
    "autoAdvance": true,
  },

  "avatarUrl": {
    "text": "Foto de perfil. Elige una opción:",
    "options": [
      {"label": "Saltar", "action": "skip"},
      {"label": "Cámara", "action": "open_camera"},
      {"label": "Galería", "action": "open_gallery"},
    ],
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
    "showProfilePictures": true,
  },

  "phone": {
    "text": "Tu número de teléfono:",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "voiceNoteUrl": {
    "text": "Graba una nota de voz (1-10s) presentándote 🎤",
    "options": [
      {"label": "Saltar", "action": "skip"},
    ],
    "step": "regProgress.voiceNoteUrl",
    "keepTalk": false,
  },

  "termsAndConditions": {
    "text":
        "Antes de crear tu cuenta, necesito que revises y aceptes nuestros Términos y Condiciones 📄",
    "options": [],
    "step": "regProgress.termsAndConditions",
    "keepTalk": false,
    "action": 3,
    "showTyping": true,
  },

  "confirmCreateAccount": {
    "text": "¿Listo para crear tu cuenta?",
    "options": ["Sí, vamos a Migozz", "Cambiar algo"],
    "step": "regProgress.confirmCreateAccount",
    "keepTalk": false,
    "isFinalConfirmation": true,
  },

  "category": {
    "text":
        "Seleccione el tipo de perfil de cuenta que aparecerá en la pantalla. 🎯",
    "options": [],
    "step": "regProgress.category",
    "keepTalk": false,
    "action": 1,
    "showTyping": true,
  },

  "interests": {
    "text": "Prepárate para seleccionar tus intereses 💡",
    "options": [],
    "step": "regProgress.interests",
    "keepTalk": false,
    "action": 2,
    "showTyping": true,
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
    "text":
        "Welcome to Migozz. You're about to create your new digital social ecosystem. Please, what is your first and last name?",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
    "keyboardType": "text",
  },

  "username": {
    "text": "Got it {fullName}. Choose your Username:",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
    "keyboardType": "text",
    "generateSuggestions": true,
  },

  "emailReask": {
    "text": "Your current email is: {email}. Would you like to change it?",
    "options": ["No, it's fine", "Yes, change it"],
    "step": "regProgress.emailReask",
    "keepTalk": false,
  },

  "gender": {
    "text": "What is your gender?",
    "options": ["Male", "Female", "Rather not say"],
    "step": "regProgress.gender",
    "keepTalk": false,
    "keyboardType": "text",
  },
  "socialEcosystem": {
    "text": "Almost done! Link your social networks 📱",
    "options": [],
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
    "action": 0,
  },

  "location": {
    "text": "Would you like to add your location?",
    "options": ["Yes", "Rather not say"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "email": {
    "text": "Enter your email address:",
    "options": [],
    "step": "regProgress.email",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "sendOTP": {
    "text": "Your email: {email}. Is this correct?",
    "options": ["Yes", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailChange": {
    "text": "Please enter your new email address:",
    "options": [],
    "step": "regProgress.emailChange",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "emailVerification": {
    "text": "📩 A 6-digit code has been sent to {email}.",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": true,
    "keyboardType": "text",
  },

  "otpInput": {
    "text": "Enter the 6-digit code:",
    "options": ["Resend code", "Change email"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "emailSuccess": {
    "text": "✅ Email verified.",
    "options": [],
    "step": "regProgress.emailSuccess",
    "keepTalk": false,
    "autoAdvance": true,
  },

  "avatarUrl": {
    "text": "Profile photo. Choose an option:",
    "options": [
      {"label": "Skip", "action": "skip"},
      {"label": "Camera", "action": "open_camera"},
      {"label": "Gallery", "action": "open_gallery"},
    ],
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
    "showProfilePictures": true,
  },

  "phone": {
    "text": "Your phone number:",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "voiceNoteUrl": {
    "text": "Record a voice note (1-10s) introducing yourself 🎤",
    "options": [
      {"label": "Skip", "action": "skip"},
    ],
    "step": "regProgress.voiceNoteUrl",
    "keepTalk": false,
  },

  "termsAndConditions": {
    "text":
        "Before creating your account, please review and accept our Terms & Conditions 📄",
    "options": [],
    "step": "regProgress.termsAndConditions",
    "keepTalk": false,
    "action": 3,
    "showTyping": true,
  },

  "confirmCreateAccount": {
    "text": "Ready to create your account?",
    "options": ["Yes, go to Migozz", "Change something"],
    "step": "regProgress.confirmCreateAccount",
    "keepTalk": false,
    "isFinalConfirmation": true,
  },

  "category": {
    "text": "Select your type of account profile screen coming up 🎯",
    "options": [],
    "step": "regProgress.category",
    "keepTalk": false,
    "action": 1,
    "showTyping": true,
  },

  "interests": {
    "text": "Get ready interest selection coming up 💡",
    "options": [],
    "step": "regProgress.interests",
    "keepTalk": false,
    "action": 2,
    "showTyping": true,
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
    "text": "Necesito tu nombre y apellido para continuar.",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
  },

  "username": {
    "text": "El usuario debe tener al menos 3 letras y sin espacios.",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
  },

  "gender": {
    "text": "Elige una de las opciones que te di 😊",
    "options": ["Hombre", "Mujer", "Prefiero no decir"],
    "step": "regProgress.gender",
    "keepTalk": false,
  },
  "location": {
    "text": "Solo dime Sí o No 😊",
    "options": ["Sí", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "email": {
    "text":
        "Hmm, eso no parece un correo válido. Prueba algo como tu@correo.com",
    "options": [],
    "step": "regProgress.email",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "sendOTP": {
    "text": "Solo dime Sí o No 😊",
    "options": ["Sí", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailVerification": {
    "text": "Ese código no es correcto. ¿Lo intentas de nuevo?",
    "options": ["Reenviar código", "Cambiar correo"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },

  "phone": {
    "text": "Ese número no parece válido. Intenta de nuevo.",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
  },

  // "avatarUrl": {
  //   "text":
  //       "Por favor selecciona una foto de las opciones, súbela desde tu galería o tómala con la cámara. 📸",
  //   "step": "regProgress.avatarUrl",
  //   "keepTalk": false,
  //   "showProfilePictures": true, // ✅ Volver a mostrar las fotos
  // },
};

final Map<String, Map<String, dynamic>> errorMessagesEn = {
  // "language": {
  //   "text": "Please choose a valid language from the options.",
  //   "options": ["English", "Español"],
  //   "step": "regProgress.language",
  //   "keepTalk": false,
  // },
  "fullName": {
    "text": "I need your first and last name to continue.",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
  },

  "username": {
    "text": "Your username needs at least 3 characters with no spaces.",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
  },

  "gender": {
    "text": "Pick one of the options I gave you 😊",
    "options": ["Male", "Female", "Rather not say"],
    "step": "regProgress.gender",
    "keepTalk": false,
  },
  "location": {
    "text": "Just tell me Yes or No 😊",
    "options": ["Yes", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "email": {
    "text":
        "Hmm, that doesn't look like a valid email. Try something like you@email.com",
    "options": [],
    "step": "regProgress.email",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "sendOTP": {
    "text": "Just tell me Yes or No 😊",
    "options": ["Yes", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailVerification": {
    "text": "That code didn't work. Want to try again?",
    "options": ["Resend code", "Change email"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },

  "phone": {
    "text": "That doesn't look like a valid number. Try again.",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
  },
};

/// MENSAJES CONTEXTUALES (para keepTalk=true)
final Map<String, Map<String, dynamic>> contextMessagesEs = {
  "addSocialNetwork": {
    "text": "Agregando red social...",
    "step": "regProgress.socialEcosystem",
    "keepTalk": true,
  },

  "socialNetworkAdded": {
    "text": "✓ Conectado: {socialEcosystem}",
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
  },

  "changeEmail": {
    "text": "\u00bfCu\u00e1l es tu nuevo correo?",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },
};

final Map<String, Map<String, dynamic>> contextMessagesEn = {
  "addSocialNetwork": {
    "text": "Adding social network...",
    "step": "regProgress.socialEcosystem",
    "keepTalk": true,
  },

  "socialNetworkAdded": {
    "text": "✓ Connected: {socialEcosystem}",
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
