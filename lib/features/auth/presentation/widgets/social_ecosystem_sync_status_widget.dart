import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/services/add_networks/social_ecosystem_sync_service.dart';

/// Widget que muestra el estado de sincronización de redes sociales
/// y permite sincronizar manualmente
class SocialEcosystemSyncStatusWidget extends StatefulWidget {
  final UserDTO user;
  final String userId;
  final VoidCallback? onSyncComplete;
  final VoidCallback? onSyncError;

  const SocialEcosystemSyncStatusWidget({
    required this.user,
    required this.userId,
    this.onSyncComplete,
    this.onSyncError,
    Key? key,
  }) : super(key: key);

  @override
  State<SocialEcosystemSyncStatusWidget> createState() =>
      _SocialEcosystemSyncStatusWidgetState();
}

class _SocialEcosystemSyncStatusWidgetState
    extends State<SocialEcosystemSyncStatusWidget> {
  final _syncService = SocialEcosystemSyncService();
  bool _isSyncing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final lastSync = widget.user.lastSocialEcosystemSync;
    final statusText = _syncService.getSyncStatusMessage(lastSync);
    final formattedTime = _syncService.getLastSyncFormattedText(lastSync);
    final needsSync = _syncService.needsSyncByDays(lastSync);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                const Icon(Icons.sync, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Estado de Redes Sociales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: needsSync
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: needsSync ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última actualización: $formattedTime',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botón de sincronización
            if (widget.user.socialEcosystem != null &&
                widget.user.socialEcosystem!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _handleSync,
                  icon: _isSyncing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isSyncing ? 'Actualizando...' : 'Actualizar ahora',
                  ),
                ),
              )
            else
              const SizedBox(
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Sin redes sociales agregadas',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),

            // Mensaje de error
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Info de redes
            if (widget.user.socialEcosystem != null &&
                widget.user.socialEcosystem!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Redes sincronizadas (${widget.user.socialEcosystem!.length}):',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.user.socialEcosystem!.map((network) {
                  String platform = network['platform']?.toString() ?? '';
                  dynamic payload = network;

                  // Soporta formato B: { instagram: { ... } }
                  if (platform.isEmpty && network.isNotEmpty) {
                    platform = network.keys.first.toString();
                    payload = network[platform];
                  }

                  platform = platform.isEmpty ? 'Unknown' : platform;

                  final followers = (payload is Map)
                      ? (payload['followers'] ?? payload['followersCount'] ?? 0)
                      : (network['followers'] ?? 0);

                  final platformLetter = platform.isNotEmpty
                      ? platform.substring(0, 1).toUpperCase()
                      : '?';

                  return Chip(
                    label: Text(
                      '$platform ($followers)',
                      style: const TextStyle(fontSize: 11),
                    ),
                    avatar: CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      child: Text(
                        platformLetter,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      await _syncService.syncUserNetworks(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Redes sociales actualizadas correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        widget.onSyncComplete?.call();
        setState(() {
          _isSyncing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _errorMessage = 'Error: ${e.toString()}';
        });

        widget.onSyncError?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

/// Widget simplificado que solo muestra el estado
class SocialEcosystemSyncStatusBadge extends StatelessWidget {
  final DateTime? lastSync;
  final int intervalDays;

  const SocialEcosystemSyncStatusBadge({
    required this.lastSync,
    this.intervalDays = 15,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final syncService = SocialEcosystemSyncService();
    final needsSync = syncService.needsSyncByDays(
      lastSync,
      intervalDays: intervalDays,
    );
    final statusText = syncService.getSyncStatusMessage(
      lastSync,
      intervalDays: intervalDays,
    );

    return Tooltip(
      message: statusText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: needsSync
              ? Colors.orange.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: needsSync ? Colors.orange : Colors.green,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              needsSync ? Icons.refresh : Icons.check_circle,
              size: 14,
              color: needsSync ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              needsSync ? 'Actualizar' : 'Al día',
              style: TextStyle(
                fontSize: 12,
                color: needsSync ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
