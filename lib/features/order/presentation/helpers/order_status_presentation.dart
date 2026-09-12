import 'package:flutter/material.dart';

class OrderTimelineStep {
  const OrderTimelineStep({
    required this.status,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String status;
  final String label;
  final bool isCompleted;
  final bool isCurrent;
}

const _statusLabels = <String, String>{
  'pending': 'Commande reçue',
  'confirmed': 'Confirmée',
  'preparing': 'En préparation',
  'ready_for_delivery': 'Prête',
  'delivered': 'Livrée',
  'cancelled': 'Annulée',
};

const _statusDescriptions = <String, String>{
  'pending': 'En attente de confirmation du vendeur',
  'confirmed': 'Commande acceptée par le vendeur',
  'preparing': 'Les articles sont en préparation',
  'ready_for_delivery': 'Commande prête pour livraison ou retrait',
  'delivered': 'Commande terminée',
  'cancelled': 'Commande annulée',
};

const _nextStatuses = <String, String>{
  'pending': 'confirmed',
  'confirmed': 'preparing',
  'preparing': 'ready_for_delivery',
  'ready_for_delivery': 'delivered',
};

const _actionLabels = <String, String>{
  'pending': 'Confirmer',
  'confirmed': 'Préparer',
  'preparing': 'Marquer prête',
  'ready_for_delivery': 'Marquer livrée',
};

const _timelineStatuses = <String>[
  'pending',
  'confirmed',
  'preparing',
  'ready_for_delivery',
  'delivered',
];

String orderStatusLabel(String status) => _statusLabels[status] ?? status;

String orderStatusDescription(String status) {
  return _statusDescriptions[status] ?? 'Statut de commande mis à jour';
}

String? nextOrderStatus(String status) => _nextStatuses[status];

String? orderStatusActionLabel(String status) => _actionLabels[status];

IconData orderStatusIcon(String status) {
  return switch (status) {
    'pending' => Icons.inbox_outlined,
    'confirmed' => Icons.verified_outlined,
    'preparing' => Icons.inventory_2_outlined,
    'ready_for_delivery' => Icons.local_shipping_outlined,
    'delivered' => Icons.check_circle_outline,
    'cancelled' => Icons.cancel_outlined,
    _ => Icons.receipt_long_outlined,
  };
}

Color orderStatusColor(String status, BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    'pending' => dark ? const Color(0xFFFFD166) : const Color(0xFFB7791F),
    'confirmed' => dark ? const Color(0xFF90CDF4) : const Color(0xFF2B6CB0),
    'preparing' => dark ? const Color(0xFFC4B5FD) : const Color(0xFF6B46C1),
    'ready_for_delivery' =>
      dark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490),
    'delivered' => dark ? const Color(0xFF73C895) : const Color(0xFF2E8B57),
    'cancelled' => dark ? const Color(0xFFFCA5A5) : const Color(0xFFC53030),
    _ => Theme.of(context).colorScheme.primary,
  };
}

List<OrderTimelineStep> orderTimelineSteps(String status) {
  if (status == 'cancelled') {
    return const [
      OrderTimelineStep(
        status: 'cancelled',
        label: 'Annulée',
        isCompleted: true,
        isCurrent: true,
      ),
    ];
  }

  final currentIndex = _timelineStatuses.indexOf(status);
  final safeIndex = currentIndex < 0 ? 0 : currentIndex;
  return _timelineStatuses
      .map((stepStatus) {
        final index = _timelineStatuses.indexOf(stepStatus);
        return OrderTimelineStep(
          status: stepStatus,
          label: orderStatusLabel(stepStatus),
          isCompleted: index <= safeIndex,
          isCurrent: index == safeIndex,
        );
      })
      .toList(growable: false);
}
