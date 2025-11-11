import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/social_normalizer.dart';

void handleFacebook(String rawData, BuildContext context) {
  try {
    debugPrint('facebook deeplink raw: $rawData');

    // Decodificar payload de Facebook
    final params = Uri.splitQueryString(rawData);
    final payload = params['payload'];
    if (payload == null || payload.isEmpty) {
      debugPrint('handleFacebook: no payload');
      return;
    }

    final normalizedPayload = _padB64(payload);
    final decoded = utf8.decode(base64Url.decode(normalizedPayload));
    final Map<String, dynamic> data = json.decode(decoded);

    // Normalizar datos
    final normalized = normalizeFacebook(data);

    // Obtener cubit
    final registerCubit = context.read<RegisterCubit>();
    final current = List<Map<String, Map<String, dynamic>>>.from(
      registerCubit.state.socialEcosystem ?? [],
    );

    current.add({'facebook': normalized});
    registerCubit.setSocialEcosystem(current);

    debugPrint('✅ Facebook conectado: $normalized');
  } catch (e, st) {
    debugPrint('❌ Error decoding Facebook payload: $e\n$st');
  }
}

String _padB64(String s) {
  final mod = s.length % 4;
  if (mod != 0) s = s + ('=' * (4 - mod));
  return s;
}
