import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class MyTextField extends StatefulWidget {
  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    this.controller,
    this.iconPrefix,
    this.iconSufix,
    this.onPressed,
    this.keyboardType,
    this.textInputAction,
    this.onDarkBackground = true,
  });

  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final VoidCallback? onPressed;
  final IconData? iconPrefix;
  final IconData? iconSufix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool onDarkBackground;

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  void _togglePasswordVisibility() {
    if (!widget.obscureText) return;

    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = AppColors.softSurface(context);
    final borderColor = AppColors.border(context);
    final hintColor = AppColors.textSecondary(context);
    final iconColor = AppColors.accent(context).withValues(alpha: 0.78);

    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      cursorColor: AppColors.accent(context),
      style: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        prefixIcon: Icon(widget.iconPrefix, color: iconColor, size: 20),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: _togglePasswordVisibility,
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary(context),
                  size: 20,
                ),
              )
            : null,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: MediaQuery.sizeOf(context).height < 700 ? 13 : 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.accent(context), width: 1.4),
        ),
      ),
    );
  }
}
