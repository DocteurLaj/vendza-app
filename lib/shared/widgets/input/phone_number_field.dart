import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/utils/phone_number.dart';
import 'package:vendza/shared/widgets/input/app_input_decoration.dart';

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    super.key,
    this.initialValue = '',
    this.label = 'Téléphone',
    this.enabled = true,
    this.onChanged,
  });

  final String initialValue;
  final String label;
  final bool enabled;
  final ValueChanged<ParsedPhoneNumber>? onChanged;

  @override
  State<PhoneNumberField> createState() => PhoneNumberFieldState();
}

class PhoneNumberFieldState extends State<PhoneNumberField> {
  late PhoneCountry _country;
  late final TextEditingController _nationalController;

  ParsedPhoneNumber get value => ParsedPhoneNumber(
    country: _country,
    national: digitsOnly(_nationalController.text),
  );

  @override
  void initState() {
    super.initState();
    final parsed = parsePhoneNumber(widget.initialValue);
    _country = parsed.country;
    _nationalController = TextEditingController(text: parsed.national);
  }

  @override
  void dispose() {
    _nationalController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged?.call(value);
  }

  Future<void> _pickCountry() async {
    if (!widget.enabled) return;
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return ListView(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Indicatif',
                style: AppTextStyles.sectionTitle(context),
              ),
            ),
            ...kPhoneCountries.map((country) {
              return ListTile(
                leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
                title: Text(country.name),
                trailing: Text('+${country.dialCode}'),
                selected: country.iso == _country.iso,
                onTap: () => Navigator.pop(context, country),
              );
            }),
          ],
        );
      },
    );
    if (selected == null) return;
    setState(() {
      _country = selected;
      final digits = digitsOnly(_nationalController.text);
      _nationalController.text = digits.length > selected.nationalLength
          ? digits.substring(0, selected.nationalLength)
          : digits;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.enabled ? _pickCountry : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                  color: AppColors.card(context),
                ),
                child: Row(
                  children: [
                    Text(_country.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '+${_country.dialCode}',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.iconAccent(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _nationalController,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_country.nationalLength),
                ],
                onChanged: (_) => _emit(),
                decoration: AppInputDecoration.field(
                  context,
                  hintText: '0' * _country.nationalLength,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
