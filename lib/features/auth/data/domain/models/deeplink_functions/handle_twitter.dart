import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/data/domain/models/deeplink_functions/social_normalizer.dart';

void handleTwitter(String queryString, BuildContext context) {
  try {
    // 1️⃣ Parsear la query del deeplink
    final params = Uri.splitQueryString(queryString);

    // 2️⃣ Normalizar los datos
    final normalized = normalizeTwitter(params);

    // 3️⃣ Guardar en el cubit
    final registerCubit = context.read<RegisterCubit>();
    final current = List<Map<String, Map<String, dynamic>>>.from(
      registerCubit.state.socialEcosystem ?? [],
    );

    current.add({'twitter': normalized});
    registerCubit.setSocialEcosystem(current);

    debugPrint("✅ Twitter conectado: $normalized");
  } catch (e, s) {
    debugPrint('❌ Error handleTwitter: $e\n$s');
  }
}
