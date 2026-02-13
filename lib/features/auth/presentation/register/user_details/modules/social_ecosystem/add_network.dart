import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
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

  // Para el phone input
  String _completePhoneNumber = '';
  bool _isPhoneValid = false;

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
    final networkName = widget.networkConfig.name.toLowerCase();

    // Para WhatsApp y Telegram con phone input
    if (_isPhoneInputNetwork(networkName)) {
      if (_isPhoneValid && _completePhoneNumber.isNotEmpty) {
        widget.onOptionSelected(NetworkAuthMode.manual, _completePhoneNumber);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('addSocials.networkAuth.phoneInvalid'.tr()),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Para otros campos de texto normales
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      widget.onOptionSelected(NetworkAuthMode.manual, value);
    }
  }

  bool _isPhoneInputNetwork(String networkName) {
    return networkName == 'whatsapp' || networkName == 'telegram';
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
              "addSocials.networkAuth.connectTitle".tr(
                namedArgs: {'platform': config.displayName},
              ),
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
                  title: "addSocials.networkAuth.oneClickTitle".tr(),
                  subtitle: "addSocials.networkAuth.oneClickSubtitle".tr(
                    namedArgs: {'platform': config.displayName},
                  ),
                  onTap: _handleClickAuth,
                )
              // Si solo soporta manual, mostrar directamente el formulario
              else if (config.capability == NetworkAuthCapability.manual)
                _buildManualForm()
              // Si soporta ambos, mostrar opciones
              else ...[
                _buildOptionButton(
                  icon: Icons.link,
                  title: "addSocials.networkAuth.oneClickTitle".tr(),
                  subtitle: "addSocials.networkAuth.oneClickSubtitle".tr(
                    namedArgs: {'platform': config.displayName},
                  ),
                  onTap: _handleClickAuth,
                ),
                const SizedBox(height: 12),
                _buildOptionButton(
                  icon: Icons.edit,
                  title: "addSocials.networkAuth.manualTitle".tr(),
                  subtitle: "addSocials.networkAuth.manualSubtitle".tr(),
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
    final networkName = widget.networkConfig.name.toLowerCase();
    final isPhoneInput = _isPhoneInputNetwork(networkName);
    final networkTexts = _getNetworkTexts();

    return Column(
      children: [
        // Preview URL o ejemplo (Dinámico)
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            String exampleText = networkTexts['example']!;

            // Lógica dinámica para mostrar la URL mientras el usuario escribe (solo si no es input de teléfono)
            if (!isPhoneInput && exampleText.contains('http')) {
              final inputText = value.text.trim();
              if (inputText.isNotEmpty) {
                // Si pega una URL completa, mostramos esa
                if (inputText.toLowerCase().startsWith('http')) {
                  exampleText = inputText;
                } else {
                  // Reemplazo dinámico del placeholder "usuario"/"username"
                  final placeholder = context.locale.languageCode == 'es'
                      ? 'usuario'
                      : 'username';

                  if (exampleText.contains(placeholder)) {
                    exampleText = exampleText.replaceAll(
                      placeholder,
                      inputText,
                    );
                  } else {
                    // Fallback: si no encuentra el placeholder, se añade al final de manera inteligente
                    if (exampleText.endsWith('/')) {
                      exampleText += inputText;
                    } else {
                      // Intenta encontrar el último segmento si la estructura es típica
                      final lastSlash = exampleText.lastIndexOf('/');
                      if (lastSlash != -1 &&
                          lastSlash < exampleText.length - 1) {
                        // Asumimos que lo que sigue al último slash es el placeholder si este no coincidió con "usuario"
                        exampleText =
                            exampleText.substring(0, lastSlash + 1) + inputText;
                      } else {
                        exampleText += '/$inputText';
                      }
                    }
                  }
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                exampleText,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),

        // Phone input para WhatsApp y Telegram
        if (isPhoneInput)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntlPhoneField(
              decoration: InputDecoration(
                hintText: networkTexts['hint'],
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                counterText: '',
              ),
              showDropdownIcon: true,
              dropdownIcon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[400],
              ),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              dropdownTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              onChanged: (phone) {
                setState(() {
                  _completePhoneNumber = phone.completeNumber;
                  _isPhoneValid = phone.number.length >= 4;
                });
              },
              keyboardType: TextInputType.phone,
              disableLengthCheck: true,
              pickerDialogStyle: PickerDialogStyle(
                width: 350,
                countryCodeStyle: const TextStyle(color: Colors.black),
                countryNameStyle: const TextStyle(color: Colors.black87),
                searchFieldInputDecoration: InputDecoration(
                  hintText: 'addSocials.networkAuth.searchCountry'.tr(),
                  hintStyle: const TextStyle(color: Colors.black87),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          )
        else
          // TextField normal para otras redes
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: networkTexts['hint'],
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

        const SizedBox(height: 20),

        // Botón para volver si hay múltiples opciones
        if (widget.networkConfig.capability == NetworkAuthCapability.both) ...[
          TextButton.icon(
            onPressed: () => setState(() => _selectedMode = null),
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            label: Text(
              "addSocials.networkAuth.backToOptions".tr(),
              style: const TextStyle(color: Colors.white70),
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
            child: Text(
              "buttons.save".tr(),
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _getNetworkTexts() {
    final name = widget.networkConfig.name.toLowerCase();

    switch (name) {
      case 'instagram':
        return {
          'hint': 'addSocials.networkAuth.hints.instagram'.tr(),
          'example': 'addSocials.networkAuth.examples.instagram'.tr(),
        };

      case 'tiktok':
        return {
          'hint': 'addSocials.networkAuth.hints.tiktok'.tr(),
          'example': 'addSocials.networkAuth.examples.tiktok'.tr(),
        };

      case 'youtube':
        return {
          'hint': 'addSocials.networkAuth.hints.youtube'.tr(),
          'example': 'addSocials.networkAuth.examples.youtube'.tr(),
        };

      case 'twitter':
        return {
          'hint': 'addSocials.networkAuth.hints.twitter'.tr(),
          'example': 'addSocials.networkAuth.examples.twitter'.tr(),
        };

      case 'facebook':
        return {
          'hint': 'addSocials.networkAuth.hints.facebook'.tr(),
          'example': 'addSocials.networkAuth.examples.facebook'.tr(),
        };

      case 'whatsapp':
        return {
          'hint': 'addSocials.networkAuth.hints.whatsapp'.tr(),
          'example': 'addSocials.networkAuth.examples.whatsapp'.tr(),
        };

      case 'telegram':
        return {
          'hint': 'addSocials.networkAuth.hints.telegram'.tr(),
          'example': 'addSocials.networkAuth.examples.telegram'.tr(),
        };

      case 'pinterest':
        return {
          'hint': 'addSocials.networkAuth.hints.pinterest'.tr(),
          'example': 'addSocials.networkAuth.examples.pinterest'.tr(),
        };

      default:
        // Construcción manual para evitar problemas de interpolación con {platform}
        final isEs = context.locale.languageCode == 'es';
        final suffix = isEs ? 'usuario' : 'username';
        return {
          'hint': 'addSocials.networkAuth.hints.default'.tr(),
          'example': 'https://www.$name.com/$suffix',
        };
    }
  }
}
