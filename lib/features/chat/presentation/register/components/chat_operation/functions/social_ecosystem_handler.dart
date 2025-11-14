import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/get_time_now.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_model.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/chat/controllers/register_chat_controller.dart';
import 'package:migozz_app/features/chat/presentation/register/components/chat_operation/social_cards/helper_cards.dart';

/// Maneja la lógica de confirmación cuando el usuario regresa de vincular redes sociales
class SocialEcosystemHandler {
  static void handleReturn({
    required BuildContext context,
    required RegisterCubit cubit,
    required RegisterChatController chatController,
  }) {
    final socialEcosystem = cubit.state.socialEcosystem;

    if (socialEcosystem == null || socialEcosystem.isEmpty) {
      debugPrint('⚠️ No se vincularon redes sociales');
      _showNoSocialNetworksMessage(cubit, chatController);
      return;
    }

    debugPrint(
      '✅ Usuario regresó con ${socialEcosystem.length} red(es) vinculada(s)',
    );
    _showSocialNetworksConfirmation(cubit, chatController, socialEcosystem);
  }

  /// Muestra mensaje cuando NO se vincularon redes
  static void _showNoSocialNetworksMessage(
    RegisterCubit cubit,
    RegisterChatController chatController,
  ) {
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');

    final noSocialText = isSpanish
        ? 'No vinculaste ninguna red social. ¿Deseas continuar sin vincular redes?'
        : 'You didn\'t link any social networks. Do you want to continue without linking networks?';

    chatController.addMessage({
      "other": true,
      "text": noSocialText,
      "type": MessageType.text,
      "time": getTimeNow(),
      "options": isSpanish
          ? ["Sí, continuar", "Vincular redes"]
          : ["Yes, continue", "Link networks"],
    });
  }

  /// Muestra confirmación con tarjetas cuando SÍ se vincularon redes
  static void _showSocialNetworksConfirmation(
    RegisterCubit cubit,
    RegisterChatController chatController,
    List<Map<String, Map<String, dynamic>>> socialEcosystem,
  ) {
    final isSpanish = (cubit.state.language ?? '').toLowerCase().contains('es');

    // Extraer nombres de las redes vinculadas
    final networkNames = socialEcosystem
        .map((p) => _capitalize(p.keys.first))
        .toList();
    final namesText = _formatNetworkNames(networkNames, isSpanish);

    // 1️⃣ Mensaje de texto de confirmación
    final confirmationText = isSpanish
        ? '¡Genial! Veo que conectaste $namesText 🎉'
        : 'Great! I see you connected $namesText 🎉';

    chatController.addMessage({
      "other": true,
      "text": confirmationText,
      "type": MessageType.text,
      "time": getTimeNow(),
    });

    // 2️⃣ Generar y mostrar las tarjetas de redes sociales
    Future.delayed(const Duration(milliseconds: 500), () {
      final socialCardsMessages = SocialCardsHelper.generateSocialCards(
        platforms: socialEcosystem,
        isSpanish: isSpanish,
        getTimeNow: getTimeNow,
      );

      for (var msg in socialCardsMessages) {
        chatController.addMessage(msg);
      }

      Future.delayed(const Duration(milliseconds: 1500), () {
        chatController.showNextBotMessage();
      });
    });
  }

  /// Helper para formatear nombres de redes
  static String _formatNetworkNames(List<String> names, bool isSpanish) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names[0];
    if (names.length == 2) {
      return isSpanish
          ? '${names[0]} y ${names[1]}'
          : '${names[0]} and ${names[1]}';
    }

    // Más de 2 redes: "Red1, Red2 y Red3"
    final lastSeparator = isSpanish ? ' y ' : ' and ';
    final allButLast = names.sublist(0, names.length - 1).join(', ');
    return '$allButLast$lastSeparator${names.last}';
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
