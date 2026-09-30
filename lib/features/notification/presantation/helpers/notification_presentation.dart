import 'package:flutter/material.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';

extension NotificationPresentation on NotificationModel {
  String get displayTitle {
    return switch (name) {
      'store_order' => 'Nouvelle commande',
      'order' => 'Suivi de commande',
      'product_low_stock' => 'Stock faible',
      'product_out_of_stock' => 'Rupture de stock',
      'promotion' => 'Offre Vendza',
      'security' => 'Sécurité du compte',
      'system' => 'Information système',
      'admin_targeted' => 'Message Vendza',
      'general' => 'Annonce Vendza',
      _ => _humanizeType(name),
    };
  }

  String get categoryLabel {
    return switch (name) {
      'store_order' || 'order' => 'Commande',
      'product_low_stock' || 'product_out_of_stock' => 'Stock',
      'promotion' => 'Promotion',
      'security' => 'Sécurité',
      'system' => 'Système',
      'admin_targeted' || 'general' => 'Annonce',
      _ => 'Notification',
    };
  }

  String? get actionLabel {
    if (name == 'store_order' && storeId != null) return 'Voir la commande';
    if (name == 'order' && orderId != null) return 'Suivre la commande';
    if ((name == 'product_low_stock' || name == 'product_out_of_stock') &&
        storeId != null) {
      return 'Modifier le stock';
    }
    return null;
  }

  IconData get icon {
    return switch (name) {
      'store_order' => Icons.receipt_long_outlined,
      'order' => Icons.local_shipping_outlined,
      'product_low_stock' ||
      'product_out_of_stock' => Icons.inventory_2_outlined,
      'promotion' => Icons.local_offer_outlined,
      'security' => Icons.verified_user_outlined,
      'system' => Icons.info_outline,
      'admin_targeted' || 'general' => Icons.campaign_outlined,
      _ => Icons.notifications_none_outlined,
    };
  }
}

String _humanizeType(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) return 'Notification';
  return normalized[0].toUpperCase() + normalized.substring(1);
}
