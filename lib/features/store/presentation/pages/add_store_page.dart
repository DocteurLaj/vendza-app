import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/presentation/widgets/custom_image_selector.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/input/from_fiel_widget.dart';
import 'package:vendza/shared/widgets/input/from_section.dart';
import 'package:vendza/shared/widgets/dialog/city_picker_dialog.dart';
import 'package:vendza/core/services/media/app_image_picker.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class AddStore extends StatefulWidget {
  const AddStore({super.key});

  @override
  State<AddStore> createState() => _AddStoreState();
}

class _AddStoreState extends State<AddStore> {
  static const List<String> _drcCities = [
    "Aketi",
    "Aru",
    "Bandundu",
    "Baraka",
    "Basoko",
    "Beni",
    "Binga",
    "Boende",
    "Boma",
    "Bondo",
    "Bongandanga",
    "Bunia",
    "Businga",
    "Butembo",
    "Demba",
    "Dibaya",
    "Dilolo",
    "Gemena",
    "Gbadolite",
    "Goma",
    "Idiofa",
    "Ilebo",
    "Inongo",
    "Isiro",
    "Kabalo",
    "Kabinda",
    "Kalemie",
    "Kambove",
    "Kamina",
    "Kananga",
    "Kasangulu",
    "Kasongo",
    "Kasumbalesa",
    "Kenge",
    "Kikwit",
    "Kindu",
    "Kinshasa",
    "Kipushi",
    "Kisangani",
    "Kitenge",
    "Kolwezi",
    "Kongolo",
    "Libenge",
    "Likasi",
    "Lisala",
    "Lodja",
    "Lubao",
    "Lubumbashi",
    "Luebo",
    "Lusambo",
    "Mahagi",
    "Manono",
    "Matadi",
    "Mbandaka",
    "Mbanza-Ngungu",
    "Mbuji-Mayi",
    "Moanda",
    "Moba",
    "Mweka",
    "Mwene-Ditu",
    "Nioki",
    "Tshikapa",
    "Uvira",
    "Wamba",
    "Watsa",
    "Zongo",
  ];

  String _name = "";
  String _description = "";
  String _imageUrl = "";
  String _city = "Lubumbashi";
  String _whatsapp = "";
  String _instagram = "";
  String _facebook = "";
  String? _nameError;
  String? _descriptionError;
  String? _imageError;
  bool _isSubmitting = false;

  Future<void> _pickStoreImage() async {
    if (_isSubmitting) return;
    final selectedImage = await pickAppImage(
      context,
      title: "Choisir l'image du store",
    );

    if (selectedImage == null) return;
    setState(() {
      _imageUrl = selectedImage;
      _imageError = null;
    });
  }

  Future<void> _createStore() async {
    if (_isSubmitting) return;

    final trimmedName = _name.trim();
    final trimmedDescription = _description.trim();
    final trimmedImageUrl = _imageUrl.trim();

    setState(() {
      _nameError = trimmedName.isEmpty
          ? "Le nom du store est obligatoire."
          : null;
      _descriptionError = trimmedDescription.isEmpty
          ? "La description du store est obligatoire."
          : null;
      _imageError = trimmedImageUrl.isEmpty
          ? "Ajoutez une image pour creer ce store."
          : null;
    });

    final errors = [?_nameError, ?_descriptionError, ?_imageError];
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.join("\n"))));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // New accounts are buyers; upload/store APIs require seller.
      await authSessionService.becomeSeller();
      await catalogRepository.createStore(
        name: trimmedName,
        description: trimmedDescription,
        address: _city.trim(),
        imagePath: trimmedImageUrl,
        whatsappUrl: _whatsapp.trim(),
        instagramUrl: _instagram.trim(),
        facebookUrl: _facebook.trim(),
      );
      syncStoreCustomizationFromCatalog();
      if (!mounted) return;
      Navigator.pop(context);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Creer un store")),
      body: SingleChildScrollView(
        child: ResponsiveContent(
          maxWidth: 760,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              FormSection(
                title: "Image *",
                child: CustomImageSelector(
                  title: _imageUrl.isEmpty
                      ? "Ajouter une image"
                      : "Remplacer l'image",
                  subtitle: "Appuyez pour choisir une image",
                  imageUrl: _imageUrl,
                  icon: _imageUrl.isEmpty
                      ? Icons.add_a_photo_outlined
                      : Icons.edit_outlined,
                  onTap: _pickStoreImage,
                  height: 168,
                ),
              ),
              _FieldErrorText(message: _imageError),
              FormSection(
                title: null,
                children: [
                  FormFieldWidget(
                    label: "Nom du store *",
                    hint: "Entrer le nom du store",
                    onChanged: (value) {
                      _name = value;
                      if (_nameError != null && value.trim().isNotEmpty) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),
                  _FieldErrorText(message: _nameError),
                  FormFieldWidget(
                    label: "Description *",
                    hint: "Entrer une petite description",
                    maxLines: 5,
                    minLines: 3,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) {
                      _description = value;
                      if (_descriptionError != null &&
                          value.trim().isNotEmpty) {
                        setState(() => _descriptionError = null);
                      }
                    },
                  ),
                  _FieldErrorText(message: _descriptionError),
                  _StoreCitySelector(
                    selectedCity: _city,
                    cities: _drcCities,
                    onChanged: (value) {
                      setState(() => _city = value);
                    },
                  ),
                ],
              ),
              FormSection(
                title: "Moyens de contact",
                children: [
                  const _OptionalContactNotice(),
                  FormFieldWidget(
                    label: "Whatsapp",
                    hint: "Ex: +243900000000 ou wa.me/...",
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => _whatsapp = value,
                  ),
                  FormFieldWidget(
                    label: "Instagram",
                    hint: "Ex: https://instagram.com/tonstore",
                    onChanged: (value) => _instagram = value,
                  ),
                  FormFieldWidget(
                    label: "Facebook",
                    hint: "Ex: https://facebook.com/tonstore",
                    onChanged: (value) => _facebook = value,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppBouton(
                      text: "Creer",
                      loadingText: "Creation...",
                      onPressed: _createStore,
                      enabled: !_isSubmitting,
                      isLoading: _isSubmitting,
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

class _StoreCitySelector extends StatelessWidget {
  const _StoreCitySelector({
    required this.selectedCity,
    required this.cities,
    required this.onChanged,
  });

  final String selectedCity;
  final List<String> cities;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayedCity = selectedCity.trim().isEmpty
        ? "Selectionner une ville"
        : selectedCity.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Ville", style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        AppInteractive(
          onTap: () async {
            final pickedCity = await showCityPickerDialog(
              context: context,
              selectedCity: selectedCity,
              cities: cities,
            );

            if (pickedCity == null) return;
            onChanged(pickedCity);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.searchSurface(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_city_outlined,
                  color: AppColors.accent(context),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayedCity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.accent(context),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _OptionalContactNotice extends StatelessWidget {
  const _OptionalContactNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.accent(context), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Optionnel: Whatsapp est conseille pour faciliter le contact client.",
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

class _FieldErrorText extends StatelessWidget {
  const _FieldErrorText({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
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
