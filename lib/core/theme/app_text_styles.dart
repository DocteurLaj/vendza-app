import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class AppTextStyles {
  static TextStyle pageTitle(BuildContext context) {
    return TextStyle(
      color: AppColors.pageTitle(context),
      fontSize: 18,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return TextStyle(
      color: AppColors.sectionTitle(context),
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle sectionLabel(BuildContext context) {
    return TextStyle(
      color: AppColors.sectionTitle(context),
      fontSize: 12,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle cardTitle(BuildContext context) {
    return TextStyle(
      color: AppColors.cardTitle(context),
      fontSize: 14.5,
      fontWeight: FontWeight.w900,
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      color: AppColors.bodyText(context),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    return TextStyle(
      color: AppColors.subtitleText(context),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle label(BuildContext context) {
    return TextStyle(
      color: AppColors.subtitleText(context),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle action(BuildContext context) {
    return TextStyle(
      color: AppColors.actionText(context),
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );
  }
}
