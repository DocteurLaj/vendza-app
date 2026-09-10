import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/presantation/helpers/notification_presentation.dart';
import 'package:vendza/features/order/presentation/helpers/order_status_presentation.dart';

void main() {
  group('order status presentation', () {
    test('uses human labels and action labels for seller workflow', () {
      expect(orderStatusLabel('pending'), 'Commande reçue');
      expect(orderStatusLabel('confirmed'), 'Confirmée');
      expect(orderStatusLabel('preparing'), 'En préparation');
      expect(orderStatusLabel('ready_for_delivery'), 'Prête');
      expect(orderStatusLabel('delivered'), 'Livrée');
      expect(orderStatusLabel('cancelled'), 'Annulée');

      expect(nextOrderStatus('pending'), 'confirmed');
      expect(orderStatusActionLabel('confirmed'), 'Préparer');
      expect(orderStatusActionLabel('ready_for_delivery'), 'Marquer livrée');
      expect(orderStatusActionLabel('delivered'), isNull);
    });

    test('exposes ordered timeline steps', () {
      final steps = orderTimelineSteps('preparing');

      expect(steps.map((step) => step.label), [
        'Commande reçue',
        'Confirmée',
        'En préparation',
        'Prête',
        'Livrée',
      ]);
      expect(steps.where((step) => step.isCompleted), hasLength(3));
      expect(
        steps.singleWhere((step) => step.isCurrent).label,
        'En préparation',
      );
    });
  });

  group('notification presentation', () {
    test('turns order notifications into actionable cards', () {
      final notification = NotificationModel(
        id: '1',
        name: 'store_order',
        description: 'Nouvelle commande #20 reçue pour Hermes Store.',
        imageUrl: '',
        isRead: false,
        storeId: 22,
        orderId: 20,
      );

      expect(notification.displayTitle, 'Nouvelle commande');
      expect(notification.actionLabel, 'Voir la commande');
      expect(notification.icon, Icons.receipt_long_outlined);
      expect(notification.categoryLabel, 'Commande');
    });

    test('keeps general notification copy user-friendly', () {
      final notification = NotificationModel(
        id: '2',
        name: 'general',
        description: 'Bienvenue sur Vendza',
        imageUrl: '',
        isRead: true,
      );

      expect(notification.displayTitle, 'Annonce Vendza');
      expect(notification.actionLabel, isNull);
      expect(notification.categoryLabel, 'Annonce');
    });
  });
}
