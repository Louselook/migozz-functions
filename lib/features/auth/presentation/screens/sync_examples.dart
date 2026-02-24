import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/services/add_networks/social_ecosystem_sync_service.dart';
import 'package:migozz_app/features/auth/presentation/widgets/social_ecosystem_sync_status_widget.dart';

/// EJEMPLOS DE CÓMO USAR EL SISTEMA DE SINCRONIZACIÓN EN TU APP

// ============================================================================
// EJEMPLO 1: Pantalla de Perfil Completa con Widget
// ============================================================================

class UserProfileScreenExample extends StatefulWidget {
  final UserDTO user;
  final String userId;

  const UserProfileScreenExample({
    required this.user,
    required this.userId,
    super.key,
  });

  @override
  State<UserProfileScreenExample> createState() =>
      _UserProfileScreenExampleState();
}

class _UserProfileScreenExampleState extends State<UserProfileScreenExample> {
  late UserDTO currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentUser.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar y nombre
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: currentUser.avatarUrl != null
                        ? NetworkImage(currentUser.avatarUrl!)
                        : null,
                    onBackgroundImageError: currentUser.avatarUrl != null
                        ? (_, __) {}
                        : null,
                    child: currentUser.avatarUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${currentUser.username}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 🆕 WIDGET DE SINCRONIZACIÓN
            // Muestra estado y permite sincronizar manualmente
            SocialEcosystemSyncStatusWidget(
              user: currentUser,
              userId: widget.userId,
              onSyncComplete: () {
                // Recargar datos del usuario
                _reloadUserData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Datos actualizados correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onSyncError: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error al sincronizar'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Otras secciones del perfil
            const Text(
              'Bio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(currentUser.bio ?? 'Sin bio'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _reloadUserData() {
    // Aquí puedes recargar los datos del usuario desde Firestore
    // o actualizar el estado local
    setState(() {
      // currentUser = userProvider.getUser();
    });
  }
}

// ============================================================================
// EJEMPLO 2: Usar el Servicio Directamente (Control Manual)
// ============================================================================

class SyncServiceExampleScreen extends StatefulWidget {
  final String userId;

  const SyncServiceExampleScreen({required this.userId, super.key});

  @override
  State<SyncServiceExampleScreen> createState() =>
      _SyncServiceExampleScreenState();
}

class _SyncServiceExampleScreenState extends State<SyncServiceExampleScreen> {
  final _syncService = SocialEcosystemSyncService();
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización Manual')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Control Manual de Sincronización',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Botón de sincronización
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _syncNow,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                _isLoading ? 'Sincronizando...' : 'Sincronizar Ahora',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 32),

            // Mensaje de estado
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Información
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '📊 Información:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• La sincronización ocurre automáticamente cada 15 días',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Puedes sincronizar manualmente usando este botón',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• El proceso toma ~10 segundos por red social',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '⏳ Sincronizando...';
    });

    try {
      final result = await _syncService.syncUserNetworks(widget.userId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '✅ Sincronización completada\n${result['data']}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ Error: ${e.toString()}';
        });
      }
    }
  }
}

// ============================================================================
// EJEMPLO 3: Verificar Estado de Sincronización (Solo Lectura)
// ============================================================================

class SyncStatusCheckExample extends StatelessWidget {
  final UserDTO user;

  const SyncStatusCheckExample({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = SocialEcosystemSyncService();

    // Verificar si necesita sincronización
    final needsSync = syncService.needsSyncByDays(
      user.lastSocialEcosystemSync,
      intervalDays: 15,
    );

    // Obtener texto formateado
    final statusText = syncService.getSyncStatusMessage(
      user.lastSocialEcosystemSync,
      intervalDays: 15,
    );

    // Obtener tiempo de última sincronización
    final lastSyncTime = syncService.getLastSyncFormattedText(
      user.lastSocialEcosystemSync,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Estado de Sincronización')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado visual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: needsSync
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: needsSync ? Colors.orange : Colors.green,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        needsSync
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: needsSync ? Colors.orange : Colors.green,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: needsSync ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Última actualización: $lastSyncTime',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Información de redes
            if (user.socialEcosystem != null &&
                user.socialEcosystem!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Redes Conectadas (${user.socialEcosystem!.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: user.socialEcosystem!.length,
                    itemBuilder: (context, index) {
                      final network = user.socialEcosystem![index];
                      final platform = network['platform'] ?? 'Unknown';
                      final followers = network['followers'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  platform.substring(0, 1).toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      platform.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Seguidores: $followers',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            else
              const Center(child: Text('Sin redes sociales agregadas')),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 4: Badge Simple en ListTile
// ============================================================================

class UserListTileWithSyncBadge extends StatelessWidget {
  final UserDTO user;

  const UserListTileWithSyncBadge({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        onBackgroundImageError: user.avatarUrl != null ? (_, __) {} : null,
        child: user.avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.displayName),
      subtitle: Text('@${user.username}'),
      trailing: SocialEcosystemSyncStatusBadge(
        lastSync: user.lastSocialEcosystemSync,
        intervalDays: 15,
      ),
      onTap: () {
        // Navegar a perfil detallado
      },
    );
  }
}

// ============================================================================
// EJEMPLO 5: Dashboard de Sincronización
// ============================================================================

class SyncDashboardExample extends StatefulWidget {
  final List<UserDTO> users;

  const SyncDashboardExample({required this.users, super.key});

  @override
  State<SyncDashboardExample> createState() => _SyncDashboardExampleState();
}

class _SyncDashboardExampleState extends State<SyncDashboardExample> {
  final _syncService = SocialEcosystemSyncService();

  @override
  Widget build(BuildContext context) {
    // Calcular estadísticas
    int totalUsers = widget.users.length;
    int needsSync = widget.users
        .where(
          (u) => _syncService.needsSyncByDays(
            u.lastSocialEcosystemSync,
            intervalDays: 15,
          ),
        )
        .length;
    int upToDate = totalUsers - needsSync;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard de Sincronización')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total',
                    value: '$totalUsers',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Al Día',
                    value: '$upToDate',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Necesitan Sync',
                    value: '$needsSync',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Listado de usuarios
            const Text(
              'Usuarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.users.length,
                itemBuilder: (context, index) {
                  final user = widget.users[index];
                  return UserListTileWithSyncBadge(user: user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
