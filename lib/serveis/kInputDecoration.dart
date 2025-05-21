import 'package:flutter/material.dart';

InputDecoration kInputDecoration({
  required BuildContext context,
  required String labelText,
  String? hintText,
  IconData? icon,
  bool isDense = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
  EdgeInsetsGeometry? contentPadding,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon ?? (icon != null ? Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20) : null),
    suffixIcon: suffixIcon,
    isDense: isDense,
    contentPadding: contentPadding ?? (isDense ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : null),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.colorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
    ),
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerHighest,
  );
}