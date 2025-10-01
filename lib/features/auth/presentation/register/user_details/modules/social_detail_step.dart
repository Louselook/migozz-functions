import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class SocialDetailScreen extends StatefulWidget {
  final String label;
  final String assetPath;

  const SocialDetailScreen({
    super.key,
    required this.label,
    required this.assetPath,
  });

  @override
  State<SocialDetailScreen> createState() => _SocialDetailScreenState();
}

class _SocialDetailScreenState extends State<SocialDetailScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(color: Colors.white),
        title: Text("Your Social Ecosystem", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Add your platform", style: TextStyle(color: Colors.white, fontSize: 14)), 
            // Ícono grande
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Image.asset(
                    widget.assetPath,
                    width: 40,
                    height: 40,
                  ),
                ),
                
                // Campo de texto para la URL
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add ${widget.label.toUpperCase()}",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Botón continuar
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: () {
                  // Guardar en cubit o devolver el resultado
                  Navigator.pop(context, _controller.text);
                },
                width: double.infinity,
                radius: 19,
                child: const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 20),),
                gradient: AppColors.primaryGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
