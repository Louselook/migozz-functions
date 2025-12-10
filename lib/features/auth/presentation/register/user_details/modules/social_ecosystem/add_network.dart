// add_network.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/features/auth/services/add_networks/network_config.dart';

enum NetworkAuthMode { click, manual }

class AddNetworkBottomSheet extends StatefulWidget {
  final NetworkConfig networkConfig;
  final Function(NetworkAuthMode mode, String? value) onOptionSelected;

  const AddNetworkBottomSheet({
    super.key,
    required this.networkConfig,
    required this.onOptionSelected,
  });

  @override
  State<AddNetworkBottomSheet> createState() => _AddNetworkBottomSheetState();
}

class _AddNetworkBottomSheetState extends State<AddNetworkBottomSheet> {
  NetworkAuthMode? _selectedMode;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClickAuth() {
    setState(() => _selectedMode = NetworkAuthMode.click);
    widget.onOptionSelected(NetworkAuthMode.click, null);
  }

  void _handleManualAuth() {
    setState(() => _selectedMode = NetworkAuthMode.manual);
  }

  void _handleSaveManual() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      widget.onOptionSelected(NetworkAuthMode.manual, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.networkConfig;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              "Connect ${config.displayName}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Logo
            SvgPicture.asset(config.iconPath, width: 50, height: 50),
            const SizedBox(height: 20),

            // Show connection options
            if (_selectedMode == null) ...[
              // Si solo soporta OAuth, ejecutar directamente
              if (config.capability == NetworkAuthCapability.oauth)
                _buildSingleOption(
                  icon: Icons.link,
                  title: "Connect with one click",
                  subtitle: "Authorize via ${config.displayName}",
                  onTap: _handleClickAuth,
                )
              // Si solo soporta manual, mostrar directamente el formulario
              else if (config.capability == NetworkAuthCapability.manual)
                _buildManualForm()
              // Si soporta ambos, mostrar opciones
              else ...[
                _buildOptionButton(
                  icon: Icons.link,
                  title: "Connect with one click",
                  subtitle: "Authorize via ${config.displayName}",
                  onTap: _handleClickAuth,
                ),
                const SizedBox(height: 12),
                _buildOptionButton(
                  icon: Icons.edit,
                  title: "Enter manually",
                  subtitle: "Paste username or link",
                  onTap: _handleManualAuth,
                ),
              ],
            ] else if (_selectedMode == NetworkAuthMode.manual)
              _buildManualForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            onPressed: onTap,
            gradient: AppColors.primaryGradient,
            radius: 20,
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    return Column(
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter username or link",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Preview URL
        Text(
          _getExampleUrl(),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Botón para volver si hay múltiples opciones
        if (widget.networkConfig.capability == NetworkAuthCapability.both) ...[
          TextButton.icon(
            onPressed: () => setState(() => _selectedMode = null),
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            label: const Text(
              "Back to options",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Botón Guardar
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            onPressed: _handleSaveManual,
            gradient: AppColors.primaryGradient,
            radius: 20,
            height: 48,
            child: const Text(
              "Save",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  String _getExampleUrl() {
    switch (widget.networkConfig.name.toLowerCase()) {
      case 'instagram':
        return 'https://www.instagram.com/username';
      case 'tiktok':
        return 'https://www.tiktok.com/@username';
      case 'youtube':
        return 'https://www.youtube.com/@username';
      case 'twitter':
        return 'https://twitter.com/username';
      case 'facebook':
        return 'https://www.facebook.com/username';
      default:
        return 'https://www.${widget.networkConfig.name}.com/username';
    }
  }
}
