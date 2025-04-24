import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer for image loading

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 17:04:59

class Burbujawidget extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  // --- NUEVO PARÁMETRO ---
  final double fontSizeMultiplier;
  // --- FIN NUEVO PARÁMETRO ---

  const Burbujawidget({
    Key? key,
    required this.text,
    this.imageUrl,
    required this.size,
    this.onTap,
    // --- AÑADIR AL CONSTRUCTOR CON VALOR POR DEFECTO ---
    this.fontSizeMultiplier = 0.12, // Valor por defecto si no se especifica
    // --- FIN AÑADIR AL CONSTRUCTOR ---
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme data
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine text style based on size, ensure it's readable
    final TextStyle effectiveTextStyle = textTheme.labelMedium?.copyWith(
          // --- USAR EL NUEVO PARÁMETRO AQUÍ ---
          fontSize: (size * fontSizeMultiplier).clamp(10.0, 16.0), // Usa el multiplicador pasado
          // --- FIN USAR EL NUEVO PARÁMETRO ---
          fontWeight: FontWeight.w600, // Slightly less bold than 'bold'
          color: colorScheme.onPrimaryContainer, // Color for text on primary container
        ) ?? const TextStyle(); // Fallback style

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          // Use a theme color for the background
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
          // Use theme color for the border
          border: Border.all(color: colorScheme.primary.withOpacity(0.7), width: 2),
          boxShadow: [ // Use theme shadow color
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.25), // Use theme shadow
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        // Use ClipOval to ensure content (like image) stays within the circle
        child: ClipOval(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // If an image URL is provided and not empty, display the image
              if (imageUrl != null && imageUrl!.isNotEmpty)
                SizedBox(
                  // Adjust image size relative to the bubble size
                  width: size * 0.6,
                  height: size * 0.6,
                  child: ClipOval( // Clip the image itself to be oval
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      // Add a loading builder with shimmer
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: colorScheme.surfaceVariant,
                          highlightColor: colorScheme.surface,
                          child: Container(color: Colors.white), // Placeholder for shimmer
                        );
                      },
                      // Use theme colors in error builder
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceVariant, // Use theme color
                          child: Icon(
                            Icons.image_not_supported_outlined, // Use outlined icon
                            color: colorScheme.onSurfaceVariant, // Use theme color
                            size: size * 0.3, // Adjust icon size
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Add space only if there's an image above
              if (imageUrl != null && imageUrl!.isNotEmpty) const SizedBox(height: 4),

              // Display the text, applying the calculated style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add horizontal padding
                child: Text(
                  text,
                  style: effectiveTextStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1, // Ensure text doesn't wrap excessively
                  overflow: TextOverflow.ellipsis, // Handle overflow
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}