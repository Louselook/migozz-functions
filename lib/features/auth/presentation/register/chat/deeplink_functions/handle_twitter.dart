import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';

void handleTwitter(String queryString, BuildContext context) {
  final params = Uri.splitQueryString(queryString);

  final registerCubit = context.read<RegisterCubit>();
  final current = List<Map<String, Map<String, dynamic>>>.from(
    registerCubit.state.socialEcosystem ?? [],
  );

  current.add({
    'twitter': {
      'id': params['id'],
      'name': params['name'],
      'username': params['username'],
      'profile_image_url': params['profile_image_url'],
      'followers_count': int.tryParse(params['followers_count'] ?? '0') ?? 0,
      'following_count': int.tryParse(params['following_count'] ?? '0') ?? 0,
      'tweet_count': int.tryParse(params['tweet_count'] ?? '0') ?? 0,
      'listed_count': int.tryParse(params['listed_count'] ?? '0') ?? 0,
      'like_count': int.tryParse(params['like_count'] ?? '0') ?? 0,
      'media_count': int.tryParse(params['media_count'] ?? '0') ?? 0,
    },
  });

  registerCubit.setSocialEcosystem(current);
}
