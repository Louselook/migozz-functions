// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
// import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.userProfile;

    if (!authState.isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: user == null
              ? const Center(child: Text('Cargando perfil...'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      PrimaryText(
                        user.displayName,
                        color: AppColors.backgroundDark,
                      ),
                      const SizedBox(height: 8),
                      SecondaryText(user.email, color: AppColors.grey),
                      const SizedBox(height: 16),

                      // Basic fields
                      ListTile(
                        title: const Text('Username'),
                        subtitle: Text(user.username),
                      ),
                      ListTile(
                        title: const Text('Phone'),
                        subtitle: Text(user.phone ?? '-'),
                      ),
                      ListTile(
                        title: const Text('Gender'),
                        subtitle: Text(user.gender),
                      ),
                      ListTile(
                        title: const Text('Location'),
                        subtitle: Text(
                          '${user.location.city}, ${user.location.state}, ${user.location.country}',
                        ),
                      ),

                      // Category
                      if (user.category != null && user.category!.isNotEmpty)
                        ListTile(
                          title: const Text('Category'),
                          subtitle: Wrap(
                            spacing: 8,
                            children: user.category!
                                .map((c) => Chip(label: Text(c)))
                                .toList(),
                          ),
                        ),

                      // Interests (map)
                      if (user.interests.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              'Interests',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...user.interests.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 110, child: Text(e.key)),
                                    Expanded(child: Text(e.value.join(', '))),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // Social ecosystem: iterate list of maps
                      if (user.socialEcosystem != null &&
                          user.socialEcosystem!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Socials',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...user.socialEcosystem!.map((map) {
                              // cada map puede contener por ejemplo: { "tiktok": { ... } }
                              final key = map.keys.isNotEmpty
                                  ? map.keys.first
                                  : 'unknown';
                              final value = map.values.first;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(key),
                                  subtitle: value is Map
                                      ? Text(
                                          value.entries
                                              .map(
                                                (e) => '${e.key}: ${e.value}',
                                              )
                                              .join('\n'),
                                        )
                                      : Text(value.toString()),
                                ),
                              );
                            }),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // voice note
                      if (user.voiceNoteUrl != null &&
                          user.voiceNoteUrl!.isNotEmpty)
                        Column(
                          children: [
                            const Text('Voice note available'),
                            const SizedBox(height: 8),
                            Text(user.voiceNoteUrl!),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Timestamps
                      // ListTile(title: const Text('Created at'), subtitle: Text(_formatDate(user.createdAt))),
                      // ListTile(title: const Text('Updated at'), subtitle: Text(_formatDate(user.updatedAt))),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final authCubit = context.read<AuthCubit>();
                          await authCubit.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
