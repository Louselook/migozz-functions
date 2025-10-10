import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart'; 

class EditRecordScreen extends StatelessWidget {
  const EditRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // solo navega
        ),
        title: const Text(
          "Edit Record",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.04),

            // Title
            const Text(
              "Record Your Voicenote",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Voice note: 5 or 10 sec max.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            SizedBox(height: screenHeight * 0.05),

            // Mic image (botón visual)
            GestureDetector(
              onTap: () {}, // Ingresar logica de grabacion
              child: Container(
                width: 191,
                height: 191,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4DB6), 
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    "assets/icons/Mic.png", 
                    width: 140,
                    height: 140,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.05),

            // Play audio button (solo visual)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Listen to your audio",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {}, // Ingresar logica de play
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4DB6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/icons/Play.png",
                              width: 51,
                              height: 51,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Save button (maqueta, solo cierra la vista)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }
}
