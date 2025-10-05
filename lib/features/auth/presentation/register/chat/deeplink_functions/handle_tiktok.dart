import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

String _padBase64(String s) {
  final mod = s.length % 4;
  if (mod != 0) s = s + ('=' * (4 - mod));
  return s;
}

void handleTikTok(String queryString, BuildContext context) {
  debugPrint('tiktok deeplink raw: $queryString');

  final params = Uri.splitQueryString(queryString);
  final payload = params['payload'];
  if (payload == null || payload.isEmpty) {
    debugPrint('handleTikTok: no payload');
    return;
  }

  try {
    final normalized = _padBase64(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> data = json.decode(decoded);

    final registerCubit = context.read<RegisterCubit>();
    final current = List<Map<String, Map<String, dynamic>>>.from(
      registerCubit.state.socialEcosystem ?? [],
    );

    current.add({
      'tiktok': {
        'id': data['id'],
        'username': data['username'],
        'display_name': data['display_name'],
        'profile_image_url': data['profile_image_url'],
        'followers_count': (data['followers_count'] ?? 0) is int
            ? data['followers_count']
            : int.tryParse('${data['followers_count']}') ?? 0,
        'following_count': (data['following_count'] ?? 0) is int
            ? data['following_count']
            : int.tryParse('${data['following_count']}') ?? 0,
        'likes_count': (data['likes_count'] ?? 0) is int
            ? data['likes_count']
            : int.tryParse('${data['likes_count']}') ?? 0,
        'video_count': (data['video_count'] ?? 0) is int
            ? data['video_count']
            : int.tryParse('${data['video_count']}') ?? 0,
      },
    });

    final avatar = data['profile_image_url'];
    if (avatar != null && avatar.toString().isNotEmpty) {
      registerCubit.setAvatarUrl(avatar);
    }

    registerCubit.setSocialEcosystem(current);
  } catch (e, st) {
    debugPrint('Error decoding TikTok payload: $e\n$st');
  }
}
