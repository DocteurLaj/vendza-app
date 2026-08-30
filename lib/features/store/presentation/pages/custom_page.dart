import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/upload/image_upload_controller.dart';
import 'package:vendza/features/collection/presentation/widgets/assign_products_dialog.dart';
import 'package:vendza/features/home/data/models/store_model.dart'
    as home_store;
import 'package:vendza/features/store/data/models/store_customization_model.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/data/services/product_management_service.dart';
import 'package:vendza/features/store/data/services/store_api_service.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/store/presentation/widgets/custom_product_picker_section.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/utils/phone_number.dart';
import 'package:vendza/shared/utils/social_url.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/input/phone_number_field.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class CustomPage extends StatefulWidget {
  const CustomPage({super.key, required this.store});

  final ListStoreModel store;

  @override
  State<CustomPage> createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final ImageUploadController _coverUpload;
  late final ImageUploadController _profileUpload;
  final _whatsappFieldKey = GlobalKey<PhoneNumberFieldState>();
  late String _initialWhatsapp;
  late List<ProductModel> _featuredProducts;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final customization = storeCustomization.value;
    final shouldUseCustomization = isOwnedStoreId(widget.store.id);
    _nameController = TextEditingController(
      text: shouldUseCustomization ? customization.name : widget.store.name,
    );
    _descriptionController = TextEditingController(
      text: shouldUseCustomization
          ? customization.description
          : widget.store.description,
    );
    _initialWhatsapp = customization.whatsappUrl;
    _instagramController = TextEditingController(
      text: customization.instagramUrl,
    );
    _facebookController = TextEditingController(
      text: customization.facebookUrl,
    );
    _coverUpload = ImageUploadController(
      initialUrl: shouldUseCustomization
          ? customization.coverImageUrl
          : widget.store.imageUrl,
      pickTitle: "Choisir la couverture",
    )..addListener(_onChanged);
    _profileUpload = ImageUploadController(
      initialUrl: shouldUseCustomization
          ? customization.profileImageUrl
          : widget.store.imageUrl,
      pickTitle: "Choisir la photo de profil",
    )..addListener(_onChanged);
    _featuredProducts = shouldUseCustomization
        ? List.of(customization.featuredProducts)
        : activeProductsForStore(widget.store).take(2).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _coverUpload
      ..removeListener(_onChanged)
      ..dispose();
    _profileUpload
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _selectFeaturedProducts() async {
    final selectedProducts = await showAssignProductsDialog(
      context: context,
      products: productsForStore(widget.store),
      selectedProducts: _featuredProducts,
      title: "Produits mis en avant",
      subtitle: "Choisis les produits à afficher sur l'accueil du store.",
    );

    if (selectedProducts == null) return;
    setState(() => _featuredProducts = selectedProducts);
  }

  StoreCustomizationModel _buildCustomizationDraft() {
    final whatsapp =
        _whatsappFieldKey.currentState?.value ??
        parsePhoneNumber(_initialWhatsapp);
    return StoreCustomizationModel(
      name: _nameController.text.trim().isEmpty
          ? "Ma boutique"
          : _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      coverImageUrl: _coverUpload.remoteUrl ?? _coverUpload.previewUrl,
      profileImageUrl: _profileUpload.remoteUrl ?? _profileUpload.previewUrl,
      whatsappUrl: whatsapp.e164.isEmpty
          ? ''
          : whatsappUrlFromPhone(whatsapp.e164),
      instagramUrl: _instagramController.text.trim(),
      facebookUrl: _facebookController.text.trim(),
      featuredProducts: _featuredProducts,
    );
  }

  Future<void> _saveCustomization() async {
    if (_isSubmitting ||
        _coverUpload.blocksSubmit ||
        _profileUpload.blocksSubmit) {
      return;
    }
    if (!isOwnedStoreId(widget.store.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez modifier que votre propre boutique.'),
        ),
      );
      return;
    }
    final storeId = int.tryParse(widget.store.id);
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Identifiant de boutique invalide")),
      );
      return;
    }

    final instagramError = validateInstagramUrl(_instagramController.text);
    final facebookError = validateFacebookUrl(_facebookController.text);
    if (instagramError != null || facebookError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(instagramError ?? facebookError!)),
      );
      return;
    }

    final previousCover = storeCustomization.value.coverImageUrl;
    final previousProfile = storeCustomization.value.profileImageUrl;
    setState(() => _isSubmitting = true);
    try {
      final coverImage = _coverUpload.hasImage
          ? await _coverUpload.ensureRemoteUrl()
          : '';
      final profileImage = _profileUpload.hasImage
          ? await _profileUpload.ensureRemoteUrl()
          : '';
      final draft = _buildCustomizationDraft();
      final resolvedCustomization = StoreCustomizationModel(
        name: draft.name,
        description: draft.description,
        coverImageUrl: coverImage,
        profileImageUrl: profileImage,
        whatsappUrl: draft.whatsappUrl,
        instagramUrl: draft.instagramUrl,
        facebookUrl: draft.facebookUrl,
        featuredProducts: draft.featuredProducts,
      );

      await StoreApiService().updateStore(
        storeId: storeId,
        name: resolvedCustomization.name,
        description: resolvedCustomization.description,
        image: resolvedCustomization.profileImageUrl.isEmpty
            ? resolvedCustomization.coverImageUrl
            : resolvedCustomization.profileImageUrl,
        bannerUrl: resolvedCustomization.coverImageUrl,
        whatsappUrl: resolvedCustomization.whatsappUrl,
        instagramUrl: resolvedCustomization.instagramUrl,
        facebookUrl: resolvedCustomization.facebookUrl,
      );
      updateStoreCustomizationForStore(widget.store.id, resolvedCustomization);
      await SmartImage.evict(previousCover);
      await SmartImage.evict(previousProfile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Modifications enregistrées"),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : "Enregistrement impossible. Réessayez.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _previewStorefront() {
    final customization = _buildCustomizationDraft();
    updateStoreCustomizationForStore(widget.store.id, customization);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailPage(
          store: home_store.StoreModel(
            name: customization.name,
            id: widget.store.id,
            image: customization.coverImageUrl,
            description: customization.description,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.isDark(context)
            ? AppColors.darkSurface
            : AppColors.primary,
        foregroundColor: AppColors.isDark(context)
            ? AppColors.darkTextPrimary
            : Colors.white,
        centerTitle: true,
        title: const Text("Custom"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        child: ResponsiveContent(
          maxWidth: AppBreakpoints.contentMaxWidth,
          child: Column(
            children: [
              const _CustomPageIntro(),
              const SizedBox(height: 12),
              CustomMediaSection(
                coverController: _coverUpload,
                profileController: _profileUpload,
                enabled: !_isSubmitting,
              ),
              CustomFormSection(
                nameController: _nameController,
                descriptionController: _descriptionController,
              ),
              CustomSocialLinksSection(
                whatsappField: PhoneNumberField(
                  key: _whatsappFieldKey,
                  label: "WhatsApp",
                  initialValue: _initialWhatsapp,
                  enabled: !_isSubmitting,
                ),
                instagramController: _instagramController,
                facebookController: _facebookController,
              ),
              CustomProductPickerSection(
                products: _featuredProducts,
                onSelectProducts: _selectFeaturedProducts,
              ),
              const SizedBox(height: 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _previewStorefront,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text(
                      "Voir ma page",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent(context),
                      side: BorderSide(color: AppColors.accent(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.infinity,
                  child: AppBouton(
                    text: "Enregistrer les changements",
                    loadingText: "Enregistrement...",
                    onPressed: _saveCustomization,
                    enabled:
                        !_isSubmitting &&
                        !_coverUpload.blocksSubmit &&
                        !_profileUpload.blocksSubmit,
                    isLoading: _isSubmitting,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomPageIntro extends StatelessWidget {
  const _CustomPageIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF145A55)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personnalise ta boutique",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Gère l'image, les contacts et les produits visibles.",
                  style: TextStyle(
                    color: Color(0xDDEAF2EF),
                    fontSize: 12,
                    height: 1.25,
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
