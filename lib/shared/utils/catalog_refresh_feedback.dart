import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart'
    show catalogError, catalogRepository;

Future<void> refreshCatalogWithFeedback(
  BuildContext context, {
  required String targetLabel,
  required String successMessage,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text("Actualisation de $targetLabel..."),
        duration: const Duration(milliseconds: 900),
      ),
    );

  await catalogRepository.softRefreshCatalog(force: true);
  if (!context.mounted) return;

  final error = catalogError.value?.trim();
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          error != null && error.isNotEmpty
              ? "Actualisation impossible. Verifiez la connexion."
              : successMessage,
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
}
