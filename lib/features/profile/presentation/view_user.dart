// import 'package:flutter/material.dart';
// import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';

// void debugPrintAuthUser(AuthCubit authState, firebaseUser) {

//     debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//     debugPrint('🔍 DEBUG: AUTH USER INFO');
//     debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

//     // Estado de autenticación
//     debugPrint('📊 AUTH STATUS: ${authState.status}');
//     debugPrint('⏳ Loading Profile: ${authState.isLoadingProfile}');
//     debugPrint('✅ Profile Complete: ${authState.isProfileComplete}\n');

//     if (firebaseUser != null) {
//       debugPrint('🔥 FIREBASE USER:');
//       debugPrint('  ├─ UID: ${firebaseUser.uid}');
//       debugPrint('  ├─ Email: ${firebaseUser.email}');
//       debugPrint('  ├─ Display Name: ${firebaseUser.displayName}');
//       debugPrint('  ├─ Photo URL: ${firebaseUser.photoURL}');
//       debugPrint('  ├─ Email Verified: ${firebaseUser.emailVerified}');
//       debugPrint('  └─ Phone: ${firebaseUser.phoneNumber ?? "N/A"}\n');
//     } else {
//       debugPrint('❌ Firebase User: NULL\n');
//     }

//     // User Profile (UserDTO)
//     final userProfile = authState.userProfile;
//     if (userProfile != null) {
//       debugPrint('👤 USER PROFILE (UserDTO):');
//       debugPrint('  ├─ Email: ${userProfile.email}');
//       debugPrint('  ├─ Display Name: ${userProfile.displayName}');
//       debugPrint('  ├─ Username: ${userProfile.username}');
//       debugPrint('  ├─ Gender: ${userProfile.gender}');
//       debugPrint('  ├─ Language: ${userProfile.lang}');
//       debugPrint('  ├─ Phone: ${userProfile.phone ?? "N/A"}');
//       debugPrint('  ├─ Avatar URL: ${userProfile.avatarUrl ?? "N/A"}');
//       debugPrint('  └─ Voice Note URL: ${userProfile.voiceNoteUrl ?? "N/A"}\n');

//       // Ubicación
//       debugPrint('📍 LOCATION:');
//       debugPrint('  ├─ Country: ${userProfile.location.country}');
//       debugPrint('  ├─ State: ${userProfile.location.state}');
//       debugPrint('  ├─ City: ${userProfile.location.city}');
//       debugPrint('  ├─ Latitude: ${userProfile.location.lat}');
//       debugPrint('  └─ Longitude: ${userProfile.location.lng}\n');

//       // Categorías
//       if (userProfile.category != null && userProfile.category!.isNotEmpty) {
//         debugPrint('🏷️ CATEGORIES (${userProfile.category!.length}):');
//         for (var i = 0; i < userProfile.category!.length; i++) {
//           final isLast = i == userProfile.category!.length - 1;
//           debugPrint('  ${isLast ? "└─" : "├─"} ${userProfile.category![i]}');
//         }
//         debugPrint('');
//       } else {
//         debugPrint('🏷️ CATEGORIES: None\n');
//       }

//       // Intereses
//       if (userProfile.interests.isNotEmpty) {
//         debugPrint('❤️ INTERESTS (${userProfile.interests.length} sections):');
//         userProfile.interests.forEach((section, interests) {
//           debugPrint('  ├─ $section (${interests.length}):');
//           for (var i = 0; i < interests.length; i++) {
//             final isLast = i == interests.length - 1;
//             debugPrint('  │  ${isLast ? "└─" : "├─"} ${interests[i]}');
//           }
//         });
//         debugPrint('');
//       } else {
//         debugPrint('❤️ INTERESTS: None\n');
//       }

//       // Redes Sociales
//       if (userProfile.socialEcosystem != null && 
//           userProfile.socialEcosystem!.isNotEmpty) {
//         debugPrint('🌐 SOCIAL ECOSYSTEM (${userProfile.socialEcosystem!.length}):');
//         for (var i = 0; i < userProfile.socialEcosystem!.length; i++) {
//           final network = userProfile.socialEcosystem![i];
//           final networkName = network.keys.first;
//           final networkData = network[networkName]!;
//           final isLast = i == userProfile.socialEcosystem!.length - 1;
          
//           debugPrint('  ${isLast ? "└─" : "├─"} ${networkName.toUpperCase()}:');
          
//           networkData.forEach((key, value) {
//             debugPrint('     ├─ $key: $value');
//           });
          
//           if (!isLast) debugPrint('  │');
//         }
//         debugPrint('');
//       } else {
//         debugPrint('🌐 SOCIAL ECOSYSTEM: None\n');
//       }

//       // Fechas
//       debugPrint('📅 TIMESTAMPS:');
//       debugPrint('  ├─ Created At: ${userProfile.createdAt}');
//       debugPrint('  └─ Updated At: ${userProfile.updatedAt}\n');

//     } else {
//       debugPrint('❌ User Profile: NULL\n');
//     }

//     debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//     debugPrint('🔍 END DEBUG AUTH USER INFO');
//     debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
//   }