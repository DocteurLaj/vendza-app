import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/data/services/order_draft_store.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class OrderCheckoutPage extends StatefulWidget {
  const OrderCheckoutPage({super.key});

  @override
  State<OrderCheckoutPage> createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  final _api = OrderApiService();
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = currentUserStore.value;
    _phoneController = TextEditingController(text: user.phoneNumber.trim());
    _addressController = TextEditingController(text: user.address.trim());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(OrderDraft draft) async {
    final error = orderDraftStore.validateCheckout(
      contactPhone: _phoneController.text,
      deliveryAddress: _addressController.text,
    );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.createOrder(
        items: draft.items
            .map((item) => item.toRequest())
            .toList(growable: false),
        idempotencyKey: OrderApiService.newIdempotencyKey(),
        contactPhone: _phoneController.text,
        deliveryAddress: _addressController.text,
        customerNote: _noteController.text,
      );
      orderDraftStore.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande envoyée au vendeur.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuyerOrdersPage()),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’envoyer la commande.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        title: const Text('Confirmer la commande'),
        backgroundColor: AppColors.appBackground(context),
        foregroundColor: AppColors.textPrimary(context),
      ),
      body: AnimatedBuilder(
        animation: orderDraftStore,
        builder: (context, _) {
          final draft = orderDraftStore.value;
          if (draft == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucune commande en préparation.',
                  style: AppTextStyles.cardTitle(context),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ResponsiveContent(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(draft: draft),
                    const SizedBox(height: 14),
                    ...draft.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DraftItemTile(item: item),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CheckoutFields(
                      phoneController: _phoneController,
                      addressController: _addressController,
                      noteController: _noteController,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _submitting ? null : () => _submit(draft),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _submitting ? 'Envoi...' : 'Envoyer la commande',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : orderDraftStore.clear,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Vider la commande'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.draft});

  final OrderDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commande chez ${draft.storeName}',
            style: AppTextStyles.cardTitle(context),
          ),
          const SizedBox(height: 6),
          Text(
            '${draft.totalItems} article(s) · ${draft.totalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paiement à la livraison. Le vendeur utilisera votre téléphone et votre adresse pour confirmer la livraison.',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}

class _DraftItemTile extends StatelessWidget {
  const _DraftItemTile({required this.item});

  final OrderDraftItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.unitPrice.toStringAsFixed(0)} × ${item.quantity} = ${item.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => orderDraftStore.decrement(item.product.id),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          IconButton(
            onPressed: () => orderDraftStore.increment(item.product.id),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _CheckoutFields extends StatelessWidget {
  const _CheckoutFields({
    required this.phoneController,
    required this.addressController,
    required this.noteController,
  });

  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact et livraison', style: AppTextStyles.cardTitle(context)),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone de contact *',
              hintText: '+243...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addressController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Adresse de livraison *',
              hintText: 'Avenue, quartier, commune, ville...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note pour le vendeur',
              hintText: 'Ex: Appelez-moi avant livraison.',
            ),
          ),
        ],
      ),
    );
  }
}
