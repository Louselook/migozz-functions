import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class DataDeletionScreen extends StatelessWidget {
  const DataDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 800 ? 800.0 : double.infinity;

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
                  const Expanded(child: PrimaryText('Data Deletion')),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: _DataDeletionContent(),
                  ),
                ),
              ),
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
}

class _DataDeletionContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                Icon(Icons.delete_forever, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Instrucciones de Eliminación de Datos',
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

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntro(),
                const SizedBox(height: 24),

                _buildSection(
                  '1. Ámbito',
                  'Estas instrucciones aplican a la información recopilada por Migozz a través de Facebook Login y otras integraciones de Meta, incluyendo: nombre público, ID de usuario, foto de perfil, correo electrónico (si lo autorizaste), y cualquier permiso adicional que hayas otorgado a la app.',
                ),

                _buildSection(
                  '2. Cómo solicitar la eliminación',
                  'Tienes tres opciones:',
                ),

                _buildOptionCard(
                  icon: Icons.account_circle,
                  title: 'Desde tu cuenta',
                  description:
                      'Ve a Perfil > Configuración > Privacidad > Eliminar mi cuenta y datos, o accede a https://migozz.com/account/delete y sigue los pasos en pantalla.',
                ),

                const SizedBox(height: 12),

                _buildOptionCard(
                  icon: Icons.web,
                  title: 'Formulario web',
                  description:
                      'Completa el formulario en https://migozz.com/legal/data-deletion indicando tu correo y el ID con el que te registraste (si lo conoces).',
                ),

                const SizedBox(height: 12),

                _buildOptionCard(
                  icon: Icons.email,
                  title: 'Correo electrónico',
                  description:
                      'Escríbenos a privacy@migozz.com con el asunto "Eliminar mis datos – Migozz" y desde el mismo correo asociado a tu cuenta.',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '3. Qué ocurre después',
                  '• Confirmaremos la recepción en 48–72 horas.\n'
                      '• Completaremos la eliminación o anonimización en un plazo máximo de 30 días.\n'
                      '• Te enviaremos un comprobante de eliminación cuando finalice el proceso.',
                ),

                _buildSection(
                  '4. Alcance de la eliminación',
                  'Eliminamos datos obtenidos vía Facebook Login y datos generados en el uso de Migozz (perfiles, sesiones, preferencias, contenido no sujeto a obligaciones legales).\n\n'
                      'Podrían conservarse por tiempo limitado ciertos registros mínimos necesarios para:\n'
                      '• Cumplimiento de la ley\n'
                      '• Prevención de fraude/abuso\n'
                      '• Obligaciones fiscales/contables\n'
                      '• Defensa de reclamaciones\n\n'
                      'Dichos registros se retienen de forma segura y se eliminan al expirar la obligación.',
                ),

                _buildWarningBox(
                  '⚠️ Efectos',
                  'La eliminación es irreversible y puede implicar la desactivación o cierre de tu cuenta y la pérdida de acceso a tus contenidos o funciones asociadas.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade300, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Si deseas eliminar tus datos personales de Migozz, sigue las instrucciones a continuación.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGradient.colors.first.withValues(
                alpha: 0.2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade300,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
