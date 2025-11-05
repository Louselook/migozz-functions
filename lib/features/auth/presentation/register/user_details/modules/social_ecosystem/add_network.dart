import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class AddNetworkBottomSheet extends StatefulWidget {
  final String label;
  final String assetPath;
  final Function(String username) onSaved;

  const AddNetworkBottomSheet({
    super.key,
    required this.label,
    required this.assetPath,
    required this.onSaved,
  });

  @override
  State<AddNetworkBottomSheet> createState() => _AddNetworkBottomSheetState();
}

class _AddNetworkBottomSheetState extends State<AddNetworkBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      // Actualiza el cubit directamente
      widget.onSaved(value);

      // NO cerrar automáticamente:
      // Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              "Add ${widget.label}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Logo
            SvgPicture.asset(widget.assetPath, width: 50, height: 50),
            const SizedBox(height: 20),

            // Input
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter username",
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
              "https://www.${widget.label.toLowerCase()}.com/",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Botón Guardar (con degradado)
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: _handleSave,
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
        ),
      ),
    );
  }
}
