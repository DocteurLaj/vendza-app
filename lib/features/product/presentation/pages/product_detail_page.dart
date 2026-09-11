import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/services/product_event_api_service.dart';
import 'package:vendza/core/services/moderation_api_service.dart';
import 'package:vendza/core/session/liked_products_store.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/product/presentation/widgets/product_detail_widgets.dart';
import 'package:vendza/features/product/presentation/widgets/product_image_gallery_field.dart';
import 'package:vendza/features/product/presentation/widgets/product_category_selector.dart';
import 'package:vendza/features/order/data/services/order_store.dart';
import 'package:vendza/features/order/presentation/pages/order_checkout_page.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/data/services/product_management_service.dart';
import 'package:vendza/features/store/data/services/product_api_service.dart';
import 'package:vendza/features/store/presentation/widgets/custom_image_selector.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/utils/product_price_formatter.dart';
import 'package:vendza/shared/widgets/dialog/confirm_delete_dialog.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/core/services/media/app_image_picker.dart';
import 'package:vendza/core/services/share/app_share_service.dart';
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

  Future<void> _toggleLike() async {
    try {
      final isLiked = await toggleLikedProduct(product.id);
      if (!mounted) return;
      setState(() {
        _isLiked = isLiked;
        _actionsExpanded = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Favori non modifié : $error')));
    }
  }

  Future<void> _shareProduct() async {
    setState(() {
      _actionsExpanded = false;
    });
    await AppShareService.shareProduct(context, product);
  }

  void _contactSeller() {
    final updatedProduct = registerProductContactClick(product);
    setState(() {
      _product = updatedProduct;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Demande envoyee pour ${product.name}")),
    );
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
    if (!saved) return;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Produit mis à jour.")));
  }

  Future<void> _toggleProductVisibility(bool isActive) async {
    if (product.adminDisabled && isActive) {
      final reason = product.moderationReason.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason.isEmpty
                ? "Ce produit a été désactivé par Vendza."
                : "Désactivé par Vendza : $reason",
          ),
        ),
      );
      return;
    }
    await _applyOwnerUpdate(product.copyWith(isActive: isActive));
  }

  Future<void> _requestModerationReview() async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Demander une révision"),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Expliquez pourquoi ce produit doit être réactivé.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Envoyer"),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.length < 3) return;
    try {
      await ModerationApiService().requestReview(
        targetType: 'product',
        targetId: product.id,
        message: message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande envoyée à l'administration.")),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Envoi impossible : $error")));
    }
  }

  Future<void> _orderProduct() async {
    final order = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderCheckoutPage(product: product)),
    );
    if (order == null || !mounted) return;
    prependBuyerOrder(order);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Commande #${order.id} créée avec succès.')),
    );
  }

  Future<bool> _applyOwnerUpdate(ProductModel updatedProduct) async {
    final storeId = int.tryParse(updatedProduct.storeId);
    final productId = int.tryParse(updatedProduct.id);
    if (storeId == null || productId == null) return false;
    final numericPrice = double.tryParse(
      updatedProduct.price.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final currency = updatedProduct.price.toUpperCase().contains('USD')
        ? 'USD'
        : 'CDF';
    try {
      await ProductApiService().updateProduct(
        storeId: storeId,
        productId: productId,
        title: updatedProduct.name,
        description: updatedProduct.description,
        price: numericPrice,
        currency: currency,
        stock: updatedProduct.stock,
        category: updatedProduct.category,
        isActive: updatedProduct.isActive,
        images: updatedProduct.images.isEmpty
            ? [updatedProduct.imageurl]
            : updatedProduct.images,
        variation: {
          'items': updatedProduct.variants
              .map(
                (variant) => {
                  'name': variant.name,
                  'price': variant.price,
                  'quantity': variant.quantity,
                  'imageurl': variant.imageurl,
                },
              )
              .toList(),
        },
      );
      updateManagedProduct(updatedProduct);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mise à jour impossible : $error')),
        );
      }
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

    final storeId = int.tryParse(product.storeId);
    final productId = int.tryParse(product.id);
    if (storeId == null || productId == null) return;
    try {
      await ProductApiService().deleteProduct(
        storeId: storeId,
        productId: productId,
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $error')),
      );
      return;
    }
    deleteManagedProduct(product);
    if (!mounted) return;
    Navigator.of(context).pop(true);
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
                    adminDisabled: product.adminDisabled,
                    moderationReason: product.moderationReason,
                    onEdit: _openOwnerEditor,
                    onVisibilityChanged: _toggleProductVisibility,
                    onRequestReview: _requestModerationReview,
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
                      onBuyNow:
                          !widget.ownerMode &&
                              product.storeDeliveryEnabled &&
                              product.isActive &&
                              product.stock > 0
                          ? _orderProduct
                          : null,
                      onContactSeller: _contactSeller,
                    ),
                  ),
                ),
              ),
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
    required this.adminDisabled,
    required this.moderationReason,
    required this.onEdit,
    required this.onVisibilityChanged,
    required this.onRequestReview,
    required this.onDelete,
  });

  final bool isActive;
  final bool adminDisabled;
  final String moderationReason;
  final VoidCallback onEdit;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onRequestReview;
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
            adminDisabled
                ? "Bloqué par Vendza"
                : (isActive ? "Actif" : "Inactif"),
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!adminDisabled)
            Tooltip(
              message: "",
              child: Transform.scale(
                scale: 0.78,
                child: Switch(
                  value: isActive,
                  activeThumbColor: AppColors.accent(context),
                  onChanged: onVisibilityChanged,
                ),
              ),
            ),
          if (adminDisabled)
            IconButton(
              tooltip: moderationReason.trim().isEmpty
                  ? "Demander une révision"
                  : "Motif : $moderationReason",
              onPressed: onRequestReview,
              icon: const Icon(Icons.rate_review_outlined),
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
  late final TextEditingController _stockController;
  late String _category;
  late String _currency;
  late List<String> _imageUrls;
  late bool _isActive;
  late List<_VariantEditorDraft> _variants;
  String? _nameError;
  String? _priceError;
  String? _imageError;
  String? _stockError;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    final parsedPrice = parseProductPriceInputValue(product.price);
    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(text: parsedPrice.amount);
    _currency = parsedPrice.currency;
    _imageUrls = product.images.isEmpty
        ? [if (product.imageurl.trim().isNotEmpty) product.imageurl]
        : List<String>.from(product.images);
    _descriptionController = TextEditingController(text: product.description);
    _stockController = TextEditingController(text: '${product.stock}');
    _category = product.category;
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
    _stockController.dispose();
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

  void _changeStock(int delta) {
    final current = int.tryParse(_stockController.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    setState(() {
      _stockController.text = '$next';
      _stockError = null;
    });
  }

  String get _primaryImageUrl => _imageUrls.isEmpty ? '' : _imageUrls.first;

  Future<void> _pickProductImage() async {
    final selectedImage = await pickAppImage(
      context,
      title: "Choisir l'image du produit",
    );

    if (selectedImage == null) return;
    setState(() {
      if (_imageUrls.isEmpty) {
        _imageUrls.add(selectedImage);
      } else {
        _imageUrls[0] = selectedImage;
      }
      _imageError = null;
    });
  }

  Future<void> _addProductImage() async {
    if (_imageUrls.length >= ProductImagePolicy.currentMaxImages) {
      await showProductImageLimitSheet(
        context,
        maxImages: ProductImagePolicy.currentMaxImages,
      );
      return;
    }

    final selectedImage = await pickAppImage(
      context,
      title: "Ajouter une image d'illustration",
    );
    if (selectedImage == null || !mounted) return;
    setState(() {
      _imageUrls.add(selectedImage);
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
    final images = _imageUrls
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList(growable: false);
    final imageUrl = images.isEmpty ? '' : images.first;
    final stock = int.tryParse(_stockController.text.trim());

    setState(() {
      _nameError = name.isEmpty ? "Le nom du produit est obligatoire." : null;
      _priceError = price.isEmpty
          ? "Le prix du produit est obligatoire."
          : null;
      _imageError = imageUrl.isEmpty
          ? "Ajoutez une image pour enregistrer ce produit."
          : null;
      _stockError = stock == null || stock < 0
          ? 'Entrez un stock valide.'
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
    final errors = [
      ?_nameError,
      ?_priceError,
      ?_imageError,
      ?_stockError,
      ...variantErrors,
    ];

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
        images: images,
        description: _descriptionController.text.trim(),
        category: _category,
        stock: stock!,
        status: stock > 0 ? 'En stock' : 'Rupture de stock',
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
                    CustomImageSelector(
                      title: _primaryImageUrl.isEmpty
                          ? "Ajouter une image"
                          : "Remplacer l'image",
                      subtitle: "Appuyez pour choisir l'image principale",
                      imageUrl: _primaryImageUrl,
                      icon: _primaryImageUrl.isEmpty
                          ? Icons.add_a_photo_outlined
                          : Icons.edit_outlined,
                      onTap: _pickProductImage,
                      height: 154,
                    ),
                    const SizedBox(height: 12),
                    ProductImageGalleryField(
                      images: _imageUrls,
                      maxImages: ProductImagePolicy.currentMaxImages,
                      onAddPressed: _addProductImage,
                      onImagePressed: (_) => _pickProductImage(),
                    ),
                    const SizedBox(height: 12),
                    _OwnerFieldError(message: _imageError),
                    _OwnerTextField(
                      label: "Description",
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    _OwnerStockField(
                      controller: _stockController,
                      errorText: _stockError,
                      onChanged: (value) {
                        if (_stockError != null && value.trim().isNotEmpty) {
                          setState(() => _stockError = null);
                        }
                      },
                      onDecrease: () => _changeStock(-1),
                      onIncrease: () => _changeStock(1),
                      onIncreaseTen: () => _changeStock(10),
                    ),
                    ProductCategorySelector(
                      storeId: widget.product.storeId,
                      selectedCategory: _category,
                      onChanged: (value) {
                        setState(() => _category = value);
                      },
                    ),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: widget.product.adminDisabled
                          ? null
                          : (value) {
                              setState(() => _isActive = value);
                            },
                      activeThumbColor: AppColors.accent(context),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        widget.product.adminDisabled
                            ? "Produit désactivé par Vendza"
                            : "Produit visible côté client",
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: widget.product.adminDisabled
                          ? Text(
                              widget.product.moderationReason.trim().isEmpty
                                  ? "Contactez l'administration pour demander une révision."
                                  : widget.product.moderationReason,
                            )
                          : null,
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

class _OwnerStockField extends StatelessWidget {
  const _OwnerStockField({
    required this.controller,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.onIncreaseTen,
    this.errorText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onIncreaseTen;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: 'Stock disponible',
              errorText: errorText,
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              filled: true,
              fillColor: AppColors.searchSurface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove, size: 17),
                label: const Text('-1'),
              ),
              OutlinedButton.icon(
                onPressed: onIncrease,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('+1'),
              ),
              OutlinedButton.icon(
                onPressed: onIncreaseTen,
                icon: const Icon(Icons.add_box_outlined, size: 17),
                label: const Text('+10'),
              ),
            ],
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
