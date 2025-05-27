import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recetas360/components/CarritoRestante.dart'; // Importado para el botón del carrito
import 'package:recetas360/components/ListaRecetas.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:recetas360/pagines/HistorialRecetas.dart';
import 'package:recetas360/pagines/RecetasFavoritas.dart';
import 'package:recetas360/pagines/PantallacrearReceta.dart'; // Import CrearRecetaScreen
import 'package:recetas360/widgetsutilizados/burbujaestilo.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 15:18:52

class PantallaGastronomias extends StatefulWidget {
  final String tipoAlimento;
  const PantallaGastronomias({super.key, required this.tipoAlimento});

  @override
  State<PantallaGastronomias> createState() => _PantallaGastronomiasState();
}

class _PantallaGastronomiasState extends State<PantallaGastronomias>
    with SingleTickerProviderStateMixin {
  final List<String> subcategorias = [
    "Mediterranea",
    "Asiatica",
    "Americana",
    "Africana",
    "Oceanica"
  ];

  final Map<String, String?> subcategoriasImagenes = {
    "Mediterranea": "assets/images/mediterranea.png",
    "Asiatica": "assets/images/asiatica.png",
    "Americana": "assets/images/americana.png",
    "Africana": "assets/images/africana.png",
    "Oceanica": "assets/images/oceanica.png",
    // Consider adding a default/placeholder image if a subcategoria might not have an image
  };

  late AnimationController _controller;
  late List<Animation<double>> _bubbleAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initializeAnimations();
    _controller.forward();
  }

  void _initializeAnimations() {
    final int n = subcategorias.length;
    if (n == 0) {
      _bubbleAnimations = [];
      return;
    }
    final double intervalLength = 0.6 / n; // Ensure n is not zero if used in division
    const double startOffset = 0.1;

    _bubbleAnimations = List.generate(n, (i) {
      double start = startOffset + (i * intervalLength * 0.8);
      double end = start + intervalLength;
      end = math.min(end, 1.0);
      start = math.min(start, end); // Ensure start <= end

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });
  }

  void _restartAnimation() {
    if (!mounted) return;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _restartAnimation());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tipoAlimento),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 25,
            tooltip: "Ajustes",
            onPressed: () => _navigateTo(const PaginaAjustes()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Text(
              "Gastronomías de ${widget.tipoAlimento}",
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double boxWidth = constraints.maxWidth;
                final double boxHeight = constraints.maxHeight;
                final double centerX = boxWidth / 2;
                final double centerY = boxHeight / 2;
                final double minSide = math.min(boxWidth, boxHeight);
                final double radius = minSide * 0.35;
                final double outerBubbleSize = minSide * 0.32;
                final double centerBubbleSize = minSide * 0.33;

                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ..._buildBurbujas(
                        centerX: centerX,
                        centerY: centerY,
                        radius: radius,
                        bubbleSize: outerBubbleSize,
                      ),
                      Container(
                        width: centerBubbleSize,
                        height: centerBubbleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.secondaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.tipoAlimento,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ).animate().scale(
                          delay: 100.ms,
                          duration: 600.ms,
                          curve: Curves.easeOutBack),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended( // ELIMINAR ESTE BLOQUE
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (_) => CrearRecetaScreen(
      //           initialCategoria: widget.tipoAlimento,
      //         ),
      //       ),
      //     ).then((_) => _restartAnimation());
      //   },
      //   icon: const Icon(Icons.add_rounded),
      //   label: Text('Crear en ${widget.tipoAlimento}'),
      //   tooltip: 'Crear nueva receta en ${widget.tipoAlimento}',
      // ).animate().fadeIn(delay: 800.ms).scale(delay: 700.ms), // HASTA AQUÍ
    );
  }

  List<Widget> _buildBurbujas({
    required double centerX,
    required double centerY,
    required double radius,
    required double bubbleSize,
  }) {
    final List<Widget> bubbles = [];
    final int n = subcategorias.length;

    if (n == 0 || _bubbleAnimations.length != n) {
      print(
          "Warning: _buildBurbujas encountered an unexpected state. n=$n, _bubbleAnimations.length=${_bubbleAnimations.length}");
      return [];
    }

    for (int i = 0; i < n; i++) {
      final String subcat = subcategorias[i];
      final double angle = -math.pi / 2 + (2 * math.pi * i) / n;
      final String? imageUrl = subcategoriasImagenes[subcat];

      if (i >= _bubbleAnimations.length) {
        print("Error: Index out of bounds for _bubbleAnimations. i=$i, length=${_bubbleAnimations.length}");
        continue;
      }

      bubbles.add(
        AnimatedBuilder(
          animation: _bubbleAnimations[i],
          builder: (context, child) {
            double value = _bubbleAnimations[i].value;
            final double currentRadius = radius * value;
            final double x = centerX + currentRadius * math.cos(angle);
            final double y = centerY + currentRadius * math.sin(angle);

            final double finalLeft = x - (bubbleSize / 2);
            final double finalTop = y - (bubbleSize / 2);

            if (value <= 0 || finalLeft.isNaN || finalTop.isNaN) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: finalLeft,
              top: finalTop,
              child: Opacity(
                opacity: math.min(value * 1.5, 1.0),
                child: Transform.scale(
                  scale: value,
                  child: child!,
                ),
              ),
            );
          },
          child: Burbujawidget(
            text: subcat,
            size: bubbleSize,
            imageUrl: imageUrl,
            onTap: () {
              print(
                  "Navegando con Categoria: ${widget.tipoAlimento}, Gastronomia: $subcat");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListaRecetas(
                    mainCategory: widget.tipoAlimento,
                    subCategory: subcat,
                  ),
                ),
              ).then((_) => _restartAnimation());
            },
          ),
        ),
      );
    }
    return bubbles;
  }
}