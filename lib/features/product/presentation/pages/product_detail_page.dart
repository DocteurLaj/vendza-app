import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/session/liked_products_store.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/shared/utils/phone_number.dart';
import 'package:vendza/features/product/presentation/widgets/product_detail_widgets.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/data/services/product_management_service.dart';
import 'package:vendza/features/store/presentation/widgets/custom_image_selector.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/utils/product_price_formatter.dart';
import 'package:vendza/shared/widgets/dialog/confirm_delete_dialog.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/core/services/media/app_image_picker.dart';
import 'package:vendza/core/services/product_event_api_service.dart';
import 'package:vendza/core/services/share/app_share_service.dart';
import 'package:vendza/core/services/share/whatsapp_seller_chat.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    this.ownerMode = false,
    this.section,
    this.position,
  });

  final ProductModel product;
  final bool ownerMode;
  final String? section;
  final int? position;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductModel _product;
  int? _selectedVariantIndex;
  bool _actionsExpanded = false;
  bool _detailsExpanded = true;
  bool _isLiked = false;
  bool _isBuying = false;
  final _orderApi = OrderApiService();

  ProductModel get product => _product;

  ProductVariantModel? get selectedVariant {
    final int? index = _selectedVariantIndex;
    if (index == null || index < 0 || index >= product.variants.length) {
      return null;
    }
    return product.variants[index];
  }

  String get displayedImage {
    final String variantImage = selectedVariant?.imageurl.trim() ?? "";
    return variantImage.isNotEmpty ? variantImage : product.imageurl;
  }

  String get displayedPrice {
    final String variantPrice = selectedVariant?.price.trim() ?? "";
    return variantPrice.isNotEmpty ? variantPrice : product.price;
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _isLiked = isProductLiked(product.id);
    if (product.variants.isNotEmpty) {
      _selectedVariantIndex = 0;
    }
    productEventApiService.trackSafely(
      eventType: 'product_open',
      productId: product.id,
      section: widget.section,
      position: widget.position,
    );
  }

  void _selectVariant(int index) {
    setState(() {
      _selectedVariantIndex = index;
    });
  }

  void _showProductImage() {
    setState(() {
      _detailsExpanded = false;
      _actionsExpanded = false;
    });
  }

  void _showProductDetails() {
    setState(() {
      _detailsExpanded = true;
    });
  }

  void _handlePanelDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity > 120) {
      _showProductImage();
      return;
    }
    if (velocity < -120) {
      _showProductDetails();
    }
  }

  void _toggleActions() {
    setState(() {
      _actionsExpanded = !_actionsExpanded;
    });
  }

  void _toggleLike() async {
    await catalogRepository.toggleProductFavorite(product.id);
    if (!mounted) return;
    setState(() {
      _isLiked = isProductLiked(product.id);
      _actionsExpanded = false;
    });
  }

  Future<void> _shareProduct() async {
    setState(() {
      _actionsExpanded = false;
    });
    await AppShareService.shareProduct(context, product);
  }

  Future<void> _contactSeller() async {
    productEventApiService.trackSafely(
      eventType: 'contact_click',
      productId: product.id,
      section: widget.section,
      position: widget.position,
    );

    final storeSocials = configuredStoreSocials(product.storeId);
    final whatsapp = storeSocials
        .where((item) => item.url != null && item.url!.contains('wa.me'))
        .map((item) => item.url!)
        .firstOrNull;
    final store = stores.where((item) => item.id == product.storeId).firstOrNull;
    final rawWhatsapp = whatsapp ?? store?.whatsappUrl.trim() ?? '';
    final link = rawWhatsapp.startsWith('http')
        ? rawWhatsapp
        : whatsappUrlFromPhone(rawWhatsapp);
    if (link.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun numero WhatsApp n\'est associe a ce store.'),
        ),
      );
      return;
    }
    final opened = await WhatsappSellerChat.open(
      whatsappLink: link,
      productId: product.id,
      productName: product.name,
      priceLabel: formatProductPriceLabel(displayedPrice),
      imageUrl: displayedImage,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp.')),
      );
    }
  }

  Future<void> _buyProduct() async {
    if (_isBuying || !product.isActive || widget.ownerMode) return;
    if (!NetworkStatus.ensureOnline(context)) return;
    final productId = int.tryParse(product.id);
    if (productId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit invalide.')));
      return;
    }

    setState(() => _isBuying = true);
    try {
      await _orderApi.createOrder(
        items: [OrderItemRequest(productId: productId, quantity: 1)],
        idempotencyKey: OrderApiService.newIdempotencyKey(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande envoyee au store.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de passer la commande pour le moment.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _openOwnerEditor() async {
    final updatedProduct = await showAppPopup<ProductModel>(
      context: context,
      size: PopupSize.large,
      scrollable: true,
      builder: (context) => _OwnerProductEditSheet(product: product),
    );

    if (updatedProduct == null) return;

    final saved = await _applyOwnerUpdate(updatedProduct);
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Produit mis à jour.")));
  }

  Future<void> _toggleProductVisibility(bool isActive) async {
    await _applyOwnerUpdate(product.copyWith(isActive: isActive));
  }

  Future<bool> _applyOwnerUpdate(ProductModel updatedProduct) async {
    try {
      await persistManagedProductUpdate(updatedProduct);
      if (!mounted) return true;
      setState(() {
        _product = updatedProduct;
        if (_selectedVariantIndex != null &&
            _selectedVariantIndex! >= product.variants.length) {
          _selectedVariantIndex = product.variants.isEmpty ? null : 0;
        }
      });
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Mise à jour impossible: $error")));
      return false;
    }
  }

  Future<void> _deleteOwnerProduct() async {
    final confirmed = await showConfirmDeleteDialog(
      context: context,
      title: "Supprimer le produit",
      message:
          "Ce produit sera retiré du store, des collections et des produits mis en avant.",
    );

    if (!confirmed) return;

    try {
      await persistManagedProductDelete(product);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Suppression impossible: $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double collapsedPanelHeight = 112;
          final double panelTopOffset = (constraints.maxHeight * 0.42)
              .clamp(260.0, 340.0)
              .toDouble();
          final double panelTop = _detailsExpanded
              ? panelTopOffset
              : constraints.maxHeight - collapsedPanelHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showProductImage,
                  onDoubleTap: _showProductDetails,
                  child: ProductDetailHero(
                    imageUrl: displayedImage,
                    showFullImage: !_detailsExpanded,
                    compactHeight: panelTopOffset + 34,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 14,
                child: ProductDetailBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (widget.ownerMode)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 66,
                  right: 14,
                  child: _OwnerProductTopBar(
                    isActive: product.isActive,
                    onEdit: _openOwnerEditor,
                    onVisibilityChanged: _toggleProductVisibility,
                    onDelete: _deleteOwnerProduct,
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 360),
                curve: Curves.fastOutSlowIn,
                left: 0,
                right: 0,
                top: panelTop,
                bottom: 0,
                child: ResponsiveContent(
                  maxWidth: 760,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _detailsExpanded ? null : _showProductDetails,
                    onVerticalDragEnd: _handlePanelDragEnd,
                    child: ProductDetailContentPanel(
                      product: product,
                      displayedPrice: displayedPrice,
                      selectedVariantIndex: _selectedVariantIndex,
                      socialItems: configuredStoreSocials(product.storeId),
                      isExpanded: _detailsExpanded,
                      minHeight: constraints.maxHeight - panelTop,
                      onVariantSelected: _selectVariant,
                      onContactSeller: _contactSeller,
                      onBuy: _buyProduct,
                      canBuy:
                          !widget.ownerMode && product.isActive && !_isBuying,
                      isBuying: _isBuying,
                    ),
                  ),
                ),
              ),
              if (!widget.ownerMode)
                ProductDetailFloatingActions(
                  expanded: _actionsExpanded,
                  isLiked: _isLiked,
                  onToggle: _toggleActions,
                  onLike: _toggleLike,
                  onShare: _shareProduct,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OwnerProductTopBar extends StatelessWidget {
  const _OwnerProductTopBar({
    required this.isActive,
    required this.onEdit,
    required this.onVisibilityChanged,
    required this.onDelete,
  });

  final bool isActive;
  final VoidCallback onEdit;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isActive
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.iconAccent(context),
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? "Actif" : "Inactif",
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: isActive,
              activeThumbColor: AppColors.accent(context),
              onChanged: onVisibilityChanged,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: "Modifier",
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.iconAccent(context),
            ),
          ),
          IconButton(
            tooltip: "Supprimer",
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}

class _OwnerProductEditSheet extends StatefulWidget {
  const _OwnerProductEditSheet({required this.product});

  final ProductModel product;

  @override
  State<_OwnerProductEditSheet> createState() => _OwnerProductEditSheetState();
}

class _OwnerProductEditSheetState extends State<_OwnerProductEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late String _currency;
  late String _imageUrl;
  late bool _isActive;
  late List<_VariantEditorDraft> _variants;
  String? _nameError;
  String? _priceError;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    final parsedPrice = parseProductPriceInputValue(product.price);
    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(text: parsedPrice.amount);
    _currency = parsedPrice.currency;
    _imageUrl = product.imageurl;
    _descriptionController = TextEditingController(text: product.description);
    _categoryController = TextEditingController(text: product.category);
    _isActive = product.isActive;
    _variants = product.variants
        .map((variant) => _VariantEditorDraft.fromModel(variant))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    for (final variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() {
      _variants.add(
        _VariantEditorDraft.empty(
          price: _priceController.text.trim(),
          currency: _currency,
        ),
      );
    });
  }

  void _removeVariant(int index) {
    setState(() {
      final variant = _variants.removeAt(index);
      variant.dispose();
    });
  }

  Future<void> _pickProductImage() async {
    final selectedImage = await pickAppImage(
      context,
      title: "Choisir l'image du produit",
    );

    if (selectedImage == null) return;
    setState(() {
      _imageUrl = selectedImage;
      _imageError = null;
    });
  }

  Future<void> _pickVariantImage(_VariantEditorDraft variant, int index) async {
    final selectedImage = await pickAppImage(
      context,
      title: "Image de la variante ${index + 1}",
    );

    if (selectedImage == null) return;
    setState(() {
      variant.imageUrl = selectedImage;
      if (variant.nameController.text.trim().isNotEmpty) {
        variant.error = null;
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final imageUrl = _imageUrl.trim();

    setState(() {
      _nameError = name.isEmpty ? "Le nom du produit est obligatoire." : null;
      _priceError = price.isEmpty
          ? "Le prix du produit est obligatoire."
          : null;
      _imageError = imageUrl.isEmpty
          ? "Ajoutez une image pour enregistrer ce produit."
          : null;
      for (final variant in _variants) {
        final hasImage = variant.imageUrl.trim().isNotEmpty;
        final hasName = variant.nameController.text.trim().isNotEmpty;
        variant.error = hasImage && !hasName
            ? "Ajoutez un nom pour cette variante ou retirez son image."
            : null;
      }
    });

    final variantErrors = _variants
        .map((variant) => variant.error)
        .whereType<String>()
        .toList();
    final errors = [?_nameError, ?_priceError, ?_imageError, ...variantErrors];

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.join("\n"))));
      return;
    }

    final variants = _variants
        .map((variant) => variant.toModel())
        .where(
          (variant) => variant.name.isNotEmpty || variant.imageurl.isNotEmpty,
        )
        .toList();

    Navigator.of(context).pop(
      widget.product.copyWith(
        name: name,
        price: "$price $_currency",
        imageurl: imageUrl,
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        isActive: _isActive,
        variants: variants,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackground(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Modifier le produit',
                    style: TextStyle(
                      color: AppColors.pageTitle(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                _OwnerEditCard(
                  children: [
                    _OwnerTextField(
                      label: "Nom *",
                      controller: _nameController,
                      errorText: _nameError,
                      onChanged: (value) {
                        if (_nameError != null && value.trim().isNotEmpty) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    _OwnerPriceField(
                      label: "Prix *",
                      controller: _priceController,
                      currency: _currency,
                      errorText: _priceError,
                      onChanged: (value) {
                        if (_priceError != null && value.trim().isNotEmpty) {
                          setState(() => _priceError = null);
                        }
                      },
                      onCurrencyChanged: (value) {
                        setState(() => _currency = value);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomImageSelector(
                        title: _imageUrl.isEmpty
                            ? "Ajouter une image"
                            : "Remplacer l'image",
                        subtitle: "Appuyez pour choisir une image",
                        imageUrl: _imageUrl,
                        icon: _imageUrl.isEmpty
                            ? Icons.add_a_photo_outlined
                            : Icons.edit_outlined,
                        onTap: _pickProductImage,
                        height: 154,
                      ),
                    ),
                    _OwnerFieldError(message: _imageError),
                    _OwnerTextField(
                      label: "Description",
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    _OwnerTextField(
                      label: "Catégorie",
                      controller: _categoryController,
                    ),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                      activeThumbColor: AppColors.accent(context),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Produit visible côté client",
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _OwnerEditCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Variantes",
                            style: TextStyle(
                              color: AppColors.cardTitle(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addVariant,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Ajouter"),
                        ),
                      ],
                    ),
                    const _OwnerVariantsNotice(),
                    ...List.generate(_variants.length, (index) {
                      final variant = _variants[index];
                      return _VariantEditorCard(
                        index: index,
                        variant: variant,
                        onPickImage: () => _pickVariantImage(variant, index),
                        onCurrencyChanged: (value) {
                          setState(() => variant.currency = value);
                        },
                        onNameChanged: (value) {
                          if (variant.error != null &&
                              value.trim().isNotEmpty) {
                            setState(() => variant.error = null);
                          }
                        },
                        onRemove: () => _removeVariant(index),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      "Enregistrer",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerEditCard extends StatelessWidget {
  const _OwnerEditCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _OwnerVariantsNotice extends StatelessWidget {
  const _OwnerVariantsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.iconAccent(context),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Optionnel: ajoutez des variantes seulement si ce produit existe en plusieurs choix.",
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerTextField extends StatelessWidget {
  const _OwnerTextField({
    required this.label,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.minLines,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          filled: true,
          fillColor: AppColors.searchSurface(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.accent(context),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerPriceField extends StatelessWidget {
  const _OwnerPriceField({
    required this.label,
    required this.controller,
    required this.currency,
    required this.onCurrencyChanged,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _OwnerThousandsInputFormatter(),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          filled: true,
          fillColor: AppColors.searchSurface(context),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currency,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.iconAccent(context),
                  size: 18,
                ),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                items: const [
                  DropdownMenuItem(value: "CDF", child: Text("CDF")),
                  DropdownMenuItem(value: "USD", child: Text("USD")),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  onCurrencyChanged(value);
                },
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 78,
            minHeight: 40,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.accent(context),
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _OwnerThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r"\D"), "");
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final buffer = StringBuffer();
    for (int index = 0; index < digits.length; index++) {
      final int remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(" ");
      }
    }

    final formattedValue = buffer.toString();
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

class _OwnerFieldError extends StatelessWidget {
  const _OwnerFieldError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantEditorCard extends StatelessWidget {
  const _VariantEditorCard({
    required this.index,
    required this.variant,
    required this.onPickImage,
    required this.onCurrencyChanged,
    required this.onNameChanged,
    required this.onRemove,
  });

  final int index;
  final _VariantEditorDraft variant;
  final VoidCallback onPickImage;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softSurface(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Variante ${index + 1}",
                  style: TextStyle(
                    color: AppColors.cardTitle(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          _OwnerTextField(
            label: "Nom",
            controller: variant.nameController,
            errorText: variant.error,
            onChanged: onNameChanged,
          ),
          _OwnerPriceField(
            label: "Prix",
            controller: variant.priceController,
            currency: variant.currency,
            onCurrencyChanged: onCurrencyChanged,
          ),
          CustomImageSelector(
            title: variant.imageUrl.isEmpty
                ? "Ajouter l'image"
                : "Remplacer l'image",
            subtitle: "Variante ${index + 1}",
            imageUrl: variant.imageUrl,
            icon: variant.imageUrl.isEmpty
                ? Icons.add_a_photo_outlined
                : Icons.edit_outlined,
            onTap: onPickImage,
            height: 112,
          ),
        ],
      ),
    );
  }
}

class _VariantEditorDraft {
  _VariantEditorDraft({
    required String name,
    required String price,
    required this.currency,
    required String initialImageUrl,
  }) : nameController = TextEditingController(text: name),
       priceController = TextEditingController(text: price),
       imageUrl = initialImageUrl;

  factory _VariantEditorDraft.fromModel(ProductVariantModel variant) {
    final parsedPrice = parseProductPriceInputValue(variant.price);
    return _VariantEditorDraft(
      name: variant.name,
      price: parsedPrice.amount,
      currency: parsedPrice.currency,
      initialImageUrl: variant.imageurl,
    );
  }

  factory _VariantEditorDraft.empty({
    required String price,
    required String currency,
  }) {
    return _VariantEditorDraft(
      name: "",
      price: price,
      currency: currency,
      initialImageUrl: "",
    );
  }

  final TextEditingController nameController;
  final TextEditingController priceController;
  String currency;
  String imageUrl;
  String? error;

  ProductVariantModel toModel() {
    final price = priceController.text.trim();
    return ProductVariantModel(
      name: nameController.text.trim(),
      price: price.isEmpty ? "" : "$price $currency",
      quantity: "",
      imageurl: imageUrl.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}
