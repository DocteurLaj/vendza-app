import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
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
import 'package:vendza/core/services/media/app_image_picker.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class CustomPage extends StatefulWidget {
  const CustomPage({super.key, required this.store});

  final ListStoreModel store;

  @override
  State<CustomPage> createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late String _coverImageUrl;
  late String _profileImageUrl;
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
    _whatsappController = TextEditingController(
      text: customization.whatsappUrl,
    );
    _instagramController = TextEditingController(
      text: customization.instagramUrl,
    );
    _facebookController = TextEditingController(
      text: customization.facebookUrl,
    );
    _coverImageUrl = shouldUseCustomization
        ? customization.coverImageUrl
        : widget.store.imageUrl;
    _profileImageUrl = shouldUseCustomization
        ? customization.profileImageUrl
        : widget.store.imageUrl;
    _featuredProducts = shouldUseCustomization
        ? List.of(customization.featuredProducts)
        : activeProductsForStore(widget.store).take(2).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required String title,
    required ValueChanged<String> onSelected,
  }) async {
    final selectedImage = await pickAppImage(context, title: title);

    if (selectedImage == null) return;
    setState(() => onSelected(selectedImage));
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
    return StoreCustomizationModel(
      name: _nameController.text.trim().isEmpty
          ? "Ma boutique"
          : _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      coverImageUrl: _coverImageUrl,
      profileImageUrl: _profileImageUrl,
      whatsappUrl: _whatsappController.text.trim(),
      instagramUrl: _instagramController.text.trim(),
      facebookUrl: _facebookController.text.trim(),
      featuredProducts: _featuredProducts,
    );
  }

  Future<void> _saveCustomization() async {
    if (_isSubmitting) return;
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
    final customization = _buildCustomizationDraft();

    setState(() => _isSubmitting = true);
    try {
      final coverImage = await uploadApiService.resolveImageUrl(
        customization.coverImageUrl,
      );
      final profileImage = await uploadApiService.resolveImageUrl(
        customization.profileImageUrl,
      );
      final resolvedCustomization = StoreCustomizationModel(
        name: customization.name,
        description: customization.description,
        coverImageUrl: coverImage,
        profileImageUrl: profileImage,
        whatsappUrl: customization.whatsappUrl,
        instagramUrl: customization.instagramUrl,
        facebookUrl: customization.facebookUrl,
        featuredProducts: customization.featuredProducts,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Personnalisation enregistrée"),
          duration: Duration(seconds: 2),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
                coverImageUrl: _coverImageUrl,
                profileImageUrl: _profileImageUrl,
                onPickCover: () => _pickImage(
                  title: "Choisir la couverture",
                  onSelected: (image) => _coverImageUrl = image,
                ),
                onPickProfile: () => _pickImage(
                  title: "Choisir la photo de profil",
                  onSelected: (image) => _profileImageUrl = image,
                ),
              ),
              CustomFormSection(
                nameController: _nameController,
                descriptionController: _descriptionController,
              ),
              CustomSocialLinksSection(
                whatsappController: _whatsappController,
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
                    onPressed: _previewStorefront,
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
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _saveCustomization,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSubmitting
                          ? "Enregistrement..."
                          : "Enregistrer les changements",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.isDark(context)
                          ? AppColors.darkBackground
                          : Colors.white,
                      disabledBackgroundColor: AppColors.muted(
                        context,
                      ).withValues(alpha: 0.28),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
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
