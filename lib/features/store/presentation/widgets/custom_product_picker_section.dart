import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/store/presentation/widgets/custom_image_selector.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class CustomProductPickerSection extends StatelessWidget {
  const CustomProductPickerSection({
    super.key,
    required this.products,
    required this.onSelectProducts,
  });

  final List<ProductModel> products;
  final VoidCallback onSelectProducts;

  @override
  Widget build(BuildContext context) {
    return _CustomSectionCard(
      title: "Produits mis en avant",
      subtitle: "Choisis les produits visibles sur l'accueil du store.",
      trailing: TextButton.icon(
        onPressed: onSelectProducts,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.actionText(context),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: const Icon(Icons.tune, size: 18),
        label: const Text("Choisir"),
      ),
      child: products.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: "Aucun produit mis en avant",
              message:
                  "Choisis les produits qui seront visibles sur l'accueil.",
              compact: true,
            )
          : SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _FeaturedProductChip(product: products[index]);
                },
              ),
            ),
    );
  }
}

class CustomFormSection extends StatelessWidget {
  const CustomFormSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return _CustomSectionCard(
      title: "Informations boutique",
      subtitle: "Ces informations apparaîtront sur la page publique.",
      child: Column(
        children: [
          _CustomTextField(
            controller: nameController,
            label: "Nom de la boutique",
            hintText: "Ex: Vendza Tech Store",
          ),
          const SizedBox(height: 12),
          _CustomTextField(
            controller: descriptionController,
            label: "Description",
            hintText: "Présente brièvement ta boutique...",
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class CustomMediaSection extends StatelessWidget {
  const CustomMediaSection({
    super.key,
    required this.coverImageUrl,
    required this.profileImageUrl,
    required this.onPickCover,
    required this.onPickProfile,
  });

  final String coverImageUrl;
  final String profileImageUrl;
  final VoidCallback onPickCover;
  final VoidCallback onPickProfile;

  @override
  Widget build(BuildContext context) {
    return _CustomSectionCard(
      title: "Identité visuelle",
      subtitle: "Ajoute une couverture et une image de profil.",
      child: Column(
        children: [
          CustomImageSelector(
            title: "Image de couverture",
            subtitle: "Changer la bannière du store",
            imageUrl: coverImageUrl,
            icon: Icons.image_outlined,
            onTap: onPickCover,
          ),
          const SizedBox(height: 12),
          CustomImageSelector(
            title: "Photo de profil",
            subtitle: "Changer le logo ou avatar",
            imageUrl: profileImageUrl,
            icon: Icons.storefront_outlined,
            onTap: onPickProfile,
            height: 104,
          ),
        ],
      ),
    );
  }
}

class CustomSocialLinksSection extends StatelessWidget {
  const CustomSocialLinksSection({
    super.key,
    required this.whatsappController,
    required this.instagramController,
    required this.facebookController,
  });

  final TextEditingController whatsappController;
  final TextEditingController instagramController;
  final TextEditingController facebookController;

  @override
  Widget build(BuildContext context) {
    return _CustomSectionCard(
      title: "Réseaux sociaux",
      subtitle: "Ajoute seulement les liens que tu veux afficher.",
      child: Column(
        children: [
          _CustomTextField(
            controller: whatsappController,
            label: "WhatsApp",
            hintText: "Ex: +243900000000 ou lien wa.me",
            prefixIcon: const FaIcon(FontAwesomeIcons.whatsapp, size: 19),
          ),
          const SizedBox(height: 12),
          _CustomTextField(
            controller: instagramController,
            label: "Instagram",
            hintText: "Ex: https://instagram.com/tonstore",
            prefixIcon: const FaIcon(FontAwesomeIcons.instagram, size: 19),
          ),
          const SizedBox(height: 12),
          _CustomTextField(
            controller: facebookController,
            label: "Facebook",
            hintText: "Ex: https://facebook.com/tonstore",
            prefixIcon: const FaIcon(FontAwesomeIcons.facebook, size: 19),
          ),
        ],
      ),
    );
  }
}

class _CustomSectionCard extends StatelessWidget {
  const _CustomSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: AppColors.isDark(context) ? 0.12 : 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.sectionTitle(context)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.subtitle(
                        context,
                      ).copyWith(height: 1.25),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: AppColors.accent(context),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon == null
            ? null
            : IconTheme(
                data: IconThemeData(color: AppColors.iconAccent(context)),
                child: Center(widthFactor: 1, child: prefixIcon),
              ),
        filled: true,
        fillColor: AppColors.searchSurface(context),
        labelStyle: AppTextStyles.label(context),
        hintStyle: AppTextStyles.subtitle(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.accent(context), width: 1.4),
        ),
      ),
    );
  }
}

class _FeaturedProductChip extends StatelessWidget {
  const _FeaturedProductChip({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.softSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: product.imageurl.isEmpty
                  ? const _ProductPlaceholder()
                  : SmartImage(
                      path: product.imageurl,
                      fit: BoxFit.cover,
                      errorWidget: const _ProductPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label(context).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.iconAccent(context),
        size: 22,
      ),
    );
  }
}
