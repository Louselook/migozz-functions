class IaChatService {
  bool _isEnglish = true; // por defecto inglés
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _questionsEn = [
    {
      "text":
          "Hello! 👋 I´m here to help you set up your profile. Let’s start: What is your preferred language?",
      "options": [],
    },
    {
      "text": "Great! Let’s continue in English. What is your full name?",
      "options": [],
    },
    {
      "text":
          "Nice to meet you Insert Name! Now, let's create a unique username for your profile.",
      "options": [],
    },
    {
      "text": "Great nickname! Are you a man or a woman?",
      "options": [], // Quitar
    },
    {
      "text": "Let's add your social platforms!",
      "options": [],
      "action": 0,
    }, // Navegar social abajo
    {
      "text":
          "Awesome! I can see you've connected TikTok, Instagram, YouTube, and X. 📱",
      "options": [],
      "dinamicResponse": "SocialEcosystemStep", // 👈 flag especial
    },
    {
      "text":
          "Perfect! Now, let me confirm your location. I detected you're in Bogotá, Colombia 🇨🇴. Is this correct?",
      "options": [],
    },
    {
      "text": "Great! Your email is john.doe@email.com. Is this correct?",
      "options": [],
    },
    {
      "text":
          "Perfect! Please check your email for a confirmation link to activate your profile! 📧",
      "options": [],
      "dinamicResponse": "CheckEmail",
    },
    // AI ASSISTANT- PART 2
    // mensajes seguidos
    {
      "text": "Congratulations! Your profile is now activated! 🎉",
      "options": [],
      "dinamicResponse": "FollowedMessages",
    },
    {
      "text":
          "Now let's personalize your profile. First, let's add a profile picture! 📸",
      "options": [],
    },
    {
      "text":
          "I can suggest some options from your connected social media, or you can upload a new one.",
      "options": [],
    },
    // dspus iconos o la opcion en el menu
    {
      "text":
          "Which one would you like to use? Or would you prefer to upload a custom photo?",
      "options": [],
    },
    // seguidos hasta aqui, aqui respondeemos
    {"text": "Perfect! Now, what's your phone number? 📞", "options": []},
    {
      "text":
          "Great! Now let's add a personal touch. Please record a short voice note (5-10 seconds) introducing yourself! 🎤",
      "options": [],
    }, // audio
    // por ultimo
    // Choose Your Category
    // Choose Your Interests
    // My Profile - Resultado Final
    // Profile (Other Users)
  ];

  final List<Map<String, dynamic>> _questionsEs = [
    {
      "text":
          "¡Hola! 👋 Estoy aquí para ayudarte a configurar tu perfil. Empecemos: ¿Cuál es tu idioma preferido?",
      "options": [],
    },
    {
      "text": "¡Genial! Continuemos en Español. ¿Cuál es tu nombre completo?",
      "options": [],
    },
    {
      "text":
          "¡Encantado de conocerte, Insertar Nombre! Ahora, vamos a crear un nombre de usuario único para tu perfil.",
      "options": [],
    },
    {
      "text": "¡Excelente apodo! ¿Eres hombre o mujer?",
      "options": [], // Quitar
    },
    {
      "text": "¡Agreguemos tus plataformas sociales!",
      "options": [],
      "action": 0,
    }, // Navegar social abajo

    {
      "text": "¡Genial! Veo que conectaste TikTok, Instagram, YouTube y X. 📱",
      "options": [],
      "dinamicResponse": "SocialEcosystemStep", // 👈 flag especial
    },
    {
      "text":
          "¡Perfecto! Ahora, déjame confirmar tu ubicación. Detecté que estás en Bogotá, Colombia 🇨🇴. ¿Es correcto?",
      "options": [],
    },
    {
      "text":
          "¡Perfecto! Revisa tu correo electrónico para ver el enlace de confirmación para activar tu perfil. 📧",
      "options": [],
      "dinamicResponse": "CheckEmail",
    },
    // AI ASSISTANT- PARTE 2
    // mensajes seguidos
    {
      "text": "¡Felicidades! ¡Tu perfil ya está activado! 🎉",
      "options": [],
      "dinamicResponse": "FollowedMessages",
    },
    {
      "text":
          "Ahora personalicemos tu perfil. ¡Primero, vamos a añadir una foto de perfil! 📸",
      "options": [],
    },
    {
      "text":
          "Puedo sugerirte algunas opciones de tus redes sociales conectadas, o puedes subir una nueva.",
      "options": [],
    },
    // después iconos o la opción en el menú
    {
      "text":
          "¿Cuál te gustaría usar? ¿O prefieres subir una foto personalizada?",
      "options": [],
    },
    // seguidos hasta aquí, aquí respondemos
    {
      "text": "¡Perfecto! Ahora, ¿cuál es tu número de teléfono? 📞",
      "options": [],
    },
    {
      "text":
          "¡Genial! Ahora añadamos un toque personal. Por favor, graba una nota de voz corta (5-10 segundos) presentándote 🎤",
      "options": [],
    }, // audio
    // por ultimo
    // Choose Your Category
    // Choose Your Interests
    // My Profile - Resultado Final
    // Profile (Other Users)
  ];

  /// Devuelve la siguiente pregunta
  Map<String, dynamic>? getNextBotResponse() {
    final questions = _isEnglish ? _questionsEn : _questionsEs;
    if (_currentIndex < questions.length) {
      final response = questions[_currentIndex];
      _currentIndex++;
      return response;
    }
    return {
      "text": _isEnglish
          ? "Perfect recording! Now, what best describes you professionally?"
          : "¡Grabación perfecta! Ahora, ¿qué te describe mejor profesionalmente?",
      // "dinamicResponse": 'doneChat',
      "action": 1,
    };
  }

  /// Detecta si el usuario eligió idioma
  void setLanguage(String choice) {
    if (choice.toLowerCase().contains("es")) {
      _isEnglish = false;
    } else {
      _isEnglish = true;
    }
  }

  void reset() {
    _currentIndex = 0;
    _isEnglish = true;
  }
}
