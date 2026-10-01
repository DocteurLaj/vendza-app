import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

Future<bool> showDestructiveActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  List<String> details = const [],
  String? confirmPhrase,
  String cancelLabel = 'Annuler',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DestructiveActionDialog(
      title: title,
      message: message,
      details: details,
      confirmPhrase: confirmPhrase,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}

class DestructiveActionDialog extends StatefulWidget {
  const DestructiveActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.details = const [],
    this.confirmPhrase,
    this.cancelLabel = 'Annuler',
  });

  final String title;
  final String message;
  final List<String> details;
  final String? confirmPhrase;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<DestructiveActionDialog> createState() =>
      _DestructiveActionDialogState();
}

class _DestructiveActionDialogState extends State<DestructiveActionDialog> {
  late final TextEditingController _controller;

  bool get _requiresPhrase => (widget.confirmPhrase ?? '').trim().isNotEmpty;

  bool get _canConfirm {
    final phrase = widget.confirmPhrase?.trim();
    if (phrase == null || phrase.isEmpty) return true;
    return _controller.text.trim() == phrase;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final dangerColor = AppColors.isDark(context)
        ? const Color(0xFFFF8A80)
        : const Color(0xFFC62828);
    return AlertDialog(
      icon: CircleAvatar(
        backgroundColor: dangerColor.withValues(alpha: 0.12),
        child: Icon(Icons.warning_amber_rounded, color: dangerColor),
      ),
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.message),
              if (widget.details.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...widget.details.map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(detail)),
                      ],
                    ),
                  ),
                ),
              ],
              if (_requiresPhrase) ...[
                const SizedBox(height: 14),
                Text(
                  'Tapez ${widget.confirmPhrase} pour confirmer.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: widget.confirmPhrase,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: dangerColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
