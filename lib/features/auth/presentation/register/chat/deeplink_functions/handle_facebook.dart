import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

String _padB64(String s) {
  final mod = s.length % 4;
  if (mod != 0) s = s + ('=' * (4 - mod));
  return s;
}

void handleFacebook(String queryString, BuildContext context) {
  debugPrint('facebook deeplink raw query: $queryString');

  final params = Uri.splitQueryString(queryString);
  final payload = params['payload'];
  if (payload == null || payload.isEmpty) {
    debugPrint('handleFacebook: no payload');
    return;
  }

  try {
    final normalized = _padB64(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> data = json.decode(decoded);

    final registerCubit = context.read<RegisterCubit>();
    final current = List<Map<String, Map<String, dynamic>>>.from(
      registerCubit.state.socialEcosystem ?? [],
    );

    current.add({
      'facebook': {
        'id': data['id'],
        'name': data['name'],
        'email': data['email'],
        'profile_image_url': data['profile_image_url'],
        'pages': data['pages'],
      },
    });

    final avatar = data['profile_image_url'];
    if (avatar != null && avatar.toString().isNotEmpty) {
      registerCubit.setAvatarUrl(avatar);
    }

    registerCubit.setSocialEcosystem(current);
  } catch (e, st) {
    debugPrint('Error decoding Facebook payload: $e\n$st');
  }
}
