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
  final defaultInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0),
    borderSide: BorderSide(
      color: theme.colorScheme.outline,
      width: 1.0,
    ),
  );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon ?? (icon != null ? Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20) : null),
    suffixIcon: suffixIcon,
    isDense: isDense,
    contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), // Ajustado para consistencia
    
    filled: true, 
    fillColor: Colors.white, // Fondo blanco para campos editables

    border: defaultInputBorder,
    enabledBorder: defaultInputBorder,
    focusedBorder: defaultInputBorder.copyWith(
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 2.0,
      ),
    ),
    errorBorder: defaultInputBorder.copyWith(
      borderSide: BorderSide(
        color: theme.colorScheme.error,
        width: 1.0, // o 1.5 si prefieres
      ),
    ),
    focusedErrorBorder: defaultInputBorder.copyWith(
      borderSide: BorderSide(
        color: theme.colorScheme.error,
        width: 2.0,
      ),
    ),
  );
}