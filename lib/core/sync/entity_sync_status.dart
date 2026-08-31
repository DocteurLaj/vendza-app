enum EntitySyncStatus { online, queued, syncing, waitingNetwork, error }

extension EntitySyncStatusX on EntitySyncStatus {
  bool get isPending => this != EntitySyncStatus.online;

  String get label => switch (this) {
    EntitySyncStatus.online => 'En ligne',
    EntitySyncStatus.queued => 'Envoi vers le serveur…',
    EntitySyncStatus.syncing => 'Envoi vers le serveur…',
    EntitySyncStatus.waitingNetwork => 'En attente de connexion',
    EntitySyncStatus.error => 'Échec de synchronisation',
  };

  String labelWithProgress(double progress) {
    if (this == EntitySyncStatus.syncing && progress > 0) {
      return '$label ${(progress * 100).clamp(0, 100).round()}%';
    }
    return label;
  }

  double? barValue(double progress) {
    switch (this) {
      case EntitySyncStatus.syncing:
        return progress <= 0 ? null : progress.clamp(0.0, 1.0);
      case EntitySyncStatus.queued:
      case EntitySyncStatus.waitingNetwork:
        return null;
      case EntitySyncStatus.error:
        return 0;
      case EntitySyncStatus.online:
        return 1;
    }
  }
}

bool isLocalEntityId(String id) => id.trim().startsWith('local-');
