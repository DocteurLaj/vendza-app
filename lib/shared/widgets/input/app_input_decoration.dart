import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class AppInputDecoration {
  static InputDecoration field(
    BuildContext context, {
    required String hintText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: AppColors.searchSurface(context),
      hintStyle: TextStyle(
        color: AppColors.textSecondary(context),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: _border(context),
      enabledBorder: _border(context),
      focusedBorder: _border(
        context,
        color: AppColors.accent(context),
        width: 1.5,
      ),
      errorBorder: _border(context, color: Colors.red),
      focusedErrorBorder: _border(context, color: Colors.red, width: 1.5),
    );
  }

  static OutlineInputBorder _border(
    BuildContext context, {
    Color? color,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: color ?? AppColors.border(context),
        width: width,
      ),
    );
  }
}
