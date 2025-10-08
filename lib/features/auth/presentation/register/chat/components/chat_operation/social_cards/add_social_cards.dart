// import 'package:migozz_app/core/components/atomics/get_time_now.dart';
// import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
// import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/social_cards/helper_cards.dart';

// /// ------------------- Social Cards (después de conectar redes) -------------------
// Future<void> addSocialCards({
//   required dynamic platforms,
//   required bool isSpanish,
// }) async {
//   if (platforms.isEmpty) return;
//   // 🔹 NUEVO: Mensaje previo mencionando las redes conectadas
//   final platformNames = platforms
//       .map((p) => p.keys.first.capitalize())
//       .join(', ')
//       .replaceFirst(
//         RegExp(r',\s(?!.*,)'),
//         isSpanish ? ' y ' : ' and ',
//       ); // último separador

//   final introText = isSpanish
//       ? '¡Genial! Veo que conectaste $platformNames. 🎉'
//       : 'Great! I see you connected $platformNames. 🎉';

//   addMessage({
//     "other": true,
//     "text": introText,
//     "type": MessageType.text,
//     "time": getTimeNow(),
//   });

//   await Future.delayed(const Duration(milliseconds: 600));

//   // 🔹 Luego mostrar las cards
//   final socialMessages = SocialCardsHelper.generateSocialCards(
//     platforms: platforms,
//     isSpanish: isSpanish,
//     getTimeNow: getTimeNow,
//   );

//   for (final message in socialMessages) {
//     addMessage(message);
//     await Future.delayed(const Duration(milliseconds: 400));
//   }
// }
