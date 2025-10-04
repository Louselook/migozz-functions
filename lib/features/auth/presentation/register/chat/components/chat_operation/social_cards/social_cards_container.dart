import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/social_cards/social_cards.dart';

class SocialCardsContainer extends StatelessWidget {
  final List<Map<String, dynamic>> platforms;
  final String time;

  const SocialCardsContainer({
    super.key,
    required this.platforms,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener idioma del cubit
    final language = context.read<RegisterCubit>().state.language ?? '';
    final isSpanish = language.toLowerCase().contains('es');

    // Texto según idioma
    final headerText = isSpanish
        ? 'Aquí está la información extraída de sus redes sociales.'
        : 'Here is the information extracted from their social media platforms.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 15, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF9C27B0),
                      child: Icon(Icons.link, size: 14, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Migozz',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  headerText, // Texto dinámico
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: platforms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SocialCardMini(platformData: platforms[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              time,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
