import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

class GetFirestore extends StatefulWidget {
  const GetFirestore({super.key});

  @override
  State<GetFirestore> createState() => _GetFirestoreState();
}

class _GetFirestoreState extends State<GetFirestore> {
  Future<void> fetchCollection() async {
    try {
      // Cambia 'users' por el nombre de tu colección
      CollectionReference collection = FirebaseFirestore.instance.collection(
        'users',
      );
      QuerySnapshot snapshot = await collection.get();

      for (var doc in snapshot.docs) {
        debugPrint('ID: ${doc.id}, Datos: ${doc.data()}');
      }
    } catch (e) {
      debugPrint('Error al traer datos: $e');
    }
  }

  Future<void> testFirebaseConnection() async {
    try {
      debugPrint('Probando conexión a Firebase...');

      // Probar escribir un documento de prueba
      await FirebaseFirestore.instance.collection('test').add({
        'mensaje': 'Conexión exitosa',
        'timestamp': DateTime.now(),
      });

      debugPrint('Firebase conectado correctamente');
    } catch (e) {
      debugPrint('❌ Error de conexión Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Login button
          GradientButton(
            width: double.infinity,
            radius: 19,
            // onPressed: authProvider.isLoading ? null : _handleLogin,
            onPressed: () {
              testFirebaseConnection();
              Future.delayed(Duration(seconds: 2), () {
                fetchCollection();
                debugPrint('Listo!!');
              });
            },
            child: SecondaryText('Login', fontSize: 20),
          ),
        ],
      ),
    );
  }
}
