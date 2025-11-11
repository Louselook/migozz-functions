import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/social_normalizer.dart';

void handleInstagram(String rawData, BuildContext context) {
  try {
    debugPrint('instagram deeplink raw: $rawData');

    // Si recibes la query completa (p.e. "payload=...") conviértela a map:
    final params = Uri.splitQueryString(rawData);
    final payload = params['payload'] ?? rawData; // si rawData ya es el payload

    if (payload.isEmpty) {
      debugPrint('handleInstagram: no payload');
      return;
    }

    final normalizedB64 = _padB64(payload);
    final decoded = utf8.decode(base64Url.decode(normalizedB64));
    final Map<String, dynamic> data = json.decode(decoded);

    final normalized = normalizeInstagram(data);

    final registerCubit = context.read<RegisterCubit>();
    final current = List<Map<String, Map<String, dynamic>>>.from(
      registerCubit.state.socialEcosystem ?? [],
    );

    current.add({'instagram': normalized});
    registerCubit.setSocialEcosystem(current);

    debugPrint('✅ Instagram conectado: $normalized');
  } catch (e, s) {
    debugPrint('❌ Error handleInstagram: $e\n$s');
  }
}

// Asegura el padding correcto en Base64 URL-safe
String _padB64(String s) {
  final mod = s.length % 4;
  if (mod != 0) s = s + ('=' * (4 - mod));
  return s;
}
