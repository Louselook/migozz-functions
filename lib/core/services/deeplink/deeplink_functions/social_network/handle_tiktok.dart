import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/social_normalizer.dart';

void handleTikTok(String rawData, BuildContext context) {
  try {
    debugPrint('tiktok deeplink raw: $rawData');

    // Decodificar payload de TikTok
    final params = Uri.splitQueryString(rawData);
    final payload = params['payload'];
    if (payload == null || payload.isEmpty) {
      debugPrint('handleTikTok: no payload');
      return;
    }

    final normalizedPayload = _padBase64(payload);
    final decoded = utf8.decode(base64Url.decode(normalizedPayload));
    final Map<String, dynamic> data = json.decode(decoded);

    // Normalizar datos
    final normalized = normalizeTikTok(data);

    // Obtener cubit
    final registerCubit = context.read<RegisterCubit>();
    final current = List<Map<String, Map<String, dynamic>>>.from(
      registerCubit.state.socialEcosystem ?? [],
    );

    // Agregar TikTok normalizado
    current.add({'tiktok': normalized});
    registerCubit.setSocialEcosystem(current);

    debugPrint('✅ TikTok conectado: $normalized');
  } catch (e, st) {
    debugPrint('❌ Error decoding TikTok payload: $e\n$st');
  }
}

String _padBase64(String s) {
  final mod = s.length % 4;
  if (mod != 0) s = s + ('=' * (4 - mod));
  return s;
}
