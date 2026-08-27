import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/search_bar_style.dart';
import 'package:vendza/core/utils/search/search_actions.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    this.hintText = 'Rechercher...',
    this.controller,
    this.focusNode,
    this.isActive = false,
    this.showClearButton = true,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isActive;
  final bool showClearButton;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
  }

  void _submitSearch() {
    final query = _controller.text.trim();
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(query);
      return;
    }
    handleSearch(query, context);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final height = AppSearchBarStyle.height(isActive: isActive);
    final borderRadius = AppSearchBarStyle.borderRadius(isActive: isActive);
    final iconColor = AppColors.iconAccent(context);
    final hasText = _controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: AppSearchBarStyle.animationDuration,
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: AppSearchBarStyle.backgroundColor(context, isActive: isActive),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppSearchBarStyle.borderColor(context, isActive: isActive),
        ),
        boxShadow: AppSearchBarStyle.boxShadow(context, isActive: isActive),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: AppColors.accent(context),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: AppSearchBarStyle.fontSize,
            fontWeight: AppSearchBarStyle.fontWeight(isActive: isActive),
          ),
          onTap: widget.onTap,
          onSubmitted: (query) {
            if (widget.onSubmitted != null) {
              widget.onSubmitted!(query);
              return;
            }
            handleSearch(query, context);
          },
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: AppSearchBarStyle.fontSize,
              fontWeight: FontWeight.w500,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),
            prefixIcon: GestureDetector(
              onTap: _submitSearch,
              child: Icon(Icons.search, color: iconColor),
            ),
            suffixIcon: widget.showClearButton && hasText
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: iconColor,
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: height <= AppSearchBarStyle.idleHeight ? 12 : 14,
            ),
          ),
        ),
      ),
    );
  }
}
