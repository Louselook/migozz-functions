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
    "text": "¡Hola! Soy Migozz 👋 ¿Cómo te llamas? Dime tu nombre y apellido",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
    "keyboardType": "text",
  },

  "username": {
    "text": "Genial {fullName}, ahora elige un nombre de usuario. Será tu @",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
    "keyboardType": "text",
    "generateSuggestions": true,
  },

  "emailReask": {
    "text": "Tu correo es {email}. ¿Está bien o quieres cambiarlo?",
    "options": ["No, está bien", "Sí, cambiar"],
    "step": "regProgress.emailReask",
    "keepTalk": false,
  },

  "gender": {
    "text": "¿Con qué género te identificas?",
    "options": ["Hombre", "Mujer", "Prefiero no decir"],
    "step": "regProgress.gender",
    "keepTalk": false,
    "keyboardType": "text",
  },
  "socialEcosystem": {
    "text":
        "Ahora conecta tus redes sociales 📱 Es lo más importante de tu perfil",
    "options": [],
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
    "action": 0,
  },

  "location": {
    "text": "Detecté que estás en {location}. ¿Es correcto?",
    "options": ["Sí", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "email": {
    "text": "¿Cuál es tu correo electrónico?",
    "options": [],
    "step": "regProgress.email",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "sendOTP": {
    "text": "Tu correo es {email}, ¿está bien?",
    "options": ["Sí", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailChange": {
    "text": "¿Cuál es tu nuevo correo?",
    "options": [],
    "step": "regProgress.emailChange",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "emailVerification": {
    "text": "📩 Te envié un código de 6 dígitos a {email}",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": true,
    "keyboardType": "text",
  },

  "otpInput": {
    "text": "Escribe el código que te llegó:",
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
    "text": "¿Quieres subir una foto de perfil? 📸",
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
    "text": "¿Cuál es tu número de teléfono?",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "voiceNoteUrl": {
    "text": "Grábate un audio corto presentándote (1-10 seg) 🎤",
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
    "text": "¡Ya casi! ¿Creamos tu cuenta?",
    "options": ["Sí, vamos a Migozz", "Cambiar algo"],
    "step": "regProgress.confirmCreateAccount",
    "keepTalk": false,
    "isFinalConfirmation": true,
  },

  "category": {
    "text": "¿Qué tipo de creador eres? Elige tu categoría 🎯",
    "options": [],
    "step": "regProgress.category",
    "keepTalk": false,
    "action": 1,
    "showTyping": true,
  },

  "interests": {
    "text": "¿Qué temas te interesan? 💡",
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
    "text": "Hey there! I'm Migozz 👋 What's your name? First and last",
    "options": [],
    "step": "regProgress.fullName",
    "keepTalk": false,
    "keyboardType": "text",
  },

  "username": {
    "text":
        "Nice to meet you {fullName}! Now pick a username — this will be your @",
    "options": [],
    "step": "regProgress.username",
    "keepTalk": false,
    "keyboardType": "text",
    "generateSuggestions": true,
  },

  "emailReask": {
    "text": "Your email is {email}. Is that right or want to change it?",
    "options": ["No, it's fine", "Yes, change it"],
    "step": "regProgress.emailReask",
    "keepTalk": false,
  },

  "gender": {
    "text": "What gender do you identify with?",
    "options": ["Male", "Female", "Rather not say"],
    "step": "regProgress.gender",
    "keepTalk": false,
    "keyboardType": "text",
  },
  "socialEcosystem": {
    "text":
        "Time to connect your social networks 📱 This is the most important part of your profile",
    "options": [],
    "step": "regProgress.socialEcosystem",
    "keepTalk": false,
    "action": 0,
  },

  "location": {
    "text": "Looks like you're in {location}. Is that right?",
    "options": ["Yes", "No"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  "email": {
    "text": "What's your email?",
    "options": [],
    "step": "regProgress.email",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "sendOTP": {
    "text": "Your email is {email}, right?",
    "options": ["Yes", "No"],
    "step": "regProgress.sendOTP",
    "keepTalk": false,
  },

  "emailChange": {
    "text": "What's your new email?",
    "options": [],
    "step": "regProgress.emailChange",
    "keepTalk": false,
    "keyboardType": "email",
  },

  "emailVerification": {
    "text": "📩 I just sent a 6-digit code to {email}",
    "options": [],
    "step": "regProgress.emailVerification",
    "keepTalk": true,
    "keyboardType": "text",
  },

  "otpInput": {
    "text": "Type the code you received:",
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
    "text": "Want to add a profile photo? 📸",
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
    "text": "What's your phone number?",
    "options": [],
    "step": "regProgress.phone",
    "keepTalk": false,
    "keyboardType": "number",
  },

  "voiceNoteUrl": {
    "text": "Record a quick intro about yourself (1-10 sec) 🎤",
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
    "text": "Almost there! Ready to create your account?",
    "options": ["Yes, go to Migozz", "Change something"],
    "step": "regProgress.confirmCreateAccount",
    "keepTalk": false,
    "isFinalConfirmation": true,
  },

  "category": {
    "text": "What kind of creator are you? Pick your category 🎯",
    "options": [],
    "step": "regProgress.category",
    "keepTalk": false,
    "action": 1,
    "showTyping": true,
  },

  "interests": {
    "text": "What topics are you into? 💡",
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
