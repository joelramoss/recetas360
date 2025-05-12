import 'package:flutter/material.dart';

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 17:04:59

class Burbujawidget extends StatelessWidget {
  final String text; 
  final String? imageUrl; 
  final double size; // Este es el tamaño total de la burbuja (el círculo)
  final VoidCallback? onTap;

  const Burbujawidget({
    super.key,
    required this.text, 
    this.imageUrl,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Define un factor para el tamaño de la imagen respecto al tamaño de la burbuja.
    // Con 1, la imagen intenta usar todo el espacio definido por el SizedBox interno.
    const double imageSizeFactor = 0.8; // <<-- ASEGÚRATE QUE SEA 1.0

    return GestureDetector(
      onTap: onTap,
      child: Container( // Este es el contenedor de la burbuja
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer, // Este será el color de fondo visible si la imagen no llena el círculo
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
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? Center( // Center es bueno para BoxFit.contain
                  child: SizedBox( 
                    width: size * imageSizeFactor,  
                    height: size * imageSizeFactor, 
                    child: Image.asset( // No es necesario un ClipOval extra aquí si el padre ya es ClipOval y usamos contain
                        imageUrl!,
                        fit: BoxFit.contain, // Mantenemos BoxFit.contain
                        errorBuilder: (context, error, stackTrace) {
                          print('Error al cargar asset: $imageUrl. Error: $error');
                          return Container(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: (size * imageSizeFactor) * 0.5,
                            ),
                          );
                        },
                      ),
                  ),
                )
              : Center( 
                  child: Icon( 
                    Icons.category, 
                    color: colorScheme.onPrimaryContainer.withOpacity(0.6),
                    size: size * 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}