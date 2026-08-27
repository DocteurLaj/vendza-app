import 'package:flutter/foundation.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/shared/models/section_model.dart';

final List<SectionModel> categories = [];
final ValueNotifier<int> categoryRevision = ValueNotifier<int>(0);

Future<void> refreshCategories() async {
  final response = await apiClient.get(ApiEndpoints.categories);
  final items = unwrapApiList(response)
      .map(
        (json) => SectionModel(
          id: json['idcollections'].toString(),
          name: json['name'] as String? ?? '',
          imageUrl: 'assets/images/product1.webp',
        ),
      )
      .toList();
  categories
    ..clear()
    ..addAll(items);
  categoryRevision.value++;
}
