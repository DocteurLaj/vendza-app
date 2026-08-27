import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

Future<String?> showCityPickerDialog({
  required BuildContext context,
  required String selectedCity,
  required List<String> cities,
}) {
  return showAppPopup<String>(
    context: context,
    size: PopupSize.large,
    scrollable: true,
    builder: (context) =>
        CityPickerDialog(selectedCity: selectedCity, cities: cities),
  );
}

class CityPickerDialog extends StatefulWidget {
  const CityPickerDialog({
    super.key,
    required this.selectedCity,
    required this.cities,
  });

  final String selectedCity;
  final List<String> cities;

  @override
  State<CityPickerDialog> createState() => _CityPickerDialogState();
}

class _CityPickerDialogState extends State<CityPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredCities {
    final normalizedQuery = _normalize(_query);
    if (normalizedQuery.isEmpty) return widget.cities;

    return widget.cities
        .where((city) => _normalize(city).contains(normalizedQuery))
        .toList();
  }

  bool get _canUseCustomCity {
    final trimmedQuery = _query.trim();
    if (trimmedQuery.isEmpty) return false;

    return !widget.cities.any(
      (city) => _normalize(city) == _normalize(trimmedQuery),
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final filteredCities = _filteredCities;

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisir une ville',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            SearchBarWidget(
              controller: _searchController,
              autofocus: true,
              hintText: 'Rechercher ou ecrire une ville',
              isActive: _query.isNotEmpty,
              onChanged: (value) => setState(() => _query = value),
              onClear: () => setState(() => _query = ''),
              onSubmitted: (_) {},
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (_canUseCustomCity)
                    _CityOptionTile(
                      title: 'Utiliser "${_query.trim()}"',
                      icon: Icons.add_location_alt_outlined,
                      isSelected: false,
                      onTap: () => Navigator.pop(context, _query.trim()),
                    ),
                  ...filteredCities.map(
                    (city) => _CityOptionTile(
                      title: city,
                      icon: Icons.location_on_outlined,
                      isSelected:
                          _normalize(city) == _normalize(widget.selectedCity),
                      onTap: () => Navigator.pop(context, city),
                    ),
                  ),
                  if (filteredCities.isEmpty && !_canUseCustomCity)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Text('Aucune ville trouvee')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityOptionTile extends StatelessWidget {
  const _CityOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      enableHoverElevation: false,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.accent(context)
              : AppColors.textSecondary(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? AppColors.textPrimary(context)
                : AppColors.textSecondary(context),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppColors.accent(context))
            : null,
      ),
    );
  }
}
