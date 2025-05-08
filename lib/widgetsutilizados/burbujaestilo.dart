import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer for image loading

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 17:04:59

class Burbujawidget extends StatelessWidget {
  final String text;
  final String? imageUrl; // Esta URL ahora será una ruta de asset
  final double size;
  final VoidCallback? onTap;
  final double fontSizeMultiplier;

  const Burbujawidget({
    super.key,
    required this.text,
    this.imageUrl,
    required this.size,
    this.onTap,
    this.fontSizeMultiplier = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final TextStyle effectiveTextStyle = textTheme.labelMedium?.copyWith(
          fontSize: (size * fontSizeMultiplier).clamp(10.0, 16.0),
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ) ??
        const TextStyle();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.primary.withOpacity(0.7), width: 2),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                SizedBox(
                  width: size * 0.6,
                  height: size * 0.6,
                  child: ClipOval(
                    // --- CAMBIO IMPORTANTE AQUÍ ---
                    child: Image.asset( // Cambiado de Image.network a Image.asset
                      imageUrl!,
                      fit: BoxFit.cover,
                      // El loadingBuilder para Image.asset no funciona igual que para Image.network.
                      // Image.asset carga rápido o falla. Shimmer aquí puede no ser tan útil
                      // o necesitaría una lógica diferente si la carga del asset fuera asíncrona
                      // de alguna manera (lo cual no es típico para assets locales).
                      // Por simplicidad y para enfocarnos en la carga, lo comentaremos o simplificaremos.
                      /*
                      loadingBuilder: (context, child, loadingProgress) {
                        // Para Image.asset, loadingProgress suele ser null inmediatamente
                        // o la imagen ya está disponible.
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: colorScheme.surfaceContainerHighest,
                          highlightColor: colorScheme.surface,
                          child: Container(color: Colors.white),
                        );
                      },
                      */
                      // --- FIN CAMBIO IMPORTANTE ---
                      errorBuilder: (context, error, stackTrace) {
                        // Este errorBuilder SÍ se llamará si el asset no se encuentra
                        print('Error al cargar asset: $imageUrl. Error: $error');
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: size * 0.3,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (imageUrl != null && imageUrl!.isNotEmpty) const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  text,
                  style: effectiveTextStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}