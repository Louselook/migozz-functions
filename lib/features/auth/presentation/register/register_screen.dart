// import 'package:flutter/material.dart';
// import 'package:migozz_app/core/color.dart';
// import 'package:migozz_app/core/components/compuestos/custom_textfield.dart';
// import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
// import 'package:migozz_app/core/components/atomics/text.dart';
// import 'package:migozz_app/features/auth/models/location_dto.dart';
// import 'package:migozz_app/features/auth/models/user_dto.dart';
// import 'package:migozz_app/features/auth/presentation/login/login_screen.dart';
// import 'package:migozz_app/features/auth/presentation/register/chat/ia_chat_screen.dart';
// // import 'package:migozz_app/features/auth/services/auth_service.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   UserDTO generateTestUser(String email) {
//     return UserDTO(
//       email: email,
//       displayName: "Juan Pérez",
//       username: "juanperez",
//       birthday: "1990-05-15",
//       gender: "male",
//       location: LocationDTO(
//         country: "Colombia",
//         state: "Antioquia",
//         city: "Medellín",
//         lat: 6.2442,
//         lng: -75.5812,
//       ),
//       lang: "es-CO",
//       category: "Influencer",
//       interests: {
//         "interests": ["Moda", "Música"],
//       },
//       avatarUrl: null,
//       voiceNoteUrl: null,
//       totalFollowers: 0,
//       linksCount: 0,
//       // share: ShareDTO(), // inicializa según tu DTO
//       // onboarding: OnboardingDTO(),
//       // privacy: PrivacyDTO(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: AppColors.backgroundDark,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Contenido principal centrado
//             Align(
//               alignment: Alignment.center,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.only(
//                   right: 20,
//                   left: 20,
//                   bottom: 200,
//                 ),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Logo
//                       Container(
//                         width: 80,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           gradient: AppColors.primaryGradient,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Icon(
//                           Icons.link,
//                           color: Colors.white,
//                           size: 40,
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       // Welcome text
//                       const PrimaryText('Register Now!'),
//                       const SizedBox(height: 3),
//                       const SecondaryText('Enter your information below'),

//                       const SizedBox(height: 30),

//                       // Email input
//                       CustomTextField(
//                         hintText: "Enter Email",
//                         prefixIcon: const Icon(
//                           Icons.email_outlined,
//                           color: AppColors.secondaryText,
//                         ),
//                         controller: _emailController,
//                       ),

//                       const SizedBox(height: 30),

//                       // Register button
//                       // GradientButton(
//                       //   width: double.infinity,
//                       //   radius: 19,
//                       //   onPressed: () async {
//                       //     final email = _emailController.text.trim();

//                       //     if (email.isEmpty) {
//                       //       ScaffoldMessenger.of(context).showSnackBar(
//                       //         const SnackBar(
//                       //           content: Text("Please enter an email"),
//                       //         ),
//                       //       );
//                       //       return;
//                       //     }

//                       //     final testUser = generateTestUser(email);

//                       //     try {
//                       //       // Registrar usuario de prueba
//                       //       await AuthService().signUpRegister(
//                       //         email: testUser.email,
//                       //         otp: "123456", // contraseña temporal o OTP
//                       //         userData: testUser,
//                       //       );

//                       //       // Navegar a IaChatScreen
//                       //       Navigator.pushReplacement(
//                       //         // ignore: use_build_context_synchronously
//                       //         context,
//                       //         MaterialPageRoute(
//                       //           builder: (context) => const IaChatScreen(),
//                       //         ),
//                       //       );
//                       //     } catch (e) {
//                       //       // ignore: use_build_context_synchronously
//                       //       ScaffoldMessenger.of(context).showSnackBar(
//                       //         SnackBar(
//                       //           content: Text("Error al crear usuario: $e"),
//                       //         ),
//                       //       );
//                       //     }
//                       //   },
//                       //   child: SecondaryText("Create Account"),
//                       // ),
//                       GradientButton(
//                         width: double.infinity,
//                         radius: 19,
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const IaChatScreen(),
//                             ),
//                           );
//                         },
//                         child: SecondaryText("Create Account"),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // Link abajo fijo
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Padding(
//                 padding: EdgeInsets.only(
//                   bottom: screenHeight < 800 ? 130 : 220,
//                 ),
//                 child: RichText(
//                   textAlign: TextAlign.center,
//                   text: TextSpan(
//                     style: const TextStyle(fontSize: 13, color: Colors.grey),
//                     children: [
//                       const TextSpan(text: "Already a member? "),
//                       gradientTextSpan(
//                         "Login",
//                         onTap: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const LoginScreen(),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
