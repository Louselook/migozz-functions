final List<Map<String, Object>> questionsTopics = [
  // {
  //   "id": "language",
  //   "description":
  //       "Pregunta inicial para definir el idioma preferido del usuario.",
  //   "text": {
  //     "en":
  //         "Hello! 👋 I´m here to help you set up your profile. Let's start: What is your preferred language?",
  //     "es":
  //         "¡Hola! 👋 Estoy aquí para ayudarte a configurar tu perfil. Empecemos: ¿Cuál es tu idioma preferido?",
  //   },
  //   "options": {
  //     "en": ["English", "Español"],
  //     "es": ["Español", "English"],
  //   },
  //   "keyboardType": "text",
  // },
  {
    "id": "fullName",
    "description": "Solicita el nombre completo del usuario.",
    "text": {
      "en": "Great! Let's continue in English. What is your full name?",
      "es": "¡Genial! Continuemos en Español. ¿Cuál es tu nombre completo?",
    },
    "options": {"en": [], "es": []},
    "keyboardType": "text",
  },
  {
    "id": "username",
    "description":
        "Crea un nombre de usuario único. Puede generar sugerencias si el usuario lo solicita.",
    "text": {
      "en":
          "Nice to meet you {fullName}! Now, let's create a unique username for your profile.",
      "es":
          "¡Encantado de conocerte, {fullName}! Ahora, vamos a crear un nombre de usuario único para tu perfil.",
    },
    "options": {"en": [], "es": []},
    "keyboardType": "text",
  },
  // {
  //   "id": "gender",
  //   "description": "Pregunta el género del usuario.",
  //   "text": {
  //     "en": "Great nickname! What is your gender?",
  //     "es": "¡Excelente apodo! ¿Cuál es tu género?",
  //   },
  //   "options": {
  //     "en": ["Male", "Female", "Other"],
  //     "es": ["Hombre", "Mujer", "Otro"],
  //   },
  //   "keyboardType": "text",
  // },
  // {
  //   "id": "socialEcosystem",
  //   "description":
  //       "Permite al usuario agregar redes sociales. Solo preguntar si aún no tiene datos.",
  //   "text": {
  //     "en": "Let's add your social platforms!",
  //     "es": "¡Agreguemos tus plataformas sociales!",
  //   },
  //   "options": {"en": [], "es": []},
  //   "action": 0,
  // },
  {
    "id": "location",
    "description":
        "Pregunta para autorizar el uso de la ubicación detectada automáticamente. El usuario puede aceptar, rechazar o reportar que es incorrecta.",
    "text": {
      "en":
          "We detected that you live in {location}. Do you want to use your current location?",
      "es":
          "Detectamos que vives en {location}. ¿Deseas usar tu ubicación actual?",
    },
    "options": {
      "en": ["Yes", "No", "Incorrect location"],
      "es": ["Sí", "No", "Ubicación incorrecta"],
    },
  },
  {
    "id": "emailVerification",
    "description": "Verifica el correo del usuario y solicita OTP si aplica.",
    "text": {
      "en": "Great! Your email is {email}. Is this correct?",
      "es": "¡Genial! Tu correo electrónico es {email}. ¿Es correcto?",
    },
    "options": {
      "en": ["Yes", "No"],
      "es": ["Sí", "No"],
    },
    "keyboardType": "text",
  },
  {
    "id": "avatarUrl",
    "description":
        "Pregunta al usuario si desea subir o usar una foto sugerida de redes sociales.",
    "text": {
      "en":
          "Let's personalize your profile. You can upload a photo from your gallery or take a new one with your camera. Which do you prefer? 📸",
      "es":
          "Personalicemos tu perfil. Puedes subir una desde tu galeria o tomar una nueva desde la camara. ¿Cuál prefieres? 📸",
    },
    "options": {"en": ["Skip Step"], "es": ["Saltar paso"]},
  },
  {
    "id": "phone",
    "description": "Solicita el número de teléfono del usuario.",
    "text": {
      "en": "Perfect! Now, what's your phone number? 📞",
      "es": "¡Perfecto! Ahora, ¿cuál es tu número de teléfono? 📞",
    },
    "keyboardType": "number",
    "options": {"en": [], "es": []},
  },
  {
    "id": "voiceNoteUrl",
    "description":
        "Pide al usuario grabar una nota de voz corta como presentación.",
    "text": {
      "en":
          "Great! Now let's add a personal touch. Please record a short voice note (1-10 seconds) introducing yourself! 🎤",
      "es":
          "¡Genial! Ahora añadamos un toque personal. Por favor, graba una nota de voz corta (1-10 segundos) presentándote 🎤",
    },
    "options": {"en": [], "es": []},
  },
  // {
  //   "id": "category",
  //   "description": "Selecciona las categorías de interés del usuario.",
  //   "text": {
  //     "en": "Choose your categories to personalize your content.",
  //     "es": "Elige tus categorías para personalizar tu contenido.",
  //   },
  //   "options": {"en": [], "es": []},
  //   "action": 1,
  // },
  // {
  //   "id": "interests",
  //   "description":
  //       "Selecciona intereses específicos para afinar la experiencia del usuario.",
  //   "text": {
  //     "en": "Pick your interests to refine your experience.",
  //     "es": "Selecciona tus intereses para afinar tu experiencia.",
  //   },
  //   "options": {"en": [], "es": []},
  //   "action": 2,
  // },
  {
    "id": "done",
    "description": "Finaliza el registro y da la bienvenida al usuario.",
    "text": {
      "en": "The registration is complete! Welcome to our community.",
      "es": "El registro está completo. ¡Bienvenido a nuestra comunidad!",
    },
    "options": {"en": [], "es": []},
  },
];