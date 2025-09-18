class IaChatService {
  bool _isEnglish = true; // por defecto inglés
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _questionsEn = [
    {
      "text":
          "Hello! 👋 I´m here to help you set up your profile. Let’s start: What is your preferred language?",
      "options": ["English", "Español"],
    },
    {
      "text": "Great! Let’s continue in English. What is your name?",
      "options": [],
    },
    {
      "text": "Thank you. Can you indicate your gender?",
      "options": ["Male", "Female", "Other"],
    },
    {
      "text":
          "We have detected that you are in this country, the United States, is that correct?",
      "options": ["Yes, correct", "No"],
    },
    {
      "text":
          "Please review your information and confirm it: - Language: English - Name: Taylor - Date of birth: 1997 - Gender: Female - Country: United States. Is this information correct?",
      "options": ["Yes, that's correct", "No, isn't correct"],
    },
    {
      "text":
          "Awesome! Now, please enter a username or nickname you’d like to use.",
      "options": [],
    },
  ];

  final List<Map<String, dynamic>> _questionsEs = [
    {
      "text":
          "¡Hola! 👋 Estoy aquí para ayudarte a configurar tu perfil. Empecemos: ¿Cuál es tu idioma preferido?",
      "options": ["English", "Español"],
    },
    {
      "text": "¡Genial! Continuemos en Español. ¿Cuál es tu nombre?",
      "options": [],
    },
    {
      "text": "Gracias. ¿Puedes indicar tu género?",
      "options": ["Hombre", "Mujer", "Otro"],
    },
    {
      "text":
          "Hemos detectado que estás en este país, Estados Unidos, ¿es correcto?",
      "options": ["Sí, correcto", "No"],
    },
    {
      "text":
          "Por favor revisa tu información y confírmala: - Idioma: Español - Nombre: Taylor - Fecha de nacimiento: 1997 - Género: Mujer - País: Estados Unidos. ¿Es correcto?",
      "options": ["Sí, es correcto", "No, no es correcto"],
    },
    {
      "text":
          "¡Perfecto! Ahora, por favor ingresa un nombre de usuario o apodo que quieras usar.",
      "options": [],
    },
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
          ? "Thanks for completing the form! 🎉"
          : "¡Gracias por completar el formulario! 🎉",
      "options": []
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
