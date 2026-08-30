import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/core/upload/image_upload_controller.dart';
import 'package:vendza/features/cathegory/data/services/data_exemple.dart'
    as cathegory_data;
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/input/app_input_decoration.dart';
import 'package:vendza/shared/widgets/input/from_fiel_widget.dart';
import 'package:vendza/shared/widgets/input/from_section.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/media/upload_image_slot.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({
    super.key,
    this.storeId = "1",
    this.storeName = "Tech Store",
  });

  final String storeId;
  final String storeName;

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  String _name = "";
  String _description = "";
  String _price = "";
  String _currency = "CDF";
  String _category = "";
  String? _nameError;
  String? _priceError;
  String? _imageError;
  bool _isSubmitting = false;
  final _imageUpload = ImageUploadController(
    pickTitle: "Choisir l'image du produit",
  );
  final List<_VariantDraft> _variants = [];

  @override
  void initState() {
    super.initState();
    _imageUpload.addListener(_onUploadChanged);
  }

  @override
  void dispose() {
    _imageUpload
      ..removeListener(_onUploadChanged)
      ..dispose();
    for (final variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  void _onUploadChanged() {
    if (mounted) setState(() {});
  }

  void _addVariant() {
    if (_isSubmitting) return;
    setState(() {
      final variant = _VariantDraft(price: _price.trim(), currency: _currency);
      variant.image.addListener(_onUploadChanged);
      _variants.add(variant);
    });
  }

  void _removeVariant(int index) {
    if (_isSubmitting) return;
    setState(() {
      final variant = _variants.removeAt(index);
      variant.dispose();
    });
  }

  Future<void> _saveProduct() async {
    if (_isSubmitting || _imageUpload.blocksSubmit) return;
    if (_variants.any((variant) => variant.image.blocksSubmit)) return;
    if (!NetworkStatus.ensureOnline(context)) return;

    final String trimmedName = _name.trim();
    final String trimmedPrice = _price.trim();

    setState(() {
      _nameError = trimmedName.isEmpty
          ? "Le nom du produit est obligatoire."
          : null;
      _priceError = trimmedPrice.isEmpty
          ? "Le prix du produit est obligatoire."
          : null;
      _imageError = _imageUpload.hasImage
          ? null
          : "Ajoutez une image pour créer ce produit.";
      for (final variant in _variants) {
        final hasImage = variant.image.hasImage;
        final hasName = variant.name.trim().isNotEmpty;
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

    final storeId = int.tryParse(widget.storeId);
    if (storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant de boutique invalide.')),
      );
      return;
    }

    final parsedPrice = double.tryParse(
      trimmedPrice.replaceAll(RegExp(r'[\s\u00A0]'), '').replaceAll(',', '.'),
    );
    if (parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prix invalide.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final imageUrl = await _imageUpload.ensureRemoteUrl();
      final variationEntries = <MapEntry<String, Map<String, dynamic>>>[];
      for (final variant in _variants) {
        final model = variant.toModel();
        if (model.name.isEmpty && !variant.image.hasImage) continue;
        final variantImage = variant.image.hasImage
            ? await variant.image.ensureRemoteUrl()
            : '';
        variationEntries.add(
          MapEntry(model.name, {
            'price': model.price,
            'quantity': model.quantity,
            'image': variantImage,
          }),
        );
      }
      final product = await catalogRepository.createProduct(
        storeId: storeId,
        storeName: widget.storeName,
        title: trimmedName,
        description: _description.trim(),
        price: parsedPrice,
        stock: 1,
        imagePath: imageUrl,
        variation: variationEntries.isEmpty
            ? null
            : Map.fromEntries(variationEntries),
      );
      if (!mounted) return;
      Navigator.pop(context, product);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : "Impossible d'ajouter ce produit pour le moment.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter Produit")),
      body: SingleChildScrollView(
        child: ResponsiveContent(
          maxWidth: 760,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              FormSection(
                title: null,
                children: [
                  FormFieldWidget(
                    label: "Nom *",
                    hint: "Entrer le nom du produit",
                    onChanged: (value) {
                      _name = value;
                      if (_nameError != null && value.trim().isNotEmpty) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),
                  _FieldErrorText(message: _nameError),
                  FormFieldWidget(
                    label: "Description",
                    hint: "Entrer une petite description pour votre produit",
                    maxLines: 5,
                    minLines: 3,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) => _description = value,
                  ),
                  _PriceField(
                    label: "Prix *",
                    initialValue: _price,
                    currency: _currency,
                    errorText: _priceError,
                    onChanged: (value) {
                      _price = value;
                      if (_priceError != null && value.trim().isNotEmpty) {
                        setState(() => _priceError = null);
                      }
                    },
                    onCurrencyChanged: (value) {
                      setState(() => _currency = value);
                    },
                  ),
                  _ProductCategorySelector(
                    selectedCategory: _category,
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                      });
                    },
                  ),
                ],
              ),
              FormSection(
                title: "Image",
                child: UploadImageSlot(
                  controller: _imageUpload,
                  emptyTitle: "Ajouter une image",
                  enabled: !_isSubmitting,
                ),
              ),
              _FieldErrorText(message: _imageError),
              FormSection(
                title: "Variantes",
                children: [
                  const _OptionalVariantsNotice(),
                  ...List.generate(_variants.length, (index) {
                    final _VariantDraft variant = _variants[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface(context),
                        border: Border.all(color: AppColors.border(context)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Variante ${index + 1}",
                                  style: TextStyle(
                                    color: AppColors.cardTitle(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeVariant(index),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: "Supprimer la variante",
                              ),
                            ],
                          ),
                          FormFieldWidget(
                            label: "Nom de la variante",
                            hint: "Ex: Rouge / Taille M / 500 ml",
                            onChanged: (value) {
                              variant.name = value;
                              if (variant.error != null &&
                                  value.trim().isNotEmpty) {
                                setState(() => variant.error = null);
                              }
                            },
                          ),
                          _FieldErrorText(message: variant.error),
                          _PriceField(
                            label: "Prix de la variante",
                            initialValue: variant.price,
                            currency: variant.currency,
                            onChanged: (value) => variant.price = value,
                            onCurrencyChanged: (value) {
                              setState(() => variant.currency = value);
                            },
                          ),
                          UploadImageSlot(
                            controller: variant.image,
                            emptyTitle: "Ajouter l'image",
                            subtitle: "Variante ${index + 1}",
                            height: 118,
                            enabled: !_isSubmitting,
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Ajouter une variante"),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: AppBouton(
                    text: "Ajouter",
                    loadingText: "Ajout...",
                    onPressed: _saveProduct,
                    enabled:
                        !_isSubmitting &&
                        !_imageUpload.blocksSubmit &&
                        !_variants.any(
                          (variant) => variant.image.blocksSubmit,
                        ),
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

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.label,
    required this.initialValue,
    required this.currency,
    required this.onChanged,
    required this.onCurrencyChanged,
    this.errorText,
  });

  final String label;
  final String initialValue;
  final String currency;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsInputFormatter(),
          ],
          onChanged: onChanged,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: AppInputDecoration.field(
            context,
            hintText: "0",
            errorText: errorText,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currency,
                  dropdownColor: AppColors.card(context),
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
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ThousandsInputFormatter extends TextInputFormatter {
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

class _OptionalVariantsNotice extends StatelessWidget {
  const _OptionalVariantsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
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

class _ProductCategorySelector extends StatelessWidget {
  const _ProductCategorySelector({
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = cathegory_data.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Categorie", style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedCategory.isEmpty ? null : selectedCategory,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.iconAccent(context),
          ),
          dropdownColor: AppColors.card(context),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: AppInputDecoration.field(
            context,
            hintText: "Choisir la categorie du produit",
          ),
          items: [
            const DropdownMenuItem<String>(
              value: "",
              child: Text("Sans catégorie"),
            ),
            ...categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.name,
                child: Text(category.name),
              );
            }),
          ],
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _VariantDraft {
  _VariantDraft({this.price = "", this.currency = "CDF"})
    : image = ImageUploadController(pickTitle: "Image de la variante");

  String name = "";
  String price;
  String currency;
  final ImageUploadController image;
  String? error;

  void dispose() {
    image.dispose();
  }

  ProductVariantModel toModel() {
    final trimmedPrice = price.trim();
    return ProductVariantModel(
      name: name.trim(),
      price: trimmedPrice.isEmpty ? "" : "$trimmedPrice $currency",
      quantity: "",
      imageurl: image.remoteUrl ?? image.previewUrl,
    );
  }
}
