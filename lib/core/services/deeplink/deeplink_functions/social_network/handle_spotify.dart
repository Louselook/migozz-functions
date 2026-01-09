import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/social_normalizer.dart';

void handleSpotify(String rawData, BuildContext context) {
  try {
    Map<String, dynamic> params;

    // Si empieza con "{" es JSON; de lo contrario, parseamos query string
    if (rawData.trim().startsWith('{')) {
      params = json.decode(rawData) as Map<String, dynamic>;
    } else {
      params = Uri.splitQueryString(rawData);
    }

    final normalized = normalizeSpotify(params);

    final cubit = context.read<RegisterCubit>();
    final current = List<Map<String, dynamic>>.from(
      cubit.state.socialEcosystem ?? [],
    );

    current.add({'spotify': normalized});
    cubit.setSocialEcosystem(current);

    debugPrint("✅ Spotify conectado: $normalized");
  } catch (e) {
    debugPrint('❌ Error handleSpotify: $e');
    debugPrint(rawData);
  }
}
