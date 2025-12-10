// final List language = [
//   // Primera
//   {
//     "text": "👋 ¡Hola! Soy Migozz. ¿En qué idioma prefieres continuar?",
//     "options": ["Español", "English"],
//     "step": "regProgress.language",
//     "keepTalk": false,
//   },

//   // Rechazo
//   {
//     "text": "Respuesta no válida, por favor elige un idioma.",
//     "options": ["Español", "English"],
//     "step": "regProgress.language",
//     "keepTalk": false,
//     "valid": false,
//   },

//   // Válida
//   {
//     "text": "Perfecto seguiremos en Español, ¿cuál es tu nombre completo?",
//     "step": "regProgress.fullName",
//     "keepTalk": false,
//     "valid": true,
//     "userResponse": "Español",
//   },
// ];

final List fullName = [
  // Primera
  {
    "text": "Perfecto, ¿cuál es tu nombre completo?",
    "step": "regProgress.fullName",
    "keepTalk": false,
  },

  // Rechazo
  {
    "text": "Por favor, ingresa tu nombre completo para continuar.",
    "step": "regProgress.fullName",
    "keepTalk": false,
    "valid": false,
  },

  // Válida
  {
    "text":
        "¡Encantado de conocerte, Juan Pérez! Ahora, vamos a crear un nombre de usuario único para tu perfil.",
    "step": "regProgress.username",
    "keepTalk": false,
    "valid": true,
    "userResponse": "Juan Pérez",
  },
];

final List username = [
  // Primera
  {
    "text": "Genial, elige un nombre de usuario único.",
    "step": "regProgress.username",
    "keepTalk": false,
  },

  // Rechazo
  {
    "text": "El nombre de usuario no es válido o ya existe. Prueba con otro.",
    "step": "regProgress.username",
    "keepTalk": false,
    "valid": false,
  },

  // Válida
  // {
  //   "text": "¡Excelente apodo! ¿Cuál es tu género?",
  //   "step": "regProgress.gender",
  //   "keepTalk": false,
  //   "valid": true,
  //   "userResponse": "juanp",
  // },
];

// final List gender = [
//   // Primera
//   {
//     "text": "¿Cuál es tu género?",
//     "options": ["Hombre", "Mujer", "Otro"],
//     "step": "regProgress.gender",
//     "keepTalk": false,
//   },

//   // Rechazo
//   {
//     "text": "Por favor selecciona una opción válida.",
//     "options": ["Hombre", "Mujer", "Otro"],
//     "step": "regProgress.gender",
//     "keepTalk": false,
//     "valid": false,
//   },

  // Válida
  // {
  //   "text": "Perfecto, ahora agreguemos tus redes sociales.",
  //   "step": "regProgress.socialEcosystem",
  //   "keepTalk": false,
  //   "valid": true,
  //   "userResponse": "Hombre",
  // },
// ];

// final List socialEcosystem = [
//   // Primera
//   {
//     "text": "¡Agreguemos tus redes sociales!",
//     "step": "regProgress.socialEcosystem",
//     "keepTalk": false,
//   },

//   // Rechazo
//   {
//     "text": "No se pudo conectar la red social. Inténtalo nuevamente.",
//     "step": "regProgress.socialEcosystem",
//     "keepTalk": false,
//     "valid": false,
//   },

//   // Válida
//   {
//     "text": "Perfecto, redes conectadas. Confirmemos tu ubicación.",
//     "step": "regProgress.location",
//     "keepTalk": false,
//     "valid": true,
//   },
// ];

final List location = [
  // Primera - Pregunta de autorización
  {
    "text": "Muy bien, Detectamos que vives en {location}. ¿Deseas usar tu ubicación actual?",
    "options": ["Sí", "No", "Ubicación incorrecta"],
    "step": "regProgress.location",
    "keepTalk": false,
  },

  // Válida - Usuario confirma (Sí)
  {
    "text": "Perfecto, ubicación confirmada. Ahora verifica tu correo electrónico.",
    "step": "regProgress.emailVerification",
    "keepTalk": false,
    "valid": true,
    "userResponse": "Sí",
  },

  // Válida - Usuario rechaza usar ubicación (No)
  {
    "text": "Entendido, continuaremos sin una ubicación específica.",
    "step": "regProgress.emailVerification",
    "keepTalk": false,
    "valid": true,
    "userResponse": "No",
    "emptyLocation": true, //  Bandera para guardar LocationDTO.empty()
  },

  // Rechazo - Ubicación incorrecta (vuelve a preguntar)
  {
    "text": "Entendido. Por favor, ingresa tu ubicación manualmente o intenta detectarla nuevamente.",
    "step": "regProgress.location",
    "keepTalk": false,
    "valid": false,
    "userResponse": "Ubicación incorrecta",
  },

  // Rechazo - Respuesta inválida
  {
    "text": "Por favor, selecciona una opción válida: Sí, No, o Ubicación incorrecta.",
    "options": ["Sí", "No", "Ubicación incorrecta"],
    "step": "regProgress.location",
    "keepTalk": false,
    "valid": false,
  },
];

final List emailVerification = [
  // Primera
  {
    "text": "Tu correo electrónico es {email}, ¿es correcto?",
    "options": ["Sí", "No"],
    "step": "regProgress.emailVerification",
    "keepTalk": false,
  },

  // Rechazo
  {
    "text":
        "Parece que el correo no es correcto. Intenta ingresarlo nuevamente.",
    "step": "regProgress.emailVerification",
    "keepTalk": false,
    "valid": false,
  },

  // Válida
  {
    "text": "Perfecto, correo verificado. Ahora elige una foto de perfil.",
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
    "valid": true,
    "userResponse": "Sí",
  },
];

final List avatarUrl = [
  // Primera
  {
    "text":
        "Puedo sugerirte una foto de tus redes sociales conectadas o puedes subir una nueva. ¿Cuál prefieres? 📸",
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
  },

  // Rechazo
  {
    "text":
        "No se pudo subir la imagen. Inténtalo de nuevo o elige otra opción.",
    "step": "regProgress.avatarUrl",
    "keepTalk": false,
    "valid": false,
  },

  // Válida
  {
    "text":
        "Excelente, tu foto ha sido actualizada. Ahora necesito tu número de teléfono.",
    "step": "regProgress.phone",
    "keepTalk": false,
    "valid": true,
    "userResponse": "upload",
  },
];

final List phone = [
  // Primera
  {
    "text": "¿Cuál es tu número de teléfono? 📞",
    "step": "regProgress.phone",
    "keepTalk": false,
  },

  // Rechazo
  {
    "text": "El número ingresado no parece válido. Inténtalo nuevamente.",
    "step": "regProgress.phone",
    "keepTalk": false,
    "valid": false,
  },

  // Válida
  {
    "text":
        "Perfecto, número guardado. Ahora graba una nota de voz corta presentándote. 🎤",
    "step": "regProgress.voiceNoteUrl",
    "keepTalk": false,
    "valid": true,
    "userResponse": "+573001112233",
  },
];

final List voiceNoteUrl = [
  // Primera
  {
    "text":
        "Por favor graba una nota de voz corta (1-10 segundos) presentándote. 🎤",
    "step": "regProgress.voiceNoteUrl",
    "keepTalk": false,
  },

  // Rechazo
  {
    "text": "No se detectó la nota de voz. Intenta grabarla nuevamente.",
    "step": "regProgress.voiceNoteUrl",
    "keepTalk": false,
    "valid": false,
  },

  // Válida
  {
    "text": "¡Genial! Ahora selecciona tus categorías de interés. 🎯",
    "step": "regProgress.category",
    "keepTalk": false,
    "valid": true,
  },
];

// final List category = [
//   // Primera
//   {
//     "text": "Elige tus categorías favoritas para personalizar tu experiencia.",
//     "step": "regProgress.category",
//     "keepTalk": false,
//   },

//   // Rechazo
//   {
//     "text": "Debes seleccionar al menos una categoría para continuar.",
//     "step": "regProgress.category",
//     "keepTalk": false,
//     "valid": false,
//   },

//   // Válida
//   {
//     "text": "Perfecto, ahora selecciona tus intereses específicos.",
//     "step": "regProgress.interests",
//     "keepTalk": false,
//     "valid": true,
//   },
// ];

// final List interests = [
//   // Primera
//   {
//     "text": "Selecciona tus intereses para afinar tu experiencia.",
//     "step": "regProgress.interests",
//     "keepTalk": false,
//   },

//   // Rechazo
//   {
//     "text": "Debes elegir al menos un interés para continuar.",
//     "step": "regProgress.interests",
//     "keepTalk": false,
//     "valid": false,
//   },

//   // Válida
//   {
//     "text": "Todo listo. ¡Tu registro está completo! 🎉",
//     "step": "regProgress.done",
//     "keepTalk": false,
//     "valid": true,
//   },
// ];

final List done = [
  // Primera
  {
    "text": "🎉 ¡Registro completado! Bienvenido a Migozz.",
    "step": "regProgress.done",
    "keepTalk": false,
  },

  // Rechazo
  {
    "text": "Hubo un problema al finalizar tu registro. Intenta de nuevo.",
    "step": "regProgress.done",
    "keepTalk": false,
    "valid": false,
  },

  // Válida
  {
    "text": "✅ Registro finalizado correctamente. Disfruta de la app.",
    "step": "regProgress.done",
    "keepTalk": false,
    "valid": true,
  },
];