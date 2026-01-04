/// Context information about Migozz platform
/// This file contains comprehensive information about the app's purpose and why each data point is needed

class MigozzContext {
  /// Platform description
  static const String platformDescriptionES = '''
Migozz es una plataforma centralizada para creadores de contenido donde pueden:
- Mostrar todas sus redes sociales en un solo perfil
- Demostrar su alcance, tipo de contenido y audiencia
- Funcionar como portafolio profesional
- Ser descubiertos por marcas, empresas e interesados en contratar sus servicios
- Conectar con oportunidades laborales basadas en su ubicación y especialidad
''';

  static const String platformDescriptionEN = '''
Migozz is a centralized platform for content creators where they can:
- Showcase all their social networks in one profile
- Demonstrate their reach, content type, and audience
- Function as a professional portfolio
- Be discovered by brands, companies, and interested in hiring their services
- Connect with job opportunities based on their location and specialty
''';

  /// Field purposes with context
  static final Map<String, Map<String, String>> fieldContextES = {
    'fullName': {
      'purpose': 'Identificación Personal',
      'why':
          'Tu nombre completo es la base de tu identidad profesional en Migozz. Es lo que otros creadores y potenciales clientes verán primero.',
      'benefit':
          'Permite que la gente te conozca por tu nombre real y construya confianza contigo.',
    },
    'username': {
      'purpose': 'Usuario Único',
      'why':
          'Tu nombre de usuario es tu identidad digital en Migozz. Es cómo otros te encontrarán y cómo aparecerás en perfiles, búsquedas y recomendaciones.',
      'benefit':
          'Hace que seas identificable y buscable. Un buen username aumenta tus posibilidades de ser encontrado.',
    },
    'location': {
      'purpose': 'Ubicación Geográfica',
      'why':
          'Las marcas y empresas buscan creadores en su región. Tu ubicación permite que te descubran personas interesadas en tus servicios que estén cerca de ti.',
      'benefit':
          'Aumenta oportunidades locales. Muchos negocios prefieren trabajar con creadores de su zona porque facilita colaboraciones presenciales y entienden mejor el mercado local.',
      'examples':
          'Una agencia en Ciudad de México buscará influencers CDMX. Un e-commerce en Barcelona buscará creadores de Cataluña.',
    },
    'phone': {
      'purpose': 'Contacto Directo',
      'why':
          'Las empresas e interesados en tus servicios necesitan una forma segura de contactarte. Tu teléfono es el método más directo y rápido.',
      'benefit':
          'No pierdes oportunidades laborales. Muchos negocios no quieren esperar emails y prefieren contacto inmediato.',
      'security':
          'No compartimos tu número públicamente. Solo se usa para verificación de cuenta y contacto directo desde nuestro sistema.',
    },
    'voiceNoteUrl': {
      'purpose': 'Presentación Personal',
      'why':
          'Una nota de voz (5-10s) de presentación hace tu perfil más auténtico y personal. Las personas escuchan tu voz, tono y personalidad.',
      'benefit':
          'Diferencia tu perfil. Potenciales clientes prefieren creadores que se tomen tiempo para una presentación personal. Transmite profesionalismo y seriedad.',
      'psychology':
          'La voz humaniza el perfil. La gente conecta mejor contigo cuando te escucha.',
    },
    'avatarUrl': {
      'purpose': 'Identidad Visual',
      'why':
          'Tu foto hace tu perfil reconocible y confiable. Los creadores con fotos reciben 3x más contactos que sin foto.',
      'benefit':
          'Aumenta contactos y oportunidades. Una buena foto profesional comunica que eres serio con tu trabajo.',
      'research':
          'Estudios muestran que perfiles con foto son vistos como más confiables y profesionales.',
    },
    'socialEcosystem': {
      'purpose': 'Portafolio de Trabajo',
      'why':
          'Tus redes sociales son el CORAZÓN de tu perfil. Ahí demuestras tu verdadero alcance, tipo de contenido, calidad, y capacidad de generar audiencia.',
      'benefit':
          'Sin redes verificadas, tu perfil no tiene valor. Las redes sociales son la prueba de que REALMENTE tienes audiencia y que sabes crear contenido que conecta.',
      'brands':
          'Las marcas SIEMPRE verifican tus redes antes de ofrecerte trabajo. Es donde ven tus números reales: seguidores, engagement, calidad de contenido.',
      'key': 'Este es el dato MÁS importante. Define tu valor como creador.',
    },
  };

  static final Map<String, Map<String, String>> fieldContextEN = {
    'fullName': {
      'purpose': 'Personal Identification',
      'why':
          'Your full name is the foundation of your professional identity on Migozz. It\'s what other creators and potential clients see first.',
      'benefit':
          'Allows people to know you by your real name and build trust with you.',
    },
    'username': {
      'purpose': 'Unique Identity',
      'why':
          'Your username is your digital identity on Migozz. It\'s how others will find you and how you\'ll appear in profiles, searches, and recommendations.',
      'benefit':
          'Makes you identifiable and searchable. A good username increases your chances of being found.',
    },
    'location': {
      'purpose': 'Geographic Location',
      'why':
          'Brands and companies search for creators in their region. Your location lets people interested in your services discover you if they\'re near you.',
      'benefit':
          'Increases local opportunities. Many businesses prefer working with creators in their area because it facilitates in-person collaborations.',
      'examples':
          'An agency in New York will search for influencers in NYC. A local startup in LA will look for creators in California.',
    },
    'phone': {
      'purpose': 'Direct Contact',
      'why':
          'Companies interested in your services need a secure way to contact you. Your phone is the fastest and most direct method.',
      'benefit':
          'You don\'t miss job opportunities. Many businesses don\'t want to wait for emails and prefer immediate contact.',
      'security':
          'We don\'t share your number publicly. It\'s only used for account verification and direct contact through our system.',
    },
    'voiceNoteUrl': {
      'purpose': 'Personal Presentation',
      'why':
          'A short voice note (5-10s) introduction makes your profile more authentic and personal. People hear your voice, tone, and personality.',
      'benefit':
          'Differentiates your profile. Potential clients prefer creators who take time for a personal introduction. It shows professionalism and seriousness.',
      'psychology':
          'Voice humanizes your profile. People connect better when they hear you.',
    },
    'avatarUrl': {
      'purpose': 'Visual Identity',
      'why':
          'Your photo makes your profile recognizable and trustworthy. Creators with photos receive 3x more inquiries than without.',
      'benefit':
          'Increases contacts and opportunities. A good professional photo communicates that you\'re serious about your work.',
      'research':
          'Studies show that profiles with photos are viewed as more trustworthy and professional.',
    },
    'socialEcosystem': {
      'purpose': 'Work Portfolio',
      'why':
          'Your social networks are the HEART of your profile. They prove your real reach, content type, quality, and ability to build an audience.',
      'benefit':
          'Without verified social accounts, your profile has no value. Social networks are proof that you ACTUALLY have an audience.',
      'brands':
          'Brands ALWAYS check your social accounts before offering work. That\'s where they see your real numbers: followers, engagement, content quality.',
      'key':
          'This is the MOST important data. It defines your value as a creator.',
    },
  };

  /// Get context for a specific field based on language
  static Map<String, String>? getFieldContext(
    String fieldKey,
    String language,
  ) {
    final isSpanish =
        language.toLowerCase().contains('español') || language == 'es';
    final contextMap = isSpanish ? fieldContextES : fieldContextEN;
    return contextMap[fieldKey];
  }

  /// Get a formatted explanation for why a field is needed
  static String getWhyExplanation(String fieldKey, String language) {
    final context = getFieldContext(fieldKey, language);
    if (context == null) return '';

    final isSpanish =
        language.toLowerCase().contains('español') || language == 'es';

    // Build a comprehensive explanation
    final buffer = StringBuffer();

    if (isSpanish) {
      buffer.writeln('💡 Contexto sobre "${context['purpose']}":\n');
      buffer.writeln('¿Por qué?: ${context['why']}\n');
      buffer.writeln('✅ Beneficio: ${context['benefit']}');
      if (context['examples'] != null) {
        buffer.writeln('\n📍 Ejemplos: ${context['examples']}');
      }
      if (context['security'] != null) {
        buffer.writeln('\n🔒 Seguridad: ${context['security']}');
      }
      if (context['psychology'] != null) {
        buffer.writeln('\n🧠 Psicología: ${context['psychology']}');
      }
      if (context['research'] != null) {
        buffer.writeln('\n📊 Investigación: ${context['research']}');
      }
      if (context['brands'] != null) {
        buffer.writeln('\n🏢 Para Marcas: ${context['brands']}');
      }
      if (context['key'] != null) {
        buffer.writeln('\n🔑 IMPORTANTE: ${context['key']}');
      }
    } else {
      buffer.writeln('💡 Context about "${context['purpose']}":\n');
      buffer.writeln('Why?: ${context['why']}\n');
      buffer.writeln('✅ Benefit: ${context['benefit']}');
      if (context['examples'] != null) {
        buffer.writeln('\n📍 Examples: ${context['examples']}');
      }
      if (context['security'] != null) {
        buffer.writeln('\n🔒 Security: ${context['security']}');
      }
      if (context['psychology'] != null) {
        buffer.writeln('\n🧠 Psychology: ${context['psychology']}');
      }
      if (context['research'] != null) {
        buffer.writeln('\n📊 Research: ${context['research']}');
      }
      if (context['brands'] != null) {
        buffer.writeln('\n🏢 For Brands: ${context['brands']}');
      }
      if (context['key'] != null) {
        buffer.writeln('\n🔑 IMPORTANT: ${context['key']}');
      }
    }

    return buffer.toString();
  }

  /// Get short explanation (for quick responses)
  static String getShortExplanation(String fieldKey, String language) {
    final context = getFieldContext(fieldKey, language);
    if (context == null) return '';

    final isSpanish =
        language.toLowerCase().contains('español') || language == 'es';

    if (isSpanish) {
      return '${context['why']}\n✅ ${context['benefit']}';
    } else {
      return '${context['why']}\n✅ ${context['benefit']}';
    }
  }
}
