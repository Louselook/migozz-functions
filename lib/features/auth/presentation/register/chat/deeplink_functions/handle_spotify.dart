import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

void handleSpotify(String queryString, BuildContext context) {
  final params = Uri.splitQueryString(queryString);

  // Obtener el cubit desde el context
  final registerCubit = context.read<RegisterCubit>();

  final current = List<Map<String, Map<String, dynamic>>>.from(
    registerCubit.state.socialEcosystem ?? [],
  );

  current.add({
    'spotify': {
      'access_token': params['access_token'],
      'refresh_token': params['refresh_token'],
      'display_name': params['display_name'],
      'email': params['email'],
      'followers': int.tryParse(params['followers'] ?? '0') ?? 0,
      'pais': params['pais'],
      'plan': params['plan'],
    },
  });

  registerCubit.setSocialEcosystem(current);
}
