import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/share/app_share_service.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/presentation/widgets/store_presentation_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({super.key, required this.store});

  final StoreModel store;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  @override
  Widget build(BuildContext context) {
    final isFavorite = isStoreFavorite(widget.store);
    final storeSurface = AppColors.appBackground(context);

    return Scaffold(
      backgroundColor: storeSurface,
      appBar: AppBar(
        backgroundColor: storeSurface,
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Boutique",
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final added = await toggleStoreFavorite(widget.store);
                if (!mounted) return;
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      added
                          ? "Boutique ajoutée aux favoris"
                          : "Boutique retirée des favoris",
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } on Object catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : AppColors.accent(context),
            ),
          ),
          IconButton(
            onPressed: () => AppShareService.shareStore(context, widget.store),
            icon: Icon(Icons.share_outlined, color: AppColors.accent(context)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveContent(
          maxWidth: AppBreakpoints.contentMaxWidth,
          child: StorePresentationWidget(store: widget.store),
        ),
      ),
    );
  }
}
