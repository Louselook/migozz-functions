import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/core/services/deeplink/deeplink_functions/social_network/social_normalizer.dart';

void handleTwitter(String queryString, BuildContext context) {
  try {
    //  Parsear la query del deeplink
    final params = Uri.splitQueryString(queryString);

    // Normalizar los datos
    final normalized = normalizeTwitter(params);

    // Guardar en el cubit
    final registerCubit = context.read<RegisterCubit>();
    final current = List<Map<String, dynamic>>.from(
      registerCubit.state.socialEcosystem ?? [],
    );

    current.add({'x': normalized});
    registerCubit.setSocialEcosystem(current);

    debugPrint("✅ Twitter conectado: $normalized");
  } catch (e, s) {
    debugPrint('❌ Error handleTwitter: $e\n$s');
  }
}
