import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: PrimaryText('Terms & Privacy')),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isDesktop || isTablet
                  ? _buildTwoColumnLayout()
                  : _buildSingleColumnLayout(),
            ),

            // Back to Login Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GradientButton(
                  width: double.infinity,
                  radius: 19,
                  onPressed: () => context.go('/login'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      SecondaryText("Back to Login"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Layout para desktop/tablet (2 columnas)
  Widget _buildTwoColumnLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Términos de Servicio
          Expanded(child: _TermsSection(isMobile: false)),
          const SizedBox(width: 20),
          // Política de Privacidad
          Expanded(child: _PrivacySection(isMobile: false)),
        ],
      ),
    );
  }

  // Layout para móvil (scroll vertical)
  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _TermsSection(isMobile: true),
          const SizedBox(height: 30),
          _PrivacySection(isMobile: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Sección de Términos de Servicio
class _TermsSection extends StatelessWidget {
  final bool isMobile;

  const _TermsSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient.scale(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.description, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Términos de Servicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido scrolleable (o no, dependiendo de isMobile)
          if (isMobile)
            _buildMobileContent()
          else
            Expanded(child: _buildDesktopContent()),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildContent(),
    );
  }

  Widget _buildMobileContent() {
    return Padding(padding: const EdgeInsets.all(20), child: _buildContent());
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntro(),
        const SizedBox(height: 20),
        _buildSection(
          '1. Aceptación de los Términos',
          'Al registrarte, acceder o utilizar Migozz, aceptas estos Términos de Servicio y nuestra Política de Privacidad. Si no estás de acuerdo, no debes utilizar la plataforma.',
        ),
        _buildSection(
          '2. Descripción del Servicio',
          'Migozz permite a los usuarios conectar múltiples redes sociales, publicar contenido de forma cruzada, monetizar su presencia digital, recibir regalos, y acceder a herramientas de análisis impulsadas por IA.',
        ),
        _buildSection(
          '3. Elegibilidad',
          'Debes tener al menos 13 años para usar Migozz. Si eres menor de edad, necesitas el consentimiento de tus padres o tutores legales.',
        ),
        _buildSection(
          '4. Uso Aceptable',
          'No puedes utilizar Migozz para:\n\n'
              '• Publicar contenido ilegal, ofensivo o que infrinja derechos de terceros.\n'
              '• Suplantar identidades o manipular estadísticas.\n'
              '• Realizar actividades fraudulentas o engañosas.',
        ),
        _buildSection(
          '5. Propiedad Intelectual',
          'Todo el contenido generado por Migozz, incluyendo diseño, algoritmos y funcionalidades, es propiedad de Migozz Inc. Los usuarios conservan los derechos sobre el contenido que suben, pero otorgan a Migozz una licencia para mostrarlo y distribuirlo dentro del ecosistema.',
        ),
        _buildSection(
          '6. Monetización y Pagos',
          'Los ingresos generados por publicidad, regalos o ventas de contenido están sujetos a comisiones establecidas por Migozz. Los pagos se procesan de forma segura y pueden estar sujetos a impuestos locales.',
        ),
        _buildSection(
          '7. Cancelación y Suspensión',
          'Migozz se reserva el derecho de suspender o cancelar cuentas que violen estos términos, sin previo aviso. Los usuarios pueden eliminar su cuenta en cualquier momento desde el panel de configuración.',
        ),
        _buildSection(
          '8. Limitación de Responsabilidad',
          'Migozz no se hace responsable por pérdidas de ingresos, interrupciones del servicio o daños derivados del uso de la plataforma.',
        ),
        _buildSection(
          '9. Modificaciones',
          'Nos reservamos el derecho de modificar estos términos en cualquier momento. Las actualizaciones se publicarán en esta página y se considerarán vigentes desde su publicación.',
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Text(
      'Bienvenido a Migozz, el primer ecosistema de redes sociales impulsado por inteligencia artificial. Al acceder o utilizar nuestros servicios, aceptas cumplir con los siguientes términos y condiciones.',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 14,
        height: 1.5,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Sección de Política de Privacidad
class _PrivacySection extends StatelessWidget {
  final bool isMobile;

  const _PrivacySection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient.scale(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Política de Privacidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido scrolleable (o no, dependiendo de isMobile)
          if (isMobile)
            _buildMobileContent()
          else
            Expanded(child: _buildDesktopContent()),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildContent(),
    );
  }

  Widget _buildMobileContent() {
    return Padding(padding: const EdgeInsets.all(20), child: _buildContent());
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntro(),
        const SizedBox(height: 20),
        _buildSection(
          '1. Información que Recopilamos',
          '• Datos de registro: nombre, correo electrónico, número de teléfono.\n'
              '• Redes sociales conectadas: estadísticas de seguidores, publicaciones, interacciones.\n'
              '• Información de uso: actividad dentro de la plataforma, clics, tiempo de sesión.\n'
              '• Datos de monetización: ingresos generados, regalos recibidos, transacciones.',
        ),
        _buildSection(
          '2. Cómo Usamos Tu Información',
          '• Para personalizar tu experiencia en Migozz.\n'
              '• Para mostrar estadísticas y análisis de tu comunidad.\n'
              '• Para facilitar la publicación cruzada y la monetización.\n'
              '• Para enviarte notificaciones relevantes y soporte técnico.',
        ),
        _buildSection(
          '3. Compartir Información',
          'No vendemos tus datos. Podemos compartir información con:\n\n'
              '• Proveedores de servicios (como procesadores de pago).\n'
              '• Autoridades legales si es requerido por ley.\n'
              '• Socios estratégicos, solo con tu consentimiento.',
        ),
        _buildSection(
          '4. Seguridad',
          'Utilizamos cifrado, autenticación y servidores seguros para proteger tu información. Sin embargo, ningún sistema es 100% infalible.',
        ),
        _buildSection(
          '5. Tus Derechos',
          '• Acceder a tus datos.\n'
              '• Rectificar información incorrecta.\n'
              '• Eliminar tu cuenta y tus datos.\n'
              '• Solicitar una copia de tu información.',
        ),
        _buildSection(
          '6. Cookies y Tecnologías de Rastreo',
          'Usamos cookies para mejorar la experiencia del usuario, analizar el tráfico y personalizar contenido. Puedes gestionar tus preferencias desde tu navegador.',
        ),
        _buildSection(
          '7. Retención de Datos',
          'Conservamos tu información mientras tu cuenta esté activa o sea necesario para cumplir con obligaciones legales.',
        ),
        _buildSection(
          '8. Cambios en la Política',
          'Podemos actualizar esta política periódicamente. Te notificaremos sobre cambios importantes por correo o dentro de la plataforma.',
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Text(
      'En Migozz, valoramos tu privacidad y nos comprometemos a proteger tus datos personales. Esta política describe cómo recopilamos, usamos, almacenamos y compartimos tu información.',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 14,
        height: 1.5,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
