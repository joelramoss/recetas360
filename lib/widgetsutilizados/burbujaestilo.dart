import 'package:flutter/material.dart';

class Burbujawidget extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const Burbujawidget({
    Key? key,
    required this.text,
    this.imageUrl,
    required this.size,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si hay URL de imagen, la burbuja tendrá fondo con imagen y texto blanco abajo.
    // Si NO hay URL, la burbuja será blanca y el texto negro centrado.
    final bool hasImage = imageUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orangeAccent, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
          // Fondo con imagen o blanco
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: hasImage ? null : Colors.white,
        ),
        // Alineamos el texto según tenga o no imagen
        child: Align(
          alignment: hasImage ? Alignment.bottomCenter : Alignment.center,
          child: Padding(
            // Un pequeño padding en la parte inferior si hay imagen
            padding: hasImage ? const EdgeInsets.only(bottom: 8.0) : EdgeInsets.zero,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hasImage ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.15,
                shadows: hasImage
                    ? const [
                        Shadow(
                          blurRadius: 3,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
