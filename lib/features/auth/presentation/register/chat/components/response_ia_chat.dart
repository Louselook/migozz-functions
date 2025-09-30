import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_state.dart';

class IaChatService {
  bool _isEnglish = true; // por defecto inglés
  int currentIndex = 0;

  final List<Map<String, dynamic>> _questionsEn = [
    {
      "text":
          "Hello! 👋 I´m here to help you set up your profile. Let’s start: What is your preferred language?",
      "options": [],
      "keyboardType": "text",
    },
    {
      "text": "Great! Let’s continue in English. What is your full name?",
      "options": [],
      "keyboardType": "text",
    },
    {
      "text":
          "Nice to meet you {fullName}! Now, let's create a unique username for your profile.",
      "options": [],
      "keyboardType": "text",
    },
    {"text": "Great nickname! Are you a man or a woman?", "options": [], "keyboardType": "text"},
    {"text": "Let's add your social platforms!", "options": [], "action": 0},
    {
      "text": "Awesome! I can see you've connected {socialEcosystem}. 📱",
      "options": [],
      "dinamicResponse": "SocialEcosystemStep", // 👈 flag especial
    },
    {
      "text":
          "Perfect! Now, let me confirm your location. I detected you're in {location}. Is this correct?",
      "options": [],
    },
    {"text": "Great! Your email is {email}. Is this correct?", "options": [], "keyboardType": "text"},
    {
      "text":
          "Perfect! Please check your email for a confirmation link to activate your profile! 📧",
      "options": [],
      "keyboardType": "number", // <-- OTP espera número
    },
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
    {
      "text":
          "Which one would you like to use? Or would you prefer to upload a custom photo?",
      "options": [],
    },
    {"text": "Perfect! Now, what's your phone number? 📞", "options": [], "keyboardType": "number"},
    {
      "text":
          "Great! Now let's add a personal touch. Please record a short voice note (5-10 seconds) introducing yourself! 🎤",
      "options": [],
    },
  ];

  final List<Map<String, dynamic>> _questionsEs = [
    {
      "text":
          "¡Hola! 👋 Estoy aquí para ayudarte a configurar tu perfil. Empecemos: ¿Cuál es tu idioma preferido?",
      "options": [],
      "keyboardType": "text",
    },
    {
      "text": "¡Genial! Continuemos en Español. ¿Cuál es tu nombre completo?",
      "options": [],
      "keyboardType": "text",
    },
    {
      "text":
          "¡Encantado de conocerte, {fullName}! Ahora, vamos a crear un nombre de usuario único para tu perfil.",
      "options": [],
      "keyboardType": "text",
    },
    {"text": "¡Excelente apodo! ¿Eres hombre o mujer?", "options": [], "keyboardType": "text"},
    {
      "text": "¡Agreguemos tus plataformas sociales!",
      "options": [],
      "action": 0,
    },
    {
      "text": "¡Genial! Veo que conectaste {socialEcosystem}. 📱",
      "options": [],
      "dinamicResponse": "SocialEcosystemStep", // 👈 flag especial
    },
    {
      "text":
          "¡Perfecto! Ahora, déjame confirmar tu ubicación. Detecté que estás en {location}. ¿Es correcto?",
      "options": [],
    },
    {
      "text": "¡Genial! Tu correo electrónico es {email}. ¿Es correcto?",
      "options": [],
      "keyboardType": "text",
    },
    {
      "text":
          "¡Perfecto! Revisa tu correo electrónico para ver el enlace de confirmación para activar tu perfil. 📧",
      "options": [],
      "keyboardType": "number", // <-- OTP espera número
    },
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
    {
      "text":
          "¿Cuál te gustaría usar? ¿O prefieres subir una foto personalizada?",
      "options": [],
    },
    {
      "text": "¡Perfecto! Ahora, ¿cuál es tu número de teléfono? 📞",
      "options": [],
      "keyboardType": "number",
    },
    {
      "text":
          "¡Genial! Ahora añadamos un toque personal. Por favor, graba una nota de voz corta (5-10 segundos) presentándote 🎤",
      "options": [],
    },
  ];

  /// Devuelve la siguiente pregunta con los valores dinámicos reemplazados
  Map<String, dynamic>? getNextBotResponse(RegisterCubit cubit) {
    final questions = _isEnglish ? _questionsEn : _questionsEs;
    if (currentIndex < questions.length) {
      var response = questions[currentIndex];
      currentIndex++;

      response["text"] = _replaceDynamicValues(response["text"], cubit.state);

      return response;
    }
    return {
      "text": _isEnglish
          ? "Perfect recording! Now, what best describes you professionally?"
          : "¡Grabación perfecta! Ahora, ¿qué te describe mejor profesionalmente?",
      "action": 1,
      "keyboardType": "text",
    };
  }

  String _replaceDynamicValues(String text, RegisterState state) {
    text = text.replaceAll("{fullName}", state.fullName ?? "User");

    text = text.replaceAll(
      "{socialEcosystem}",
      state.socialEcosystem?.join(", ") ?? "your social media",
    );

    // 👇 CAMBIAR ESTO
    text = text.replaceAll(
      "{location}",
      state.location != null
          ? "${state.location!.city}, ${state.location!.country}"
          : "your location",
    );

    text = text.replaceAll("{email}", state.email ?? "your email");

    return text;
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
    currentIndex = 0;
    _isEnglish = true;
  }
}
