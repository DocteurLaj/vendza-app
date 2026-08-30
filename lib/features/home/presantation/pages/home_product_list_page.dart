import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';

class HomeProductListPage extends StatelessWidget {
  const HomeProductListPage({
    super.key,
    required this.title,
    required this.products,
    this.section = 'trending',
  });

  final String title;
  final List<ProductModel> products;
  final String section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14, bottom: 20),
        child: ResponsiveContent(
          maxWidth: AppBreakpoints.contentMaxWidth,
          child: ProductSectionWidget(
            products: products,
            onProductTap: (product) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                    product: product,
                    section: section,
                    position: products.indexOf(product),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
