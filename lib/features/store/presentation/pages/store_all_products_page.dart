import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';

class StoreAllProductsPage extends StatelessWidget {
  const StoreAllProductsPage({
    super.key,
    required this.title,
    required this.products,
  });

  final String title;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14, bottom: 20),
        child: ResponsiveContent(
          maxWidth: AppBreakpoints.contentMaxWidth,
          child: ProductSectionWidget(products: products),
        ),
      ),
    );
  }
}
